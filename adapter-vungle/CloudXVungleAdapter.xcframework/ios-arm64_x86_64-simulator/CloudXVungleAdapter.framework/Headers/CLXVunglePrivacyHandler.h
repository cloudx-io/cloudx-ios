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
 * @brief Forwards resolved privacy settings to the Vungle (Liftoff) SDK
 */
@interface CLXVunglePrivacyHandler : NSObject <CLXAdapterPrivacyHandler>
@end

NS_ASSUME_NONNULL_END
