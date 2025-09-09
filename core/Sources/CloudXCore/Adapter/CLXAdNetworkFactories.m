/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXAdNetworkFactories.h>
#import <CloudXCore/CLXAdNetworkInitializer.h>
#import <CloudXCore/CLXAdapterBannerFactory.h>
#import <CloudXCore/CLXAdapterInterstitialFactory.h>
#import <CloudXCore/CLXAdapterRewardedFactory.h>
#import <CloudXCore/CLXAdapterNativeFactory.h>

@interface CLXAdNetworkFactories ()
@property (nonatomic, strong) NSDictionary<NSString *, id<CLXBidTokenSource>> *bidTokenSources;
@property (nonatomic, strong) NSDictionary<NSString *, id<CLXAdNetworkInitializer>> *initializers;
@property (nonatomic, strong) NSDictionary<NSString *, id<CLXAdapterInterstitialFactory>> *interstitials;
@property (nonatomic, strong) NSDictionary<NSString *, id<CLXAdapterRewardedFactory>> *rewardedInterstitials;
@property (nonatomic, strong) NSDictionary<NSString *, id<CLXAdapterBannerFactory>> *banners;
@property (nonatomic, strong) NSDictionary<NSString *, id<CLXAdapterNativeFactory>> *native;
@end

@implementation CLXAdNetworkFactories

- (instancetype)initWithBidTokenSources:(NSDictionary<NSString *, id<CLXBidTokenSource>> *)bidTokenSources
                           initializers:(NSDictionary<NSString *, id<CLXAdNetworkInitializer>> *)initializers
                          interstitials:(NSDictionary<NSString *, id<CLXAdapterInterstitialFactory>> *)interstitials
                   rewardedInterstitials:(NSDictionary<NSString *, id<CLXAdapterRewardedFactory>> *)rewardedInterstitials
                                 banners:(NSDictionary<NSString *, id<CLXAdapterBannerFactory>> *)banners
                                   native:(NSDictionary<NSString *, id<CLXAdapterNativeFactory>> *)native {
    self = [super init];
    if (self) {
        _bidTokenSources = bidTokenSources ?: @{};
        _initializers = initializers ?: @{};
        _interstitials = interstitials ?: @{};
        _rewardedInterstitials = rewardedInterstitials ?: @{};
        _banners = banners ?: @{};
        _native = native ?: @{};
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    return [self initWithBidTokenSources:dictionary[@"bidTokenSources"]
                            initializers:dictionary[@"initializers"]
                           interstitials:dictionary[@"interstitials"]
                rewardedInterstitials:dictionary[@"rewardedInterstitials"]
                                  banners:dictionary[@"banners"]
                                    native:dictionary[@"native"]];
}

- (BOOL)isEmpty {
    return self.bidTokenSources.count == 0 &&
           self.initializers.count == 0 &&
           self.interstitials.count == 0 &&
           self.rewardedInterstitials.count == 0 &&
           self.banners.count == 0 &&
           self.native.count == 0;
}

@end 