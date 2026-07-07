//
//  CLXMobileFusePrivacyHandler.h
//  CloudXMobileFuseAdapter
//

#import <CloudXCore/CLXAdapterPrivacyHandler.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Forwards publisher-set privacy state (GDPR + CCPA) to the MobileFuse SDK.
 *
 * MobileFuse's iOS SDK exposes a single `MobileFusePrivacyPreferences`
 * snapshot that the SDK reads at signal-collection / load time. Only fields
 * the publisher has explicitly set are forwarded — nil values are skipped to
 * avoid overwriting CMP state that the SDK may have already resolved from
 * its own IAB string reads.
 */
@interface CLXMobileFusePrivacyHandler : CLXAdapterPrivacyHandler
@end

NS_ASSUME_NONNULL_END
