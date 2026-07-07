//
//  CLXVunglePrivacyHandler.h
//  CloudXVungleAdapter
//
//  Created by CloudX Team.
//

#import <CloudXCore/CLXAdapterPrivacyHandler.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXVunglePrivacyHandler
 * @brief Forwards publisher-set privacy flags to the Vungle (Liftoff) SDK.
 * @discussion Active when publishers call setHasUserConsent:/setDoNotSell:
 *             to manage consent directly. Not needed when a CMP is in use —
 *             Vungle reads CMP consent from NSUserDefaults on its own.
 */
@interface CLXVunglePrivacyHandler : CLXAdapterPrivacyHandler
@end

NS_ASSUME_NONNULL_END
