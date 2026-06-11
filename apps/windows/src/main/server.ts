import http from "node:http";
import os from "node:os";
import { randomUUID } from "node:crypto";
import { Bonjour, type Service } from "bonjour-service";
import QRCode from "qrcode";
import { WebSocket, WebSocketServer } from "ws";
import {
  CARLINK_DEFAULT_PORT,
  CARLINK_PROTOCOL_VERSION,
  type CarLinkMessage,
  type ControlCommand,
  createEnvelope,
  parseCarLinkMessage
} from "@carlink/protocol";
import type { ReceiverClient, ReceiverLogEntry, ReceiverState } from "../shared";

interface ServerOptions {
  onStateChange: (state: ReceiverState) => void;
}

interface LiveClient extends ReceiverClient {
  socket: WebSocket;
  paired: boolean;
}

const receiverId = `win-${randomUUID()}`;
const receiverName = `${os.hostname()} CarLink`;

export class CarLinkServer {
  private httpServer: http.Server | null = null;
  private wsServer: WebSocketServer | null = null;
  private bonjour: Bonjour | null = null;
  private service: Service | null = null;
  private clients = new Map<string, LiveClient>();
  private logs: ReceiverLogEntry[] = [];
  private state: ReceiverState = {
    receiverId,
    receiverName,
    serverUrl: "",
    port: CARLINK_DEFAULT_PORT,
    serviceName: "_carlink._tcp",
    isAdvertising: false,
    pairing: null,
    pairingQrDataUrl: null,
    clients: [],
    media: {
      title: "No media playing",
      artist: "Connect an iPhone",
      source: "CarLink",
      isPlaying: false
    },
    navigation: {
      destination: "No route",
      nextInstruction: "Open navigation on the phone",
      provider: "CarLink"
    },
    theme: {
      mode: "dark",
      material: "glass",
      accent: "#14b8a6"
    },
    logs: []
  };

  constructor(private readonly options: ServerOptions) {}

  async start(): Promise<void> {
    if (this.httpServer) {
      return;
    }

    const server = http.createServer();
    const port = await listenOnAvailablePort(server, CARLINK_DEFAULT_PORT);
    this.httpServer = server;
    this.wsServer = new WebSocketServer({ server });
    this.state.port = port;
    this.state.serverUrl = `ws://${getPrimaryIPv4Address()}:${port}`;

    this.wsServer.on("connection", (socket) => this.handleConnection(socket));
    this.publishBonjour(port);
    await this.refreshPairing();
    this.pushLog("info", `Receiver listening on ${this.state.serverUrl}`);
    this.emit();
  }

  async stop(): Promise<void> {
    this.service?.stop();
    this.bonjour?.destroy();
    this.wsServer?.close();
    await new Promise<void>((resolve) => {
      this.httpServer?.close(() => resolve());
    });
    this.state.isAdvertising = false;
    this.emit();
  }

  getState(): ReceiverState {
    return {
      ...this.state,
      clients: Array.from(this.clients.values()).map(({ socket: _socket, paired: _paired, ...client }) => client),
      logs: this.logs.slice(0, 40)
    };
  }

  async refreshPairing(): Promise<ReceiverState> {
    const host = getPrimaryIPv4Address();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString();
    const pin = randomPin();
    const pairing = {
      protocol: "carlink" as const,
      version: CARLINK_PROTOCOL_VERSION,
      host,
      port: this.state.port,
      pin,
      receiverId,
      receiverName,
      expiresAt
    };

    this.state.pairing = pairing;
    this.state.serverUrl = `ws://${host}:${this.state.port}`;
    this.state.pairingQrDataUrl = await QRCode.toDataURL(JSON.stringify(pairing), {
      errorCorrectionLevel: "M",
      margin: 1,
      color: {
        dark: "#0f172a",
        light: "#ffffff"
      },
      width: 224
    });
    this.pushLog("info", `Pairing PIN refreshed: ${pin}`);
    this.emit();
    return this.getState();
  }

  sendCommand(command: ControlCommand): ReceiverState {
    const message = createEnvelope("control.command", { command });
    this.broadcast(message);
    this.pushLog("info", `Sent command ${command}`);
    this.emit();
    return this.getState();
  }

  private publishBonjour(port: number): void {
    this.bonjour = new Bonjour();
    this.service = this.bonjour.publish({
      name: receiverName,
      type: "carlink",
      port,
      txt: {
        protocol: "carlink",
        version: String(CARLINK_PROTOCOL_VERSION),
        receiverId,
        pairing: "required"
      }
    });
    this.state.isAdvertising = true;
    this.pushLog("info", "Advertising _carlink._tcp over Bonjour");
  }

  private handleConnection(socket: WebSocket): void {
    const pendingSessionId = randomUUID();
    this.pushLog("info", "Incoming client socket opened");

    socket.on("message", (raw) => {
      const message = parseCarLinkMessage(raw.toString());
      if (!message) {
        this.pushLog("warn", "Ignored malformed message");
        return;
      }
      this.handleMessage(socket, pendingSessionId, message);
    });

    socket.on("close", () => {
      const client = this.clients.get(pendingSessionId);
      if (client) {
        this.clients.delete(pendingSessionId);
        this.pushLog("info", `${client.name} disconnected`);
        this.emit();
      }
    });
  }

  private handleMessage(socket: WebSocket, sessionId: string, message: CarLinkMessage): void {
    if (message.type === "pairing.hello") {
      this.handlePairingHello(socket, sessionId, message);
      return;
    }

    const client = this.clients.get(sessionId);
    if (!client?.paired) {
      socket.send(JSON.stringify(createEnvelope("pairing.rejected", {
        reason: "bad_pin",
        message: "Pairing is required before sending control messages."
      })));
      return;
    }

    client.lastSeenAt = new Date().toISOString();

    if (message.type === "media.state") {
      this.state.media = message.payload;
      this.pushLog("info", `Media updated: ${message.payload.title}`);
    }

    if (message.type === "navigation.state") {
      this.state.navigation = message.payload;
      this.pushLog("info", `Navigation updated: ${message.payload.destination ?? "route active"}`);
    }

    if (message.type === "theme.state") {
      this.state.theme = message.payload;
      this.pushLog("info", `Theme updated: ${message.payload.material}`);
    }

    if (message.type === "heartbeat") {
      socket.send(JSON.stringify(createEnvelope("heartbeat", {
        sessionId,
        sequence: message.payload.sequence
      })));
    }

    this.emit();
  }

  private handlePairingHello(
    socket: WebSocket,
    sessionId: string,
    message: Extract<CarLinkMessage, { type: "pairing.hello" }>
  ): void {
    const pairing = this.state.pairing;
    const expired = !pairing || Date.parse(pairing.expiresAt) < Date.now();
    const pinMatches = pairing?.pin === message.payload.pin;

    if (expired || !pinMatches) {
      socket.send(JSON.stringify(createEnvelope("pairing.rejected", {
        reason: expired ? "expired" : "bad_pin",
        message: expired ? "Pairing PIN expired." : "Pairing PIN did not match."
      })));
      this.pushLog("warn", "Rejected pairing attempt");
      this.emit();
      return;
    }

    const now = new Date().toISOString();
    const client: LiveClient = {
      sessionId,
      deviceId: message.payload.device.id,
      name: message.payload.device.name,
      platform: message.payload.device.platform,
      osVersion: message.payload.device.osVersion,
      connectedAt: now,
      lastSeenAt: now,
      socket,
      paired: true
    };

    this.clients.set(sessionId, client);
    socket.send(JSON.stringify(createEnvelope("pairing.accepted", {
      sessionId,
      receiver: {
        id: receiverId,
        name: receiverName,
        platform: "windows",
        osVersion: os.release(),
        capabilities: ["touch", "keyboard", "media", "navigation", "voice", "telemetry", "windowManagement"]
      },
      display: {
        width: 1280,
        height: 720,
        scale: 1,
        safeArea: {
          top: 0,
          right: 0,
          bottom: 0,
          left: 0
        }
      },
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
    })));
    this.pushLog("info", `${client.name} paired`);
    this.emit();
  }

  private broadcast(message: CarLinkMessage): void {
    const serialized = JSON.stringify(message);
    for (const client of this.clients.values()) {
      if (client.socket.readyState === WebSocket.OPEN) {
        client.socket.send(serialized);
      }
    }
  }

  private pushLog(level: ReceiverLogEntry["level"], message: string): void {
    this.logs.unshift({
      id: randomUUID(),
      at: new Date().toISOString(),
      level,
      message
    });
    this.logs = this.logs.slice(0, 100);
    this.state.logs = this.logs.slice(0, 40);
  }

  private emit(): void {
    this.options.onStateChange(this.getState());
  }
}

function listenOnAvailablePort(server: http.Server, startPort: number): Promise<number> {
  return new Promise((resolve, reject) => {
    const tryPort = (port: number): void => {
      const onError = (error: NodeJS.ErrnoException): void => {
        server.off("listening", onListening);
        if (error.code === "EADDRINUSE" && port < startPort + 25) {
          tryPort(port + 1);
          return;
        }
        reject(error);
      };
      const onListening = (): void => {
        server.off("error", onError);
        resolve(port);
      };
      server.once("error", onError);
      server.once("listening", onListening);
      server.listen(port, "0.0.0.0");
    };
    tryPort(startPort);
  });
}

function getPrimaryIPv4Address(): string {
  for (const addresses of Object.values(os.networkInterfaces())) {
    for (const address of addresses ?? []) {
      if (address.family === "IPv4" && !address.internal) {
        return address.address;
      }
    }
  }
  return "127.0.0.1";
}

function randomPin(): string {
  return String(Math.floor(100000 + Math.random() * 900000));
}
