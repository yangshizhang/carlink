/// <reference types="vite/client" />

import type { CarLinkBridge } from "../../shared";

declare global {
  interface Window {
    carlink?: CarLinkBridge;
  }
}
