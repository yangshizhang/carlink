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
        guard let host = sender.hostName, sender.port > 0 else {
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
}
