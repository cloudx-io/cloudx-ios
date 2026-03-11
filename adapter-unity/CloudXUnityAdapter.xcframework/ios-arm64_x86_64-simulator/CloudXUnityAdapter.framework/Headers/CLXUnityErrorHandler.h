//
//  CLXUnityErrorHandler.h
//  CloudXUnityAdapter
//

#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CLXError.h>)
#import <CloudXCore/CLXError.h>
#else
#import "CLXError.h"
#endif

#import <UnityAds/UnityAds.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXUnityErrorHandler : NSObject

/// Maps a beta-API `UnityAdsError` (protocol with `.code` + `.message`) to a `CLXError`.
+ (CLXError *)toCloudXError:(id<UnityAdsError>)error;

@end

NS_ASSUME_NONNULL_END
