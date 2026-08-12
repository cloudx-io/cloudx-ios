//
//  CLXMolocoPrivacyHandler.h
//  CloudXMolocoAdapter
//

#import <CloudXCore/CLXAdapterPrivacyHandler.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXMolocoPrivacyHandler
 * @brief Forwards publisher-set privacy flags to the Moloco SDK.
 * @discussion Active when publishers call setHasUserConsent:/setDoNotSell:
 *             to manage consent directly. Not needed when a CMP is in use —
 *             Moloco reads CMP consent from NSUserDefaults on its own.
 */
@interface CLXMolocoPrivacyHandler : CLXAdapterPrivacyHandler
@end

NS_ASSUME_NONNULL_END
