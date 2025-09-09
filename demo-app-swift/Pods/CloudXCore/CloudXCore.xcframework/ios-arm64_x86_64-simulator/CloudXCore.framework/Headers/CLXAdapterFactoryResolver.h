#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdNetworkInitializer.h>
#import <CloudXCore/CLXAdapterBannerFactory.h>
#import <CloudXCore/CLXAdapterInterstitialFactory.h>
#import <CloudXCore/CLXAdapterRewardedFactory.h>
#import <CloudXCore/CLXAdapterNativeFactory.h>
#import <CloudXCore/CLXBidTokenSource.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BidderConfig;

@protocol CLXAdapterFactoryResolverProtocol <NSObject>
- (NSDictionary *)resolveAdNetworkFactories;
@end

@interface CLXAdapterFactoryResolver : NSObject <CLXAdapterFactoryResolverProtocol>

- (NSDictionary *)resolveAdNetworkFactories;

@end

NS_ASSUME_NONNULL_END 