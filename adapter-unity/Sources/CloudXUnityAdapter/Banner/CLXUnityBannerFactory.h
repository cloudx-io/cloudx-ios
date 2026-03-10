//
//  CLXUnityBannerFactory.h
//  CloudXUnityAdapter
//

#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

@interface CLXUnityBannerFactory : NSObject <CLXAdapterBannerFactory>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END
