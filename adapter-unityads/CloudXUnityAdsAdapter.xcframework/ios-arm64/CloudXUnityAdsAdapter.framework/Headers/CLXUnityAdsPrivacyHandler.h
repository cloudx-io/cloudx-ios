//
//  CLXUnityAdsPrivacyHandler.h
//  CloudXUnityAdsAdapter
//
//  Created by CloudX Team.
//

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXUnityAdsPrivacyHandler
 * @brief Forwards resolved privacy signals to the Unity Ads SDK via UADSMetaData.
 * @discussion Unity Ads is not a registered TCF vendor and does not read IAB
 *             strings from NSUserDefaults. The CloudX core SDK resolves IAB/CMP
 *             signals and manual publisher consent into CLXAdapterPrivacySettings,
 *             then pushes to this handler. This handler forwards the pre-resolved
 *             consent to gdpr.consent and privacy.consent metadata keys.
 */
@interface CLXUnityAdsPrivacyHandler : NSObject <CLXAdapterPrivacyHandler>
@end

NS_ASSUME_NONNULL_END
