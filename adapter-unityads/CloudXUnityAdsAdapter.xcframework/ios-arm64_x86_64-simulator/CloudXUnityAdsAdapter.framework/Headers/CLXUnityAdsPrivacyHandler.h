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
 * @brief Forwards privacy settings to the Unity Ads SDK.
 * @discussion Unity Ads does not read CMP consent from NSUserDefaults on its
 *             own, so this handler forwards the full resolved signal whether
 *             the publisher uses a CMP or manual methods.
 */
@interface CLXUnityAdsPrivacyHandler : NSObject <CLXAdapterPrivacyHandler>
@end

NS_ASSUME_NONNULL_END
