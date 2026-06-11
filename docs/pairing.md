# Pairing

CarLink MVP pairing is local-network only.

1. Windows Receiver starts a WebSocket server.
2. Windows Receiver advertises `_carlink._tcp` with Bonjour/mDNS.
3. Windows Receiver generates a six-digit PIN and QR payload.
4. iOS discovers the receiver with `NetServiceBrowser`.
5. iOS connects to the receiver WebSocket and sends `pairing.hello`.
6. Receiver validates the PIN and returns `pairing.accepted`.

The current MVP is designed for local development and trusted LANs. Production hardening should add TLS, receiver identity persistence, session revocation, and a pairing approval prompt on the receiver.
