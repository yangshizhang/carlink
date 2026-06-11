import { contextBridge, ipcRenderer } from "electron";
import type { ControlCommand } from "@carlink/protocol";
import type { CarLinkBridge, ReceiverState } from "../shared";

const api: CarLinkBridge = {
  getState: () => ipcRenderer.invoke("carlink:get-state"),
  refreshPairing: () => ipcRenderer.invoke("carlink:refresh-pairing"),
  sendCommand: (command: ControlCommand) => ipcRenderer.invoke("carlink:send-command", command),
  onState: (callback: (state: ReceiverState) => void) => {
    const listener = (_event: Electron.IpcRendererEvent, state: ReceiverState): void => callback(state);
    ipcRenderer.on("carlink:state", listener);
    return () => ipcRenderer.removeListener("carlink:state", listener);
  }
};

contextBridge.exposeInMainWorld("carlink", api);
