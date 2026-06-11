import SwiftUI

@main
struct CarLinkApp: App {
    @StateObject private var model = CarLinkModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .onAppear {
                    model.startDiscovery()
                }
        }
    }
}
