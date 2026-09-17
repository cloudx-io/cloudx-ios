#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterInitializer.h>

NS_ASSUME_NONNULL_BEGIN

/// Returns YES once the BIGO Ads SDK has reported a successful initialization via
/// `-initializeWithParams:`. The bidder-signals provider gates on this so an auction
/// before init yields no token instead of a partner-side error, and ad loads fail fast
/// with a clear error instead of being rejected deep inside the partner SDK.
BOOL CLXBigoInitializerIsInitialized(void);

/**
 * @class CLXBigoInitializer
 * @brief Initializes the BIGO Ads SDK with the App ID delivered in `/sdk/init` `initData.appID`.
 * @discussion Idempotent: a second call after success completes immediately, and calls that
 *             arrive while the partner SDK is still initializing complete together with it.
 */
@interface CLXBigoInitializer : CLXAdapterInitializer

/** @brief BIGO Ads SDK version string reported by the partner SDK. */
@property (nonatomic, copy, readonly) NSString *sdkVersion;

/** @brief CloudX network name this adapter serves; always `bigo`. */
@property (nonatomic, copy, readonly) NSString *network;

/**
 * @brief BIGO Ads SDK version string reported by the partner SDK.
 * @return The version name, e.g. "5.3.0".
 */
+ (NSString *)sdkVersion;

@end

NS_ASSUME_NONNULL_END
