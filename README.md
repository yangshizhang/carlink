# CarLink

CarLink is a self-owned phone-to-PC in-car companion protocol. It does not implement or emulate Apple CarPlay, MFi, Android Auto, or any private vehicle integration protocol.

The first MVP includes:

- Windows Receiver built with Electron, React, WebSocket, and Bonjour service discovery.
- iOS client skeleton built with SwiftUI, Network framework Bonjour discovery, and URLSession WebSocket.
- CarLink Protocol v1 with pairing, capability negotiation, control events, media state, and telemetry messages.
- GitHub Actions workflows for Windows builds and iOS signing/export when repository secrets are configured.

## Local Windows Development

```powershell
npm install
npm run build:protocol
npm run dev:windows
```

The Windows app starts a local CarLink WebSocket server and advertises `_carlink._tcp` through Bonjour/mDNS.

## iOS Development

The iOS project uses XcodeGen so the generated `.xcodeproj` stays out of source control.

```bash
cd apps/ios
brew install xcodegen
xcodegen generate
open CarLink.xcodeproj
```

See [docs/build-ios.md](docs/build-ios.md) for CI signing secrets.
