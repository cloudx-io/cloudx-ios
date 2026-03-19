//
//  CLXUnityAdsBannerFactory.h
//  CloudXUnityAdsAdapter
//

#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

@interface CLXUnityAdsBannerFactory : NSObject <CLXAdapterBannerFactory>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END
