# iOS Build

The iOS app is generated with XcodeGen.

Local setup on macOS:

```bash
brew install xcodegen
cd apps/ios
xcodegen generate
open CarLink.xcodeproj
```

## GitHub Actions Unsigned IPA

`.github/workflows/ios.yml` uses a GitHub-hosted macOS runner:

1. Selects `/Applications/Xcode.app`.
2. Installs XcodeGen.
3. Generates `CarLink.xcodeproj`.
4. Builds a Release `iphoneos` app with code signing disabled.
5. Packages `DerivedData/Build/Products/Release-iphoneos/CarLink.app` into `export/CarLink-unsigned.ipa`.
6. Uploads `CarLink-unsigned-ipa` as an Actions artifact.

The generated IPA is intentionally unsigned. It is useful for CI artifacts, inspection, and later external signing, but it will not install on a normal iPhone without a valid signature and provisioning profile.
