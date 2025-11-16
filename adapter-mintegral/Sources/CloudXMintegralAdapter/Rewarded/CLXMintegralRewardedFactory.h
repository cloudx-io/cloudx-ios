#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterRewardedFactory.h>
#import "CLXMintegralBaseFactory.h"

NS_ASSUME_NONNULL_BEGIN

@interface CLXMintegralRewardedFactory : CLXMintegralBaseFactory <CLXAdapterRewardedFactory>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END

