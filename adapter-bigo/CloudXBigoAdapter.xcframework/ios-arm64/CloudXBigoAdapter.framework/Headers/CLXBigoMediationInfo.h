//
//  CLXBigoMediationInfo.h
//  CloudXBigoAdapter
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXBigoMediationInfo
 * @brief Builds the mediation descriptor the BIGO Ads SDK accepts on `BigoAdLoader.ext`.
 * @discussion BIGO attributes traffic to a mediation platform from a JSON object carrying
 *             `mediationName`, `mediationVersion` and `adapterVersion`.
 */
@interface CLXBigoMediationInfo : NSObject

/**
 * @brief JSON descriptor naming CloudX as the mediation platform.
 * @param mediationVersion The CloudX SDK version running the auction.
 * @return The JSON string, or nil when serialization fails.
 */
+ (nullable NSString *)extJSONWithMediationVersion:(NSString *)mediationVersion;

@end

NS_ASSUME_NONNULL_END
