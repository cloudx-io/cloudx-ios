//
//  CLXInMobiPrivacyHandler.h
//  CloudXInMobiAdapter
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
 * @class CLXInMobiPrivacyHandler
 * @brief Forwards resolved privacy settings to the InMobi SDK
 */
@interface CLXInMobiPrivacyHandler : NSObject <CLXAdapterPrivacyHandler>
@end

NS_ASSUME_NONNULL_END
