import Foundation

final class CarLinkClient {
    enum Event {
        case connected
        case paired
        case rejected(String)
        case command(String)
        case closed
        case failed(String)
    }

    private var task: URLSessionWebSocketTask?
    private var callback: ((Event) -> Void)?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func connect(to receiver: DiscoveredReceiver, pin: String, callback: @escaping (Event) -> Void) {
        self.callback = callback
        task?.cancel(with: .goingAway, reason: nil)
        task = URLSession.shared.webSocketTask(with: receiver.endpoint)
        task?.resume()
        callback(.connected)
        sendPairing(pin: pin)
        receiveLoop()
    }

    func sendMedia(_ media: MediaState) {
        send(Envelope(type: "media.state", payload: media))
    }

    func sendNavigation(_ navigation: NavigationState) {
        send(Envelope(type: "navigation.state", payload: navigation))
    }

    func sendTheme(_ theme: ThemeState) {
        send(Envelope(type: "theme.state", payload: theme))
    }

    private func sendPairing(pin: String) {
        let payload = PairingHello(pin: pin, device: .current, display: .current)
        send(Envelope(type: "pairing.hello", payload: payload))
    }

    private func send<T: Codable>(_ envelope: Envelope<T>) {
        do {
            let data = try encoder.encode(envelope)
            guard let string = String(data: data, encoding: .utf8) else {
                return
            }
            task?.send(.string(string)) { [weak self] error in
                if let error {
                    self?.callback?(.failed(error.localizedDescription))
                }
            }
        } catch {
            callback?(.failed(error.localizedDescription))
        }
    }

    private func receiveLoop() {
        task?.receive { [weak self] result in
            guard let self else {
                return
            }
            switch result {
            case .success(let message):
                self.handle(message)
                self.receiveLoop()
            case .failure(let error):
                self.callback?(.failed(error.localizedDescription))
            }
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) {
        guard case .string(let string) = message,
              let data = string.data(using: .utf8),
              let base = try? decoder.decode(BasicEnvelope.self, from: data)
        else {
            return
        }

        if base.type == "pairing.accepted" {
            callback?(.paired)
            return
        }

        if base.type == "pairing.rejected",
           let rejected = try? decoder.decode(Envelope<PairingRejected>.self, from: data) {
            callback?(.rejected(rejected.payload.message))
            return
        }

        if base.type == "control.command",
           let command = try? decoder.decode(Envelope<ControlCommandPayload>.self, from: data) {
            callback?(.command(command.payload.command))
        }
    }
}

private struct BasicEnvelope: Codable {
    let type: String
}
