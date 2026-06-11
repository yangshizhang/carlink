import { useEffect, useMemo, useState } from "react";
import {
  CarFront,
  CheckCircle2,
  Compass,
  Gauge,
  Home,
  Mic,
  Music2,
  Phone,
  RadioTower,
  RefreshCcw,
  Settings,
  SkipBack,
  SkipForward,
  Smartphone,
  Volume2
} from "lucide-react";
import type { ControlCommand } from "@carlink/protocol";
import { createEnvelope } from "@carlink/protocol";
import type { ReceiverState } from "../../shared";

const commandButtons: Array<{ command: ControlCommand; label: string; icon: typeof Music2 }> = [
  { command: "system.home", label: "Home", icon: Home },
  { command: "media.previous", label: "Previous", icon: SkipBack },
  { command: "media.playPause", label: "Play", icon: Music2 },
  { command: "media.next", label: "Next", icon: SkipForward },
  { command: "media.volumeUp", label: "Volume", icon: Volume2 },
  { command: "voice.start", label: "Voice", icon: Mic }
];

export function App(): JSX.Element {
  const [state, setState] = useState<ReceiverState | null>(null);
  const bridge = useMemo(() => window.carlink ?? createPreviewBridge(), []);

  useEffect(() => {
    bridge.getState().then(setState);
    return bridge.onState(setState);
  }, [bridge]);

  const pairedCount = state?.clients.length ?? 0;
  const expiresIn = useMemo(() => {
    if (!state?.pairing) {
      return "No PIN";
    }
    const seconds = Math.max(0, Math.floor((Date.parse(state.pairing.expiresAt) - Date.now()) / 1000));
    return `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, "0")}`;
  }, [state?.pairing]);

  async function sendCommand(command: ControlCommand): Promise<void> {
    setState(await bridge.sendCommand(command));
  }

  if (!state) {
    return <div className="loading">Starting CarLink Receiver...</div>;
  }

  return (
    <main className="app-shell">
      <aside className="rail" aria-label="Primary">
        <div className="brand-mark">
          <CarFront size={26} />
        </div>
        <button className="rail-button active" title="Dashboard" aria-label="Dashboard">
          <Gauge size={22} />
        </button>
        <button className="rail-button" title="Media" aria-label="Media">
          <Music2 size={22} />
        </button>
        <button className="rail-button" title="Navigation" aria-label="Navigation">
          <Compass size={22} />
        </button>
        <button className="rail-button" title="Phone" aria-label="Phone">
          <Phone size={22} />
        </button>
        <button className="rail-button" title="Settings" aria-label="Settings">
          <Settings size={22} />
        </button>
      </aside>

      <section className="surface">
        <header className="topbar">
          <div>
            <h1>CarLink Receiver</h1>
            <p>{state.receiverName}</p>
          </div>
          <div className="status-row">
            <span className={state.isAdvertising ? "status online" : "status"}>
              <RadioTower size={16} />
              {state.isAdvertising ? "_carlink._tcp" : "Offline"}
            </span>
            <span className={pairedCount > 0 ? "status online" : "status"}>
              <Smartphone size={16} />
              {pairedCount} paired
            </span>
          </div>
        </header>

        <section className="dashboard-grid">
          <section className="panel pairing-panel">
            <div className="panel-header">
              <div>
                <h2>Pair iPhone</h2>
                <p>{state.serverUrl}</p>
              </div>
              <button className="icon-button" title="Refresh PIN" aria-label="Refresh PIN" onClick={() => bridge.refreshPairing()}>
                <RefreshCcw size={20} />
              </button>
            </div>
            <div className="pairing-content">
              <div className="qr-frame">
                {state.pairingQrDataUrl ? <img src={state.pairingQrDataUrl} alt="CarLink pairing QR code" /> : null}
              </div>
              <div className="pin-block">
                <span className="eyebrow">PIN</span>
                <strong>{state.pairing?.pin ?? "------"}</strong>
                <span className="timer">{expiresIn}</span>
              </div>
            </div>
          </section>

          <section className="panel media-panel">
            <div className="panel-header">
              <div>
                <h2>Media</h2>
                <p>{state.media.source}</p>
              </div>
              <span className={state.media.isPlaying ? "pill playing" : "pill"}>{state.media.isPlaying ? "Playing" : "Paused"}</span>
            </div>
            <div className="album-art">
              <Music2 size={58} />
            </div>
            <h3>{state.media.title}</h3>
            <p>{state.media.artist}</p>
            <div className="command-row">
              {commandButtons.slice(1, 5).map((item) => {
                const Icon = item.icon;
                return (
                  <button key={item.command} className="round-command" title={item.label} aria-label={item.label} onClick={() => sendCommand(item.command)}>
                    <Icon size={20} />
                  </button>
                );
              })}
            </div>
          </section>

          <section className="panel nav-panel">
            <div className="panel-header">
              <div>
                <h2>Navigation</h2>
                <p>{state.navigation.provider}</p>
              </div>
              <Compass size={24} />
            </div>
            <div className="route-visual">
              <span />
              <span />
              <span />
            </div>
            <h3>{state.navigation.destination}</h3>
            <p>{state.navigation.nextInstruction}</p>
            <button className="primary-button" onClick={() => sendCommand("nav.open")}>
              <Compass size={18} />
              Open Navigation
            </button>
          </section>

          <section className="panel devices-panel">
            <div className="panel-header">
              <div>
                <h2>Devices</h2>
                <p>Live sessions</p>
              </div>
              <CheckCircle2 size={24} />
            </div>
            <div className="device-list">
              {state.clients.length === 0 ? (
                <div className="empty-device">Waiting for iPhone client</div>
              ) : (
                state.clients.map((client) => (
                  <div className="device-item" key={client.sessionId}>
                    <Smartphone size={22} />
                    <div>
                      <strong>{client.name}</strong>
                      <span>{client.platform} {client.osVersion}</span>
                    </div>
                  </div>
                ))
              )}
            </div>
          </section>

          <section className="panel controls-panel">
            <div className="panel-header">
              <div>
                <h2>Controls</h2>
                <p>Commands sent over CarLink Protocol</p>
              </div>
            </div>
            <div className="control-grid">
              {commandButtons.map((item) => {
                const Icon = item.icon;
                return (
                  <button key={item.command} className="control-button" onClick={() => sendCommand(item.command)}>
                    <Icon size={20} />
                    <span>{item.label}</span>
                  </button>
                );
              })}
            </div>
          </section>

          <section className="panel logs-panel">
            <div className="panel-header">
              <div>
                <h2>Protocol Log</h2>
                <p>Newest first</p>
              </div>
            </div>
            <div className="log-list">
              {state.logs.map((log) => (
                <div className="log-line" key={log.id}>
                  <span className={`log-level ${log.level}`}>{log.level}</span>
                  <span>{new Date(log.at).toLocaleTimeString()}</span>
                  <strong>{log.message}</strong>
                </div>
              ))}
            </div>
          </section>
        </section>
      </section>
    </main>
  );
}

function createPreviewBridge() {
  let state: ReceiverState = {
    receiverId: "preview",
    receiverName: "Preview CarLink Receiver",
    serverUrl: "ws://192.168.1.42:38555",
    port: 38555,
    serviceName: "_carlink._tcp",
    isAdvertising: true,
    pairing: {
      protocol: "carlink",
      version: 1,
      host: "192.168.1.42",
      port: 38555,
      pin: "482913",
      receiverId: "preview",
      receiverName: "Preview CarLink Receiver",
      expiresAt: new Date(Date.now() + 4 * 60 * 1000).toISOString()
    },
    pairingQrDataUrl: previewQrDataUrl(),
    clients: [
      {
        sessionId: "preview-session",
        deviceId: "iphone-preview",
        name: "iPhone",
        platform: "ios",
        osVersion: "18.0",
        connectedAt: new Date().toISOString(),
        lastSeenAt: new Date().toISOString()
      }
    ],
    media: {
      title: "Night Drive",
      artist: "CarLink Demo",
      source: "iPhone",
      isPlaying: true
    },
    navigation: {
      destination: "Home",
      nextInstruction: "Continue for 800 m",
      provider: "CarLink"
    },
    theme: {
      mode: "dark",
      material: "glass",
      accent: "#14b8a6"
    },
    logs: [
      { id: "1", at: new Date().toISOString(), level: "info", message: "Preview bridge active" },
      { id: "2", at: new Date().toISOString(), level: "info", message: "Media updated: Night Drive" }
    ]
  };

  return {
    getState: async () => state,
    refreshPairing: async () => {
      state = {
        ...state,
        pairing: state.pairing
          ? {
              ...state.pairing,
              pin: String(Math.floor(100000 + Math.random() * 900000)),
              expiresAt: new Date(Date.now() + 5 * 60 * 1000).toISOString()
            }
          : state.pairing
      };
      return state;
    },
    sendCommand: async (command: ControlCommand) => {
      const message = createEnvelope("control.command", { command });
      state = {
        ...state,
        logs: [
          {
            id: message.id,
            at: message.sentAt,
            level: "info",
            message: `Preview command ${command}`
          },
          ...state.logs
        ]
      };
      return state;
    },
    onState: (_callback: (nextState: ReceiverState) => void) => () => undefined
  };
}

function previewQrDataUrl(): string {
  const cells = [
    "1111111001011111111",
    "1000001001010000001",
    "1011101011110111101",
    "1011101000010111101",
    "1011101111010111101",
    "1000001010010000001",
    "1111111010101111111",
    "0000000011100000000",
    "1011011110011010111",
    "0010010011110010100",
    "1110111010101111011",
    "0011000111010100100",
    "1111111010011111111",
    "1000001011110000001",
    "1011101110100111101",
    "1011101000110111101",
    "1011101011010111101",
    "1000001010010000001",
    "1111111011111111111"
  ];
  const size = 19;
  const rects = cells
    .flatMap((row, y) =>
      row.split("").map((cell, x) =>
        cell === "1" ? `<rect x="${x}" y="${y}" width="1" height="1"/>` : ""
      )
    )
    .join("");
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${size} ${size}"><rect width="${size}" height="${size}" fill="white"/><g fill="#0f172a">${rects}</g></svg>`;
  return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`;
}
