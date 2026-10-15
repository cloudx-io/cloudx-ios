/*
 * CLXMagnitePrivacyHandler+Internal.h
 * CloudXMagniteAdapter
 */

#if __has_include(<CloudXMagniteAdapter/CLXMagnitePrivacyHandler.h>)
#import <CloudXMagniteAdapter/CLXMagnitePrivacyHandler.h>
#else
#import "CLXMagnitePrivacyHandler.h"
#endif

@class CLXAdapterPrivacyParams;

NS_ASSUME_NONNULL_BEGIN

/// The two Magnite SDK calls privacy forwarding makes. MGNISDK conforms.
@protocol CLXMagnitePrivacySDK <NSObject>
- (void)setUserConsent:(BOOL)consent forConsentType:(NSString *)consentType withTimestamp:(long)ts;
- (void)handleExtras:(void (^)(NSMutableDictionary<NSString *, id> *extras))block;
@end

/**
 * Holds privacy params until the Magnite SDK is initialized, then applies them once.
 *
 * MagniteSDK 1.0.4 crashes on a device when consent is set before initialization: its analytics
 * call dispatches onto a queue that does not exist yet (1.0.0 does not). CloudX forwards privacy
 * whenever the publisher sets it, which is often before init, and never re-sends it afterwards.
 * So the params are kept rather than dropped.
 *
 * Main thread only. The privacy handler and the initializer both reach it on the main queue.
 */
@interface CLXMagnitePrivacyGate : NSObject

/// The gate the privacy handler and the initializer share. Backed by MGNISDK and the initializer's state.
+ (instancetype)sharedGate;

- (instancetype)initWithSDKProvider:(id<CLXMagnitePrivacySDK> (^)(void))sdkProvider
                      isInitialized:(BOOL (^)(void))isInitialized NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// Applies @c params now if the SDK is initialized; otherwise keeps them, replacing any held earlier.
- (void)submitParams:(CLXAdapterPrivacyParams *)params;

/// Applies the held params, if any, and clears them. Call once the SDK is initialized.
- (void)sdkDidInitialize;

@end

NS_ASSUME_NONNULL_END
