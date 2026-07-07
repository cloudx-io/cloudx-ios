//
//  CLXMintegralPrivacyHandler.h
//  CloudXMintegralAdapter
//
//  Created by CloudX Team.
//

#import <CloudXCore/CLXAdapterPrivacyHandler.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXMintegralPrivacyHandler
 * @brief Forwards publisher-set privacy flags to the Mintegral SDK.
 * @discussion Active when publishers call setHasUserConsent:/setDoNotSell:
 *             to manage consent directly. Not needed when a CMP is in use —
 *             Mintegral reads CMP consent from NSUserDefaults on its own.
 */
@interface CLXMintegralPrivacyHandler : CLXAdapterPrivacyHandler
@end

NS_ASSUME_NONNULL_END
