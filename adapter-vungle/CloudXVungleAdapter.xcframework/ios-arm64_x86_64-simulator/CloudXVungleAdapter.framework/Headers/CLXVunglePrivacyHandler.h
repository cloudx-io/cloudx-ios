//
//  CLXVunglePrivacyHandler.h
//  CloudXVungleAdapter
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
 * @class CLXVunglePrivacyHandler
 * @brief Forwards publisher-set privacy flags to the Vungle (Liftoff) SDK.
 * @discussion Active when publishers call setHasUserConsent:/setDoNotSell:
 *             to manage consent directly. Not needed when a CMP is in use —
 *             Vungle reads CMP consent from NSUserDefaults on its own.
 */
@interface CLXVunglePrivacyHandler : NSObject <CLXAdapterPrivacyHandler>
@end

NS_ASSUME_NONNULL_END
