import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: CarLinkModel
    @State private var showScanner = false

    private let featureRows: [[CarLinkFeature]] = [
        [
            CarLinkFeature("Voice", "Hands-free commands", "waveform.circle.fill", .cyan, .voice),
            CarLinkFeature("Maps", "Route and ETA", "map.fill", .green, .maps),
            CarLinkFeature("Phone", "Calls and recents", "phone.fill", .mint, .phone),
            CarLinkFeature("Messages", "Read and reply", "message.fill", .blue, .messages)
        ],
        [
            CarLinkFeature("Music", "Now playing", "music.note", .pink, .music),
            CarLinkFeature("Podcasts", "Queue and skip", "dot.radiowaves.left.and.right", .purple, .podcasts),
            CarLinkFeature("Calendar", "Trip from events", "calendar", .orange, .calendar),
            CarLinkFeature("Reminders", "Road tasks", "checklist", .yellow, .reminders)
        ],
        [
            CarLinkFeature("Home", "Garage and scenes", "house.fill", .indigo, .home),
            CarLinkFeature("Shortcuts", "Drive automations", "bolt.fill", .teal, .shortcuts),
            CarLinkFeature("Parking", "Saved location", "parkingsign.circle.fill", .brown, .parking),
            CarLinkFeature("Charging", "EV stops", "bolt.car.fill", .green, .charging)
        ],
        [
            CarLinkFeature("Fuel", "Nearby stations", "fuelpump.fill", .orange, .fuel),
            CarLinkFeature("ETC", "Tolls and parking", "creditcard.fill", .mint, .tolls),
            CarLinkFeature("Weather", "Trip conditions", "cloud.sun.fill", .yellow, .weather),
            CarLinkFeature("Safety", "Drive lock", "lock.shield.fill", .red, .safety)
        ],
        [
            CarLinkFeature("Dashboard", "Split view", "rectangle.grid.2x2.fill", .cyan, .dashboard),
            CarLinkFeature("Vehicle", "Climate and seats", "car.fill", .gray, .settings),
            CarLinkFeature("Ultra", "Multi-display layout", "rectangle.connected.to.line.below", .blue, .dashboard),
            CarLinkFeature("Settings", "Theme and devices", "gearshape.fill", .gray, .settings)
        ]
    ]

    var body: some View {
        ZStack {
            CarLinkBackground()
            VStack(spacing: 0) {
                TopStatusBar(showScanner: $showScanner)
                ScrollView {
                    VStack(spacing: 16) {
                        DashboardPanel()
                        ConnectionPanel(showScanner: $showScanner)
                        AppGrid(rows: featureRows)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 88)
                }
                .scrollIndicators(.hidden)
            }
            VStack {
                Spacer()
                DockBar()
                    .padding(.horizontal, 18)
                    .padding(.bottom, 14)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showScanner) {
            QRCodeScannerView(
                onCode: { code in
                    showScanner = false
                    model.applyPairingCode(code)
                },
                onCancel: {
                    showScanner = false
                }
            )
            .ignoresSafeArea()
        }
        .alert("Connect CarLink", isPresented: $model.showConnectionConfirmation) {
            Button("Connect") {
                model.confirmPendingConnection()
            }
            Button("Cancel", role: .cancel) {
                model.showConnectionConfirmation = false
            }
        } message: {
            Text(model.connectionMessage)
        }
        .alert("CarLink Paired", isPresented: $model.showConnectionSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.activeSessionId ?? model.connectionMessage)
        }
        .onAppear {
            model.startDiscovery()
        }
    }
}

private struct TopStatusBar: View {
    @EnvironmentObject private var model: CarLinkModel
    @Binding var showScanner: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "car.front.waves.up.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 50, height: 50)
                .background(.cyan, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text("CarLink")
                    .font(.system(size: 30, weight: .bold))
                Text(model.connectionStatus)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(model.activeSessionId == nil ? .secondary : .green)
            }

            Spacer()

            Button {
                showScanner = true
            } label: {
                Image(systemName: "qrcode.viewfinder")
                    .font(.title3.weight(.bold))
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.plain)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))

            Label(timeText, systemImage: "iphone")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(.thinMaterial, in: Capsule())
        }
        .padding(16)
    }

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
}

private struct DashboardPanel: View {
    @EnvironmentObject private var model: CarLinkModel

    var body: some View {
        HStack(spacing: 14) {
            Button {
                model.perform(.maps)
            } label: {
                MapPreview()
            }
            .buttonStyle(.plain)

            VStack(spacing: 14) {
                NowPlayingCard()
                SuggestionStack()
            }
            .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, minHeight: 270)
    }
}

private struct MapPreview: View {
    @EnvironmentObject private var model: CarLinkModel

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.08, green: 0.13, blue: 0.16),
                            Color(red: 0.07, green: 0.18, blue: 0.14)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(MapGrid().opacity(0.38))
                .overlay(RouteLine().stroke(.cyan, style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)))

            VStack(alignment: .leading, spacing: 8) {
                Label(model.navigation.destination ?? "Route", systemImage: "location.north.fill")
                    .font(.title2.weight(.bold))
                Text(model.navigation.nextInstruction ?? "Ready for navigation")
                    .foregroundStyle(.secondary)
                    .font(.callout.weight(.semibold))
            }
            .padding(18)
        }
        .overlay(alignment: .topTrailing) {
            Label("ETA 18 min", systemImage: "clock.fill")
                .font(.subheadline.weight(.bold))
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(16)
        }
    }
}

private struct MapGrid: View {
    var body: some View {
        Canvas { context, size in
            let grid = Path { path in
                for x in stride(from: 0.0, through: size.width, by: 34) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                for y in stride(from: 0.0, through: size.height, by: 34) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
            }
            context.stroke(grid, with: .color(.white.opacity(0.2)), lineWidth: 1)
        }
    }
}

private struct RouteLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 36, y: rect.maxY - 70))
        path.addCurve(
            to: CGPoint(x: rect.maxX - 44, y: rect.minY + 70),
            control1: CGPoint(x: rect.width * 0.38, y: rect.maxY - 30),
            control2: CGPoint(x: rect.width * 0.62, y: rect.minY + 36)
        )
        return path
    }
}

private struct NowPlayingCard: View {
    @EnvironmentObject private var model: CarLinkModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "music.note")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(width: 54, height: 54)
                    .background(
                        LinearGradient(colors: [.cyan, .pink], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                VStack(alignment: .leading, spacing: 3) {
                    Text(model.media.title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(model.media.artist)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }

            HStack(spacing: 12) {
                MediaButton("backward.fill")
                Button {
                    model.perform(.music)
                } label: {
                    Image(systemName: model.media.isPlaying ? "pause.fill" : "play.fill")
                }
                .mediaButtonStyle()
                MediaButton("forward.fill")
                MediaButton("speaker.wave.2.fill")
            }
        }
        .carPanel()
    }
}

private struct MediaButton: View {
    let symbol: String

    init(_ symbol: String) {
        self.symbol = symbol
    }

    var body: some View {
        Button {} label: {
            Image(systemName: symbol)
        }
        .mediaButtonStyle()
    }
}

private struct SuggestionStack: View {
    @EnvironmentObject private var model: CarLinkModel

    var body: some View {
        VStack(spacing: 10) {
            SuggestionButton(title: "Next event", detail: "Tap to route", symbol: "calendar") {
                model.perform(.calendar)
            }
            SuggestionButton(title: "EV route", detail: "Charging stop ready", symbol: "bolt.car.fill") {
                model.perform(.charging)
            }
            SuggestionButton(title: "Home scene", detail: "Garage and lights", symbol: "house.fill") {
                model.perform(.home)
            }
        }
    }
}

private struct SuggestionButton: View {
    let title: String
    let detail: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.headline)
                    .frame(width: 34, height: 34)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

private struct ConnectionPanel: View {
    @EnvironmentObject private var model: CarLinkModel
    @Binding var showScanner: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Receiver", systemImage: "display")
                    .font(.headline)
                Spacer()
                Button {
                    showScanner = true
                } label: {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Scan")
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
            }

            HStack(spacing: 10) {
                TextField("PIN", text: $model.pin)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .font(.title3.monospacedDigit().weight(.bold))
                    .padding(12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))

                Button {
                    model.startDiscovery()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }

            if model.receivers.isEmpty {
                ReceiverRow(name: "No receiver found", detail: "Start Windows Receiver or scan QR", symbol: "wifi.slash") {}
                    .disabled(true)
            } else {
                ForEach(model.receivers) { receiver in
                    ReceiverRow(name: receiver.name, detail: "\(receiver.host):\(receiver.port)", symbol: "display.and.arrow.down") {
                        model.prepareConnection(to: receiver)
                    }
                }
            }
        }
        .carPanel()
    }
}

private struct ReceiverRow: View {
    let name: String
    let detail: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(.headline)
                    Text(detail)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

private struct AppGrid: View {
    @EnvironmentObject private var model: CarLinkModel
    let rows: [[CarLinkFeature]]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 12) {
                    ForEach(rows[rowIndex]) { feature in
                        FeatureTile(feature: feature) {
                            model.perform(feature.action)
                        }
                    }
                }
            }
        }
    }
}

private struct FeatureTile: View {
    let feature: CarLinkFeature
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: feature.symbol)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(feature.color.gradient, in: RoundedRectangle(cornerRadius: 8))
                Text(feature.title)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(feature.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct DockBar: View {
    @EnvironmentObject private var model: CarLinkModel

    var body: some View {
        HStack(spacing: 12) {
            DockButton(symbol: "rectangle.grid.2x2.fill") { model.perform(.dashboard) }
            DockButton(symbol: "map.fill") { model.perform(.maps) }
            DockButton(symbol: "music.note") { model.perform(.music) }
            DockButton(symbol: "phone.fill") { model.perform(.phone) }
            DockButton(symbol: "waveform.circle.fill") { model.perform(.voice) }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct DockButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title3.weight(.bold))
                .frame(maxWidth: .infinity, minHeight: 46)
        }
        .buttonStyle(.plain)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct CarLinkFeature: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let symbol: String
    let color: Color
    let action: CarLinkFeatureAction

    init(_ title: String, _ subtitle: String, _ symbol: String, _ color: Color, _ action: CarLinkFeatureAction) {
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.color = color
        self.action = action
    }
}

private struct CarLinkBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.02, green: 0.03, blue: 0.04),
                Color(red: 0.03, green: 0.08, blue: 0.08),
                Color(red: 0.10, green: 0.05, blue: 0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

private extension View {
    func carPanel() -> some View {
        self
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
    }

    func mediaButtonStyle() -> some View {
        self
            .font(.headline.weight(.bold))
            .frame(width: 46, height: 42)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}
