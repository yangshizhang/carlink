export const CARLINK_PROTOCOL_VERSION = 1;
export const CARLINK_SERVICE_TYPE = "_carlink._tcp";
export const CARLINK_DEFAULT_PORT = 38555;

export type CarLinkPlatform = "ios" | "windows" | "android" | "unknown";

export type CarLinkCapability =
  | "touch"
  | "keyboard"
  | "media"
  | "navigation"
  | "voice"
  | "telemetry"
  | "liquidGlassTheme"
  | "windowManagement";

export interface CarLinkEnvelope<TType extends string = string, TPayload = unknown> {
  id: string;
  type: TType;
  sentAt: string;
  payload: TPayload;
}

export interface DeviceDescriptor {
  id: string;
  name: string;
  platform: CarLinkPlatform;
  osVersion?: string;
  appVersion?: string;
  capabilities: CarLinkCapability[];
}

export interface DisplayDescriptor {
  width: number;
  height: number;
  scale: number;
  safeArea: {
    top: number;
    right: number;
    bottom: number;
    left: number;
  };
}

export interface PairingAdvert {
  protocol: "carlink";
  version: number;
  host: string;
  port: number;
  pin: string;
  receiverId: string;
  receiverName: string;
  expiresAt: string;
}

export interface PairingHelloPayload {
  pin: string;
  device: DeviceDescriptor;
  display: DisplayDescriptor;
}

export interface PairingAcceptedPayload {
  sessionId: string;
  receiver: DeviceDescriptor;
  display: DisplayDescriptor;
  expiresAt: string;
}

export interface PairingRejectedPayload {
  reason: "bad_pin" | "expired" | "unsupported_version" | "busy";
  message: string;
}

export interface HeartbeatPayload {
  sessionId: string;
  sequence: number;
}

export interface MediaStatePayload {
  title: string;
  artist: string;
  album?: string;
  artworkUrl?: string;
  durationMs?: number;
  positionMs?: number;
  isPlaying: boolean;
  source: string;
}

export interface NavigationStatePayload {
  destination?: string;
  nextInstruction?: string;
  distanceMeters?: number;
  eta?: string;
  provider?: string;
}

export type TouchPhase = "began" | "moved" | "ended" | "cancelled";

export interface TouchEventPayload {
  x: number;
  y: number;
  phase: TouchPhase;
  pointerId: number;
}

export type ControlCommand =
  | "media.playPause"
  | "media.next"
  | "media.previous"
  | "media.volumeUp"
  | "media.volumeDown"
  | "nav.open"
  | "voice.start"
  | "voice.stop"
  | "system.home"
  | "system.back";

export interface ControlCommandPayload {
  command: ControlCommand;
  args?: Record<string, string | number | boolean>;
}

export interface ThemeStatePayload {
  mode: "light" | "dark" | "night";
  material: "standard" | "glass" | "liquidGlass";
  accent: string;
}

export type CarLinkMessage =
  | CarLinkEnvelope<"pairing.hello", PairingHelloPayload>
  | CarLinkEnvelope<"pairing.accepted", PairingAcceptedPayload>
  | CarLinkEnvelope<"pairing.rejected", PairingRejectedPayload>
  | CarLinkEnvelope<"heartbeat", HeartbeatPayload>
  | CarLinkEnvelope<"media.state", MediaStatePayload>
  | CarLinkEnvelope<"navigation.state", NavigationStatePayload>
  | CarLinkEnvelope<"touch.event", TouchEventPayload>
  | CarLinkEnvelope<"control.command", ControlCommandPayload>
  | CarLinkEnvelope<"theme.state", ThemeStatePayload>;

export function createEnvelope<TType extends CarLinkMessage["type"]>(
  type: TType,
  payload: Extract<CarLinkMessage, { type: TType }>["payload"]
): Extract<CarLinkMessage, { type: TType }> {
  return {
    id: cryptoSafeId(),
    type,
    sentAt: new Date().toISOString(),
    payload
  } as Extract<CarLinkMessage, { type: TType }>;
}

function cryptoSafeId(): string {
  const source =
    typeof globalThis.crypto !== "undefined" && "randomUUID" in globalThis.crypto
      ? globalThis.crypto.randomUUID()
      : `${Date.now().toString(36)}-${Math.random().toString(36).slice(2)}`;
  return source;
}

export function parseCarLinkMessage(input: string): CarLinkMessage | null {
  try {
    const value = JSON.parse(input) as Partial<CarLinkMessage>;
    if (!value || typeof value !== "object") {
      return null;
    }
    if (typeof value.id !== "string" || typeof value.type !== "string") {
      return null;
    }
    if (typeof value.sentAt !== "string" || !("payload" in value)) {
      return null;
    }
    return value as CarLinkMessage;
  } catch {
    return null;
  }
}
