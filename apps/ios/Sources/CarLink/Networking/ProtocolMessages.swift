import Foundation
import UIKit

let carLinkProtocolVersion = 1

struct PairingAdvert: Codable {
    let protocolName: String
    let version: Int
    let host: String
    let port: Int
    let pin: String
    let receiverId: String
    let receiverName: String
    let expiresAt: String

    enum CodingKeys: String, CodingKey {
        case protocolName = "protocol"
        case version
        case host
        case port
        case pin
        case receiverId
        case receiverName
        case expiresAt
    }
}

struct Envelope<Payload: Codable>: Codable {
    let id: String
    let type: String
    let sentAt: String
    let payload: Payload

    init(type: String, payload: Payload) {
        self.id = UUID().uuidString
        self.type = type
        self.sentAt = ISO8601DateFormatter().string(from: Date())
        self.payload = payload
    }
}

struct DeviceDescriptor: Codable {
    let id: String
    let name: String
    let platform: String
    let osVersion: String
    let appVersion: String
    let capabilities: [String]

    static var current: DeviceDescriptor {
        DeviceDescriptor(
            id: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
            name: UIDevice.current.name,
            platform: "ios",
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0",
            capabilities: ["touch", "media", "navigation", "voice", "telemetry", "liquidGlassTheme"]
        )
    }
}

struct DisplayDescriptor: Codable {
    let width: Double
    let height: Double
    let scale: Double
    let safeArea: Insets

    struct Insets: Codable {
        let top: Double
        let right: Double
        let bottom: Double
        let left: Double
    }

    static var current: DisplayDescriptor {
        let screen = UIScreen.main
        return DisplayDescriptor(
            width: screen.bounds.width,
            height: screen.bounds.height,
            scale: screen.scale,
            safeArea: Insets(top: 0, right: 0, bottom: 0, left: 0)
        )
    }
}

struct PairingHello: Codable {
    let pin: String
    let device: DeviceDescriptor
    let display: DisplayDescriptor
}

struct PairingAccepted: Codable {
    let sessionId: String
}

struct PairingRejected: Codable {
    let reason: String
    let message: String
}

struct MediaState: Codable {
    let title: String
    let artist: String
    let source: String
    let isPlaying: Bool
}

struct NavigationState: Codable {
    let destination: String?
    let nextInstruction: String?
    let provider: String?
}

struct ThemeState: Codable {
    let mode: String
    let material: String
    let accent: String
}

struct ControlCommandPayload: Codable {
    let command: String
}

struct EmptyPayload: Codable {}
