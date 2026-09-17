//
//  CLXBigoPrivacyHandler.h
//  CloudXBigoAdapter
//

#import <CloudXCore/CLXAdapterPrivacyHandler.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXBigoPrivacyHandler
 * @brief Forwards CloudX privacy state to the BIGO Ads SDK consent API.
 * @discussion GDPR and LGPD receive the publisher-set consent flag; CCPA receives the
 *             resolved do-not-sell state (GPP, then US Privacy String, then the manual flag).
 */
@interface CLXBigoPrivacyHandler : CLXAdapterPrivacyHandler
@end

NS_ASSUME_NONNULL_END
