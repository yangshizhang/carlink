# Windows Build

Local build:

```powershell
npm install
npm run build
npm run dist:windows
```

Build output is written to `apps/windows/dist`.

The app uses Electron Builder and produces NSIS plus portable artifacts on Windows runners.
