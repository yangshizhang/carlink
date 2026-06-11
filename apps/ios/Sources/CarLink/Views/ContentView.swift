import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: CarLinkModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HeaderView()
                    ReceiverPickerView()
                    DashboardActionsView()
                    ProtocolLogView()
                }
                .padding(18)
            }
            .background(CarLinkBackground())
        }
    }
}

private struct HeaderView: View {
    @EnvironmentObject private var model: CarLinkModel

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "car.front.waves.up")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: 58, height: 58)
                .background(Color.cyan)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text("CarLink")
                    .font(.system(size: 30, weight: .bold))
                Text(model.connectionStatus)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Label("iOS \(UIDevice.current.systemVersion)", systemImage: "iphone")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.thinMaterial, in: Capsule())
        }
        .carPanel()
    }
}

private struct ReceiverPickerView: View {
    @EnvironmentObject private var model: CarLinkModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Receivers", systemImage: "dot.radiowaves.left.and.right")
                    .font(.headline)
                Spacer()
                Button {
                    model.startDiscovery()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .tint(.cyan)
            }

            TextField("Receiver PIN", text: $model.pin)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .font(.title2.monospacedDigit())
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))

            if model.receivers.isEmpty {
                Text("Waiting for CarLink Receiver on local network")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
            } else {
                ForEach(model.receivers) { receiver in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(receiver.name)
                                .font(.headline)
                            Text("\(receiver.host):\(receiver.port)")
                                .font(.footnote.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            model.connect(to: receiver)
                        } label: {
                            Image(systemName: "link")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                    }
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .carPanel()
    }
}

private struct DashboardActionsView: View {
    @EnvironmentObject private var model: CarLinkModel

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
            ActionTile(title: "Media", subtitle: model.media.title, icon: "music.note") {
                model.sendMediaDemo()
            }
            ActionTile(title: "Navigation", subtitle: model.navigation.destination ?? "No route", icon: "location.north") {
                model.sendNavigationDemo()
            }
            ActionTile(title: "Theme", subtitle: model.theme.material, icon: "circle.hexagongrid") {
                model.sendTheme()
            }
            ActionTile(title: "Voice", subtitle: "Ready", icon: "mic") {
                model.sendTheme()
            }
        }
    }
}

private struct ActionTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.title2.weight(.bold))
                    .frame(width: 44, height: 44)
                    .background(Color.cyan.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
            .padding(14)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

private struct ProtocolLogView: View {
    @EnvironmentObject private var model: CarLinkModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Protocol Log", systemImage: "list.bullet.rectangle")
                .font(.headline)
            ForEach(Array(model.logs.enumerated()), id: \.offset) { _, log in
                Text(log)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .carPanel()
    }
}

private struct CarLinkBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color.black, Color(red: 0.04, green: 0.08, blue: 0.08), Color(red: 0.11, green: 0.07, blue: 0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

private extension View {
    func carPanel() -> some View {
        self
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
    }
}
