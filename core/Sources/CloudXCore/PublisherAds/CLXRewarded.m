/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXRewarded.m
 * @brief Rewarded ad implementation
 */

#import <CloudXCore/CLXRewarded.h>
#import "CLXPublisherFullscreenAdBaseInternal.h"
#import <CloudXCore/CLXAdapterRewarded.h>
#import <CloudXCore/CLXAdapterRewardedFactory.h>
#import <CloudXCore/CLXAdNetworkFactories.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXAdType.h>
#import <CloudXCore/CLXAd.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXRewarded () <CLXAdapterRewardedDelegate>

@property (nonatomic, strong, nullable) id<CLXAdapterRewarded> currentAdapter;

@end

@implementation CLXRewarded

#pragma mark - Abstract Method Implementations

- (NSInteger)adType {
    return CLXAdTypeRewarded;
}

- (nullable id)createAdapterWithAdId:(NSString *)adId
                              bidId:(NSString *)bidId
                                 adm:(NSString *)adm
                       adapterExtras:(NSDictionary<NSString *, NSString *> *)adapterExtras
                                burl:(nullable NSString *)burl
                             network:(NSString *)network {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"Rewarded"];
    [logger debug:[NSString stringWithFormat:@"Creating rewarded: AdID=%@, BidID=%@, Network=%@", adId, bidId, network]];
    
    CLXAdNetworkFactories *factories = [self valueForKey:@"adFactories"];
    if (!factories) {
        [logger error:@"❌ adFactories is nil!"];
        return nil;
    }
    
    [logger debug:[NSString stringWithFormat:@"adFactories.rewardedInterstitials: %@", factories.rewardedInterstitials]];
    
    id<CLXAdapterRewardedFactory> factory = factories.rewardedInterstitials[network];
    if (!factory) {
        [logger error:[NSString stringWithFormat:@"❌ No rewarded factory found for network: %@ (Available: %@)", network, [factories.rewardedInterstitials allKeys]]];
        return nil;
    }
    
    [logger info:[NSString stringWithFormat:@"Rewarded factory found for network: %@ (class: %@)", network, NSStringFromClass([factory class])]];
    
    id<CLXAdapterRewarded> rewarded = [factory createWithAdId:adId
                                                         bidId:bidId
                                                            adm:adm
                                                        extras:adapterExtras
                                                      delegate:self];
    
    if (!rewarded) {
        [logger error:@"❌ Factory returned nil rewarded"];
        return nil;
    }
    
    [logger info:[NSString stringWithFormat:@"Rewarded created - Network: %@, BidID: %@", rewarded.network, rewarded.bidID]];
    
    return rewarded;
}

- (nullable id)getCurrentAdapter {
    return self.currentAdapter;
}

- (void)setupAdapterAndLoad:(id)adapter {
    self.currentAdapter = (id<CLXAdapterRewarded>)adapter;
    self.currentAdapter.delegate = self;
    
    // Set up 30-second timeout for adapter loading
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.isLoading) {
            CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"Rewarded"];
            [logger error:@"Rewarded load timeout after 30 seconds"];
            [self transitionToIdleState];
            
            CLXError *timeoutError = [CLXError errorWithCode:CLXErrorCodeLoadTimeout];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self notifyLoadFailure:timeoutError];
            });
        }
    });
    
    [self.currentAdapter load];
}

- (void)showCurrentAdapterFromViewController:(UIViewController *)viewController {
    [self.currentAdapter showFromViewController:viewController];
}

- (void)notifyLoadSuccess {
    if ([self.delegate respondsToSelector:@selector(didLoadAd:)]) {
        [self.delegate didLoadAd:[self createAdObject]];
    }
}

- (void)notifyLoadFailure:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(didFailToLoadAdWithError:)]) {
        [self.delegate didFailToLoadAdWithError:error];
    }
}

- (void)notifyShowFailure:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(didFailToDisplayAd:error:)]) {
        [self.delegate didFailToDisplayAd:[self createAdObject] error:error];
    }
}

- (void)notifyForceClose {
    if ([self.delegate respondsToSelector:@selector(didHideAd:)]) {
        [self.delegate didHideAd:[self createAdObject]];
    }
}

#pragma mark - CLXAdapterRewardedDelegate

- (void)didLoadWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"Rewarded"];
    [logger debug:@"Rewarded adapter loaded successfully"];
    
    self.currentAdapter = rewarded;
    [self transitionToReadyState];
    
    [self fireLoadSuccessEventForBidID:rewarded.bidID price:self.lastBidResponse ? self.lastBidResponse.price : 0.0];
    [self fireLosingBidLurls];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyLoadSuccess];
    });
}

- (void)didFailToLoadWithRewarded:(id<CLXAdapterRewarded>)rewarded error:(NSError *)error {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"Rewarded"];
    [logger error:[NSString stringWithFormat:@"❌ didFailToLoadWithRewarded (%@): %@", rewarded, error.localizedDescription]];
    
    [self sendLossNotificationForFailedAd];
    self.currentAdapter = nil;
    [self transitionToIdleState];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyLoadFailure:error];
    });
}

- (void)didShowWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didDisplayAd:)]) {
            [self.delegate didDisplayAd:[self createAdObject]];
        }
    });
}

- (void)impressionWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    [self fireRenderSuccessEventForBidID:rewarded.bidID adType:CLXAdTypeRewarded];
    
    CLXAd *adObject = [self createAdObject];
    if (self.delegate && [self.delegate respondsToSelector:@selector(didPayRevenueForAd:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate didPayRevenueForAd:adObject];
        });
    }
    
    if ([self.delegate respondsToSelector:@selector(didRecordImpressionForAd:)]) {
        [self.delegate didRecordImpressionForAd:adObject];
    }
}

- (void)didCloseWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    [self handleAdClose];
    self.currentAdapter = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didHideAd:)]) {
            [self.delegate didHideAd:[self createAdObject]];
        }
    });
}

- (void)clickWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    [self handleClickTracking];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didClickAd:)]) {
            [self.delegate didClickAd:[self createAdObject]];
        }
    });
}

- (void)userRewardWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"Rewarded"];
    [logger debug:@"User rewarded"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(userRewarded:)]) {
            [self.delegate userRewarded:self];
        }
    });
}

- (void)didFailToShowWithRewarded:(id<CLXAdapterRewarded>)rewarded error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyShowFailure:error];
    });
}

- (void)expiredWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"Rewarded"];
    [logger debug:@"Rewarded adapter expired"];
    self.currentAdapter = nil;
    [self transitionToIdleState];
}

@end

NS_ASSUME_NONNULL_END

