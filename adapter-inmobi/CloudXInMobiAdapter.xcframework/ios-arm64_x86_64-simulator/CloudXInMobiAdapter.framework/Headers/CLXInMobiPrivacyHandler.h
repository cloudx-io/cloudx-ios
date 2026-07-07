//
//  CLXInMobiPrivacyHandler.h
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#import <CloudXCore/CLXAdapterPrivacyHandler.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXInMobiPrivacyHandler
 * @brief Forwards publisher-set privacy flags to the InMobi SDK.
 * @discussion Active when publishers call setHasUserConsent:/setDoNotSell:
 *             to manage consent directly. Not needed when a CMP is in use —
 *             InMobi reads CMP consent from NSUserDefaults on its own.
 */
@interface CLXInMobiPrivacyHandler : CLXAdapterPrivacyHandler
@end

NS_ASSUME_NONNULL_END
