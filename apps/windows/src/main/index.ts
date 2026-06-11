import { app, BrowserWindow, ipcMain } from "electron";
import { join } from "node:path";
import type { ControlCommand } from "@carlink/protocol";
import { CarLinkServer } from "./server";

let mainWindow: BrowserWindow | null = null;
let server: CarLinkServer | null = null;

function createWindow(): void {
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 760,
    minWidth: 1060,
    minHeight: 680,
    title: "CarLink Receiver",
    backgroundColor: "#0b0f14",
    autoHideMenuBar: true,
    webPreferences: {
      preload: join(__dirname, "../preload/index.js"),
      contextIsolation: true,
      nodeIntegration: false
    }
  });

  if (process.env.ELECTRON_RENDERER_URL) {
    mainWindow.loadURL(process.env.ELECTRON_RENDERER_URL);
  } else {
    mainWindow.loadFile(join(__dirname, "../renderer/index.html"));
  }
}

app.whenReady().then(async () => {
  server = new CarLinkServer({
    onStateChange: (state) => mainWindow?.webContents.send("carlink:state", state)
  });

  ipcMain.handle("carlink:get-state", () => server?.getState());
  ipcMain.handle("carlink:refresh-pairing", () => server?.refreshPairing());
  ipcMain.handle("carlink:send-command", (_event, command: ControlCommand) => server?.sendCommand(command));

  createWindow();
  await server.start();

  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    app.quit();
  }
});

app.on("before-quit", async () => {
  await server?.stop();
});
