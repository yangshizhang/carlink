import Darwin
import Foundation

struct DiscoveredReceiver: Identifiable, Hashable {
    let id: String
    let name: String
    let host: String
    let port: Int
    let receiverId: String

    var endpoint: URL {
        URL(string: "ws://\(host):\(port)")!
    }

    init(id: String, name: String, host: String, port: Int, receiverId: String) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.receiverId = receiverId
    }

    init(advert: PairingAdvert) {
        self.id = "\(advert.receiverId)-\(advert.port)"
        self.name = advert.receiverName
        self.host = advert.host
        self.port = advert.port
        self.receiverId = advert.receiverId
    }
}

final class BonjourBrowser: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    var onUpdate: (([DiscoveredReceiver]) -> Void)?

    private let browser = NetServiceBrowser()
    private var services: [NetService] = []
    private var receivers: [DiscoveredReceiver] = []

    override init() {
        super.init()
        browser.delegate = self
    }

    func start() {
        browser.searchForServices(ofType: "_carlink._tcp.", inDomain: "local.")
    }

    func stop() {
        browser.stop()
        services.removeAll()
        receivers.removeAll()
        onUpdate?([])
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        services.append(service)
        service.delegate = self
        service.resolve(withTimeout: 5)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        receivers.removeAll { $0.name == service.name }
        onUpdate?(receivers)
    }

    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let host = hostAddress(from: sender), sender.port > 0 else {
            return
        }
        let txt = NetService.dictionary(fromTXTRecord: sender.txtRecordData() ?? Data())
        let receiverId = txt["receiverId"].flatMap { String(data: $0, encoding: .utf8) } ?? sender.name
        let receiver = DiscoveredReceiver(
            id: "\(receiverId)-\(sender.port)",
            name: sender.name,
            host: host,
            port: sender.port,
            receiverId: receiverId
        )
        if !receivers.contains(receiver) {
            receivers.append(receiver)
        }
        onUpdate?(receivers)
    }

    private func hostAddress(from service: NetService) -> String? {
        for address in service.addresses ?? [] {
            var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let result = address.withUnsafeBytes { pointer -> Int32 in
                guard let baseAddress = pointer.baseAddress else {
                    return -1
                }
                let socketAddress = baseAddress.assumingMemoryBound(to: sockaddr.self)
                return getnameinfo(
                    socketAddress,
                    socklen_t(address.count),
                    &hostBuffer,
                    socklen_t(hostBuffer.count),
                    nil,
                    0,
                    NI_NUMERICHOST
                )
            }

            if result == 0 {
                let host = String(cString: hostBuffer)
                if host.contains(".") {
                    return host
                }
            }
        }

        return service.hostName?.trimmingCharacters(in: CharacterSet(charactersIn: "."))
    }
}
