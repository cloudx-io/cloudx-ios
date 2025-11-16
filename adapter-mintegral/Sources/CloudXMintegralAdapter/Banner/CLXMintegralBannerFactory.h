#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterBannerFactory.h>
#import "CLXMintegralBaseFactory.h"

NS_ASSUME_NONNULL_BEGIN

@interface CLXMintegralBannerFactory : CLXMintegralBaseFactory <CLXAdapterBannerFactory>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END

