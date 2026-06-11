import Foundation
import SwiftUI

enum CarLinkFeatureAction {
    case voice
    case maps
    case phone
    case messages
    case music
    case podcasts
    case calendar
    case reminders
    case home
    case shortcuts
    case parking
    case fuel
    case tolls
    case charging
    case weather
    case safety
    case settings
    case dashboard
}

@MainActor
final class CarLinkModel: ObservableObject {
    @Published var receivers: [DiscoveredReceiver] = []
    @Published var selectedReceiver: DiscoveredReceiver?
    @Published var pendingReceiver: DiscoveredReceiver?
    @Published var pendingPin = ""
    @Published var pin = ""
    @Published var connectionStatus = "Not connected"
    @Published var activeSessionId: String?
    @Published var showConnectionConfirmation = false
    @Published var showConnectionSuccess = false
    @Published var connectionMessage = ""
    @Published var media = MediaState(title: "Ready", artist: "CarLink", source: "iPhone", isPlaying: false)
    @Published var navigation = NavigationState(destination: "No route", nextInstruction: "Choose a navigation app", provider: "CarLink")
    @Published var logs: [String] = []
    @Published var theme = ThemeState(mode: "dark", material: "glass", accent: "#14b8a6")

    private let browser = BonjourBrowser()
    private let client = CarLinkClient()

    func startDiscovery() {
        browser.onUpdate = { [weak self] receivers in
            Task { @MainActor in
                self?.receivers = receivers
            }
        }
        browser.start()
        appendLog("Browsing for _carlink._tcp")
    }

    func prepareConnection(to receiver: DiscoveredReceiver, pin: String? = nil) {
        pendingReceiver = receiver
        pendingPin = pin ?? self.pin
        connectionMessage = "Connect to \(receiver.name) at \(receiver.host):\(receiver.port)?"
        showConnectionConfirmation = true
    }

    func confirmPendingConnection() {
        guard let receiver = pendingReceiver else {
            appendLog("No pending receiver")
            return
        }
        let resolvedPin = pendingPin.trimmingCharacters(in: .whitespacesAndNewlines)
        pin = resolvedPin
        showConnectionConfirmation = false
        connect(to: receiver, pin: resolvedPin)
    }

    func applyPairingCode(_ code: String) {
        guard let data = code.data(using: .utf8) else {
            connectionStatus = "Invalid QR"
            appendLog("QR code is not UTF-8")
            return
        }

        do {
            let advert = try JSONDecoder().decode(PairingAdvert.self, from: data)
            guard advert.protocolName == "carlink", advert.version == carLinkProtocolVersion else {
                connectionStatus = "Unsupported QR"
                appendLog("QR protocol/version did not match")
                return
            }

            let receiver = DiscoveredReceiver(advert: advert)
            if !receivers.contains(receiver) {
                receivers.insert(receiver, at: 0)
            }
            selectedReceiver = receiver
            pin = advert.pin
            prepareConnection(to: receiver, pin: advert.pin)
            appendLog("Scanned receiver \(receiver.name)")
        } catch {
            connectionStatus = "Invalid QR"
            appendLog("QR parse failed: \(error.localizedDescription)")
        }
    }

    func connect(to receiver: DiscoveredReceiver) {
        connect(to: receiver, pin: pin)
    }

    private func connect(to receiver: DiscoveredReceiver, pin: String) {
        selectedReceiver = receiver
        guard !pin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            appendLog("Enter the receiver PIN first")
            return
        }
        activeSessionId = nil
        connectionStatus = "Connecting"
        appendLog("Connecting to \(receiver.name)")

        client.connect(to: receiver, pin: pin) { [weak self] event in
            Task { @MainActor in
                self?.handleClientEvent(event)
            }
        }
    }

    func sendMediaDemo() {
        media = MediaState(title: "Night Drive", artist: "CarLink Demo", source: "iPhone", isPlaying: true)
        client.sendMedia(media)
        appendLog("Sent media state")
    }

    func sendNavigationDemo() {
        navigation = NavigationState(
            destination: "Home",
            nextInstruction: "Continue for 800 m",
            provider: "CarLink"
        )
        client.sendNavigation(navigation)
        appendLog("Sent navigation state")
    }

    func sendTheme() {
        client.sendTheme(theme)
        appendLog("Sent theme state")
    }

    func perform(_ action: CarLinkFeatureAction) {
        switch action {
        case .voice:
            appendLog("Voice assistant ready")
        case .maps:
            sendNavigationDemo()
        case .phone:
            appendLog("Phone surface opened")
        case .messages:
            appendLog("Voice-only messages opened")
        case .music:
            sendMediaDemo()
        case .podcasts:
            media = MediaState(title: "Daily Drive", artist: "Podcast Queue", source: "iPhone", isPlaying: true)
            client.sendMedia(media)
            appendLog("Podcast queue sent")
        case .calendar:
            navigation = NavigationState(destination: "Next meeting", nextInstruction: "Route available", provider: "Calendar")
            client.sendNavigation(navigation)
            appendLog("Calendar destination sent")
        case .reminders:
            appendLog("Reminder created")
        case .home:
            appendLog("Home controls opened")
        case .shortcuts:
            appendLog("Shortcut triggered")
        case .parking:
            navigation = NavigationState(destination: "Parked car", nextInstruction: "Parking marker saved", provider: "CarLink")
            client.sendNavigation(navigation)
            appendLog("Parking marker updated")
        case .fuel:
            navigation = NavigationState(destination: "Fuel station", nextInstruction: "Nearby station added", provider: "CarLink")
            client.sendNavigation(navigation)
            appendLog("Fuel stop updated")
        case .tolls:
            appendLog("Toll and parking payments opened")
        case .charging:
            navigation = NavigationState(destination: "Charging station", nextInstruction: "Best stop added", provider: "EV route")
            client.sendNavigation(navigation)
            appendLog("Charging route updated")
        case .weather:
            appendLog("Weather card opened")
        case .safety:
            appendLog("Driving safety lock active")
        case .settings:
            sendTheme()
        case .dashboard:
            appendLog("Dashboard focused")
        }
    }

    private func handleClientEvent(_ event: CarLinkClient.Event) {
        switch event {
        case .connected:
            connectionStatus = "Socket connected"
        case .paired(let sessionId):
            activeSessionId = sessionId
            connectionStatus = "Paired"
            connectionMessage = "Connected to \(selectedReceiver?.name ?? "receiver")"
            showConnectionSuccess = true
            appendLog("Pairing accepted")
        case .rejected(let message):
            connectionStatus = "Rejected"
            appendLog(message)
        case .command(let command):
            appendLog("Receiver command: \(command)")
        case .closed:
            connectionStatus = "Disconnected"
            appendLog("Connection closed")
        case .failed(let message):
            connectionStatus = "Failed"
            appendLog(message)
        }
    }

    private func appendLog(_ message: String) {
        logs.insert(message, at: 0)
        logs = Array(logs.prefix(24))
    }
}
