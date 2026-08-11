/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterNativeFactory.h
 * @brief Abstract base class for native adapter factories
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXExport.h>
#import <CloudXCore/CLXAdapterNativeParams.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXAdapterNative;

/**
 * Key in `localExtraParameters` whose value is an NSValue wrapping CGSize.
 * When present, indicates the target container size for native-in-banner rendering
 * (e.g., 320x50 compact banner or 300x250 MREC).
 *
 * Populated by CLXNativeAdViewBridge before invoking a native factory on the
 * banner/MREC path. Adapters that need size at init time (e.g., Mintegral) must
 * read this value. Adapters that do not may ignore it.
 */
CLX_PUBLIC_ADAPTER FOUNDATION_EXPORT NSString * const CLXNativeContainerTargetSizeKey;

/**
 * Key in `localExtraParameters` whose value is an NSNumber BOOL.
 * YES means the native adapter is being used to back a banner/MREC ad-view
 * container rather than the standalone publisher-native surface.
 */
CLX_PUBLIC_ADAPTER FOUNDATION_EXPORT NSString * const CLXIsNativeAdViewKey;

/**
 * Key in `localExtraParameters` whose value is an opaque parsed OpenRTB
 * Native 1.2 adm object. Set by CLXNativeAdViewBridge when the banner path has
 * already parsed the adm at creation time (the creation-time parse guard) so
 * the embedded CloudX native renderer factory can reuse it via
 * `initWithParsedAd:` instead of re-parsing. Only the in-core
 * CLXCoreRendererNativeFactory consumes this key; third-party factories
 * ignore it. Absent on the third-party native-in-banner path (no creation-time
 * parse runs there).
 */
CLX_PUBLIC_ADAPTER FOUNDATION_EXPORT NSString * const CLXNativeParsedAdKey;

/// Abstract base class for native adapter factories.
/// Subclass MUST override @c -createWithParams:.
/// The wrapper attaches itself as the adapter's delegate after construction.
CLX_PUBLIC_ADAPTER
@interface CLXAdapterNativeFactory : NSObject

+ (instancetype)createInstance;

- (nullable CLXAdapterNative *)createWithParams:(CLXAdapterNativeParams *)params;

@end

NS_ASSUME_NONNULL_END
