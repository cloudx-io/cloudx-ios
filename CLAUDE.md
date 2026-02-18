# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

CloudX iOS SDK — a private monorepo containing the core ad SDK and network adapters. Code is written in **Objective-C**. The SDK is distributed publicly as binary xcframeworks via CocoaPods and SPM; source code never goes to the public repo.

## Build & Test Commands

### Run unit tests (core SDK)
```bash
cd core && xcodebuild test \
  -project CloudXCore.xcodeproj \
  -scheme CloudXCore \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet \
  CODE_SIGNING_ALLOWED=NO
```

### Run a single test class
```bash
cd core && xcodebuild test \
  -project CloudXCore.xcodeproj \
  -scheme CloudXCore \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:CloudXCoreTests/CLXBidResponseTests \
  CODE_SIGNING_ALLOWED=NO
```

### Build xcframeworks
```bash
cd core && ./build-xcframework.sh <version>      # Core (dynamic, includes dSYMs)
cd adapter-meta && ./build-xcframework.sh         # Adapters (static)
cd adapter-vungle && ./build-xcframework.sh
cd adapter-inmobi && ./build-xcframework.sh
```

### Update version constants
```bash
./scripts/update-version-constant.sh <component> <version>
# Components: core, meta, renderer, vungle, inmobi, mintegral, moloco
```

### Demo apps (CocoaPods)
```bash
cd demo-app-swift && pod install && open *.xcworkspace
cd demo-app-objc && pod install && open *.xcworkspace
```

## Architecture

### Component Layout
- **`core/`** — CloudXCore SDK. The main framework containing all ad logic, bidding, tracking, and public API. Built as a **dynamic** framework.
- **`adapter-{meta,vungle,inmobi,mintegral,moloco}/`** — Network adapters. Built as **static** frameworks. Each has its own podspec, Package.swift, and build script.
- **`renderer-cloudx/`** — Creative rendering engine (static framework).
- **`demo-app-swift/`, `demo-app-objc/`** — Demo apps using local `:path =>` pod references for development.
- **`unity-binaries/`** — Unity integration binaries.

### Core SDK Structure (`core/Sources/CloudXCore/`)
- **Entry point:** `CloudXCoreAPI.h/.m` — `CloudXCore` singleton (`CloudXCore.shared`), SDK initialization
- **`PublisherAds/`** — Public ad types: `CLXBannerAdView`, `CLXInterstitial`, `CLXRewarded`, `CLXNativeAdView`
- **`Adapter/`** — Adapter protocol interfaces (`CLXAdapterBanner`, `CLXAdapterInterstitial`, etc.) and factory protocols
- **`AdSource/`** — Bidding logic, bid request/response, `CLXBidNetworkService`
- **`Services/`** — Network services, privacy (`CLXPrivacyService`), geolocation, consent
- **`AdReporting/`** — Event tracking, metrics (`CLXMetricsTrackerImpl`), impression tracking
- **`WinLoss/`** — Win/loss notification tracking with SQLite persistence
- **`Database/`** — `CLXSQLiteDatabase` for local persistence
- **`DIContainer/`** — `CLXDIContainer` dependency injection
- **`Debug/`** — `CLXDebugButton`, `CLXDebugOverlayManager`, `CLXLogger`, `CLXLogStore`
- **`Model/`** — Data models for SDK config, bid responses, etc.

### Key Patterns
- All public classes use the `CLX` prefix
- Delegate pattern for ad lifecycle callbacks (`CLXBannerDelegate`, `CLXInterstitialDelegate`, etc.)
- Factory pattern for adapter creation (`CLXAdapterBannerFactory`, etc.)
- Version constants live in `CLX*Version.m` files (updated by `scripts/update-version-constant.sh`)

### Tests
Tests are in `core/CloudXCoreTests/` (71 test files). XCTest-based, Objective-C. Test files follow the `CLX*Tests.m` naming convention.

## Distribution

- **CocoaPods** — Primary. Each component has a `.podspec`. Public repo receives binary xcframeworks only.
- **SPM** — Root `Package.swift`. CloudXCore is source-based; adapters are binary targets.
- **Deployment target:** iOS 13.0+
- CloudXCore is **dynamic** (for dSYM crash symbolication); all adapters are **static**
- dSYMs are strictly internal — never published to the public repo

## Branching & Release

- **Trunk-based** workflow: `main` is the default branch and the main PR target
- Release tags follow `vX.Y.Z-{component}` format (e.g., `v2.1.0-core`, `v1.1.25-meta`)
- See `RELEASE.md` for the full multi-phase release process
- CI runs on pushes to `main`/`release/**`/`hotfix/**` and all PRs

## Claude Agent Maintenance

The `.claude/` directory contains agent documentation that must stay synchronized with SDK API changes. When public API classes, methods, or delegate protocols change, run `.claude/` maintenance workflows per `.claude/maintenance/UPDATE_WORKFLOW.md`.
