#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterInterstitialFactory.h>
#import "CLXMintegralBaseFactory.h"

NS_ASSUME_NONNULL_BEGIN

@interface CLXMintegralInterstitialFactory : CLXMintegralBaseFactory <CLXAdapterInterstitialFactory>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END

