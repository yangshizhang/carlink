import type {
  ControlCommand,
  MediaStatePayload,
  NavigationStatePayload,
  PairingAdvert,
  ThemeStatePayload
} from "@carlink/protocol";

export interface ReceiverClient {
  sessionId: string;
  deviceId: string;
  name: string;
  platform: string;
  osVersion?: string;
  connectedAt: string;
  lastSeenAt: string;
}

export interface ReceiverLogEntry {
  id: string;
  at: string;
  level: "info" | "warn" | "error";
  message: string;
}

export interface ReceiverState {
  receiverId: string;
  receiverName: string;
  serverUrl: string;
  port: number;
  serviceName: string;
  isAdvertising: boolean;
  pairing: PairingAdvert | null;
  pairingQrDataUrl: string | null;
  clients: ReceiverClient[];
  media: MediaStatePayload;
  navigation: NavigationStatePayload;
  theme: ThemeStatePayload;
  logs: ReceiverLogEntry[];
}

export interface CarLinkBridge {
  getState: () => Promise<ReceiverState>;
  refreshPairing: () => Promise<ReceiverState>;
  sendCommand: (command: ControlCommand) => Promise<ReceiverState>;
  onState: (callback: (state: ReceiverState) => void) => () => void;
}
