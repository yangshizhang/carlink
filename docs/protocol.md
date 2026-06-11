# CarLink Protocol v1

CarLink Protocol is a self-owned companion protocol between a phone app and a desktop receiver. It is not compatible with Apple CarPlay, Android Auto, CarLife, or any private OEM integration.

## Transport

- Discovery: Bonjour/mDNS service `_carlink._tcp`.
- Control channel: WebSocket.
- Message encoding: UTF-8 JSON envelopes.
- Binary media or video streams are reserved for a later WebRTC transport.

## Bonjour TXT Fields

| Field | Example | Description |
| --- | --- | --- |
| `protocol` | `carlink` | Protocol marker. |
| `version` | `1` | Protocol version. |
| `receiverId` | `win-...` | Stable receiver session id. |
| `pairing` | `required` | Pairing requirement. |

## Envelope

```json
{
  "id": "uuid",
  "type": "pairing.hello",
  "sentAt": "2026-06-11T12:00:00.000Z",
  "payload": {}
}
```

## Pairing

The receiver creates a six-digit PIN and a QR payload:

```json
{
  "protocol": "carlink",
  "version": 1,
  "host": "192.168.1.10",
  "port": 38555,
  "pin": "123456",
  "receiverId": "win-...",
  "receiverName": "PC CarLink",
  "expiresAt": "2026-06-11T12:05:00.000Z"
}
```

The client opens `ws://host:port` and sends `pairing.hello`. If accepted, the receiver returns `pairing.accepted` with a session id.

## Message Types

| Type | Direction | Purpose |
| --- | --- | --- |
| `pairing.hello` | phone to receiver | Start PIN pairing. |
| `pairing.accepted` | receiver to phone | Confirm pairing. |
| `pairing.rejected` | receiver to phone | Reject invalid or expired pairing. |
| `heartbeat` | both | Keepalive and latency measurement. |
| `media.state` | phone to receiver | Current media metadata. |
| `navigation.state` | phone to receiver | Route summary and next instruction. |
| `theme.state` | phone to receiver | Theme and material preference. |
| `control.command` | receiver to phone | User action from receiver UI. |
| `touch.event` | receiver to phone | Future direct touch event stream. |

## Roadmap

- TLS with pinned receiver identity after initial pairing.
- WebRTC screen or scene stream.
- Session resumption without retyping a PIN.
- Capability negotiation for microphone, steering-wheel controls, and multiple displays.
