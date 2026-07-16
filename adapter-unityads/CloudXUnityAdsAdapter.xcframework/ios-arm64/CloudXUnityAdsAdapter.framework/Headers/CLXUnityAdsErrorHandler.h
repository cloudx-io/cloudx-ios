//
//  CLXUnityAdsErrorHandler.h
//  CloudXUnityAdsAdapter
//

#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CLXError.h>)
#import <CloudXCore/CLXError.h>
#else
#import "CLXError.h"
#endif

#import <UnityAds/UnityAds.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXUnityAdsErrorHandler : NSObject

/// Maps a fullscreen load failure (`UnityAdsLoadError` enum + message) to a `CLXError`.
+ (CLXError *)toCloudXErrorFromLoadError:(UnityAdsLoadError)error message:(NSString *)message;

/// Maps a fullscreen show failure (`UnityAdsShowError` enum + message) to a `CLXError`.
+ (CLXError *)toCloudXErrorFromShowError:(UnityAdsShowError)error message:(NSString *)message;

/// Maps a banner failure (`UADSBannerError`, an NSError subclass) to a `CLXError`.
+ (CLXError *)toCloudXErrorFromBannerError:(nullable UADSBannerError *)error;

@end

NS_ASSUME_NONNULL_END
