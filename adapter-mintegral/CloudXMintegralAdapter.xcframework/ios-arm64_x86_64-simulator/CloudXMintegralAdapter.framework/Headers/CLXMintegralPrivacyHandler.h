//
//  CLXMintegralPrivacyHandler.h
//  CloudXMintegralAdapter
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
 * @class CLXMintegralPrivacyHandler
 * @brief Forwards resolved privacy settings to the Mintegral SDK
 */
@interface CLXMintegralPrivacyHandler : NSObject <CLXAdapterPrivacyHandler>
@end

NS_ASSUME_NONNULL_END
