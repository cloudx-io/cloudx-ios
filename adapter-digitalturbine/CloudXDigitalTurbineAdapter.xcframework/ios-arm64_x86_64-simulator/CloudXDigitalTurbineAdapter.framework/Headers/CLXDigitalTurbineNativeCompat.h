/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

// CLX_DT_NATIVE_AVAILABLE — compile-time gate for the Digital Turbine native adapter.
//
// Digital Turbine's native API (IANativeAdAssets / IANativeAdDelegate /
// IANativeAdSpot) was introduced in Fyber_Marketplace_SDK 8.4.0. Those two
// native implementation files are the ONLY adapter sources that fail to compile
// against older DT SDKs — banner, MREC, interstitial, rewarded, init, privacy,
// and bid-token all build against 8.3.x and below.
//
// WHY this gate exists instead of a cleaner option:
// We deliberately gate the native code in-source rather than decoupling adapter
// versions from the core SDK ("flexible"/independent adapter versioning). That
// decoupling would force a MAJOR version bump of the CloudX iOS SDK, which we are
// avoiding for now. Gating in-source keeps the adapter in lockstep with core
// versioning AND lets the podspec floor drop below 8.4.0, so a publisher pinned to
// an older DT SDK can still take banner/MREC/interstitial/rewarded.
//
// Discriminator: DTXNativeImageContentController.h ships with the native feature
// and exists only in 8.4.0+. When it is absent, native is compiled out and
// CLXDigitalTurbineNativeFactory returns nil (DT just does not fill native there).
#if __has_include(<IASDKCore/DTXNativeImageContentController.h>)
#define CLX_DT_NATIVE_AVAILABLE 1
#else
#define CLX_DT_NATIVE_AVAILABLE 0
#endif
