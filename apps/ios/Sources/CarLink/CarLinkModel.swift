import Foundation
import SwiftUI

@MainActor
final class CarLinkModel: ObservableObject {
    @Published var receivers: [DiscoveredReceiver] = []
    @Published var selectedReceiver: DiscoveredReceiver?
    @Published var pin = ""
    @Published var connectionStatus = "Not connected"
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

    func connect(to receiver: DiscoveredReceiver) {
        selectedReceiver = receiver
        guard !pin.trimmingCharacters(in: .whitespaces).isEmpty else {
            appendLog("Enter the receiver PIN first")
            return
        }
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

    private func handleClientEvent(_ event: CarLinkClient.Event) {
        switch event {
        case .connected:
            connectionStatus = "Socket connected"
        case .paired:
            connectionStatus = "Paired"
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
