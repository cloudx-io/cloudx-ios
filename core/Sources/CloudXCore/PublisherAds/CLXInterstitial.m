/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXInterstitial.m
 * @brief Interstitial ad implementation
 */

#import <CloudXCore/CLXInterstitial.h>
#import "CLXPublisherFullscreenAdBaseInternal.h"
#import <CloudXCore/CLXAdapterInterstitial.h>
#import <CloudXCore/CLXAdapterInterstitialFactory.h>
#import <CloudXCore/CLXAdNetworkFactories.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXAdType.h>
#import <CloudXCore/CLXAd.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXInterstitial () <CLXAdapterInterstitialDelegate>

@property (nonatomic, strong, nullable) id<CLXAdapterInterstitial> currentAdapter;

@end

@implementation CLXInterstitial

#pragma mark - Abstract Method Implementations

- (NSInteger)adType {
    return CLXAdTypeInterstitial;
}

- (nullable id)createAdapterWithAdId:(NSString *)adId
                              bidId:(NSString *)bidId
                                 adm:(NSString *)adm
                       adapterExtras:(NSDictionary<NSString *, NSString *> *)adapterExtras
                                burl:(nullable NSString *)burl
                             network:(NSString *)network {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"Interstitial"];
    [logger debug:[NSString stringWithFormat:@"🔧 Creating interstitial: AdID=%@, BidID=%@, Network=%@, ADM=%lu chars", adId, bidId, network, (unsigned long)adm.length]];
    
    CLXAdNetworkFactories *factories = [self valueForKey:@"adFactories"];
    if (!factories) {
        [logger error:@"❌ adFactories is nil!"];
        return nil;
    }
    
    id<CLXAdapterInterstitialFactory> factory = factories.interstitials[network];
    if (!factory) {
        [logger error:[NSString stringWithFormat:@"❌ No factory found for network: %@ (Available: %@)", network, [factories.interstitials allKeys]]];
        return nil;
    }
    
    [logger info:[NSString stringWithFormat:@"✅ Interstitial factory found for network: %@ (class: %@)", network, NSStringFromClass([factory class])]];
    
    id<CLXAdapterInterstitial> interstitial = [factory createWithAdId:adId
                                                                 bidId:bidId
                                                                   adm:adm
                                                                extras:adapterExtras
                                                              delegate:self];
    
    if (!interstitial) {
        [logger error:@"❌ Factory returned nil interstitial"];
        return nil;
    }
    
    [logger info:[NSString stringWithFormat:@"✅ Interstitial created - Network: %@, BidID: %@", interstitial.network, interstitial.bidID]];
    
    return interstitial;
}

- (nullable id)getCurrentAdapter {
    return self.currentAdapter;
}

- (void)setupAdapterAndLoad:(id)adapter {
    self.currentAdapter = (id<CLXAdapterInterstitial>)adapter;
    self.currentAdapter.delegate = self;
    
    // Set up 30-second timeout for adapter loading
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.isLoading) {
            CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"Interstitial"];
            [logger error:@"Interstitial load timeout after 30 seconds"];
            [self transitionToIdleState];
            
            NSError *timeoutError = [NSError errorWithDomain:@"CLXErrorDomain" 
                                                        code:CLXErrorCodeLoadTimeout 
                                                    userInfo:@{NSLocalizedDescriptionKey: @"Load timeout"}];
            
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
    if ([self.delegate respondsToSelector:@selector(didLoadWithAd:)]) {
        [self.delegate didLoadWithAd:[self createAdObject]];
    }
}

- (void)notifyLoadFailure:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(failToLoadWithAd:error:)]) {
        [self.delegate failToLoadWithAd:[self createAdObject] error:error];
    }
}

- (void)notifyShowFailure:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(failToShowWithAd:error:)]) {
        [self.delegate failToShowWithAd:[self createAdObject] error:error];
    }
}

- (void)notifyForceClose {
    if ([self.delegate respondsToSelector:@selector(didHideWithAd:)]) {
        [self.delegate didHideWithAd:[self createAdObject]];
    }
}

#pragma mark - CLXAdapterInterstitialDelegate

- (void)didLoadWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"Interstitial"];
    [logger debug:[NSString stringWithFormat:@"🔧 didLoadWithInterstitial - Class: %@", NSStringFromClass([(NSObject *)interstitial class])]];
    
    self.currentAdapter = interstitial;
    [self transitionToReadyState];
    
    [self fireLoadSuccessEventForBidID:interstitial.bidID price:self.lastBidResponse ? self.lastBidResponse.price : 0.0];
    [self fireLosingBidLurls];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyLoadSuccess];
    });
}

- (void)didFailToLoadWithInterstitial:(id<CLXAdapterInterstitial>)interstitial error:(NSError *)error {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"Interstitial"];
    [logger error:[NSString stringWithFormat:@"❌ didFailToLoadWithInterstitial (%@): %@", interstitial, error.localizedDescription]];
    
    [self sendLossNotificationForFailedAd];
    self.currentAdapter = nil;
    [self transitionToIdleState];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyLoadFailure:error];
    });
}

- (void)didShowWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didShowWithAd:)]) {
            [self.delegate didShowWithAd:[self createAdObject]];
        }
    });
}

- (void)impressionWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    [self fireRenderSuccessEventForBidID:interstitial.bidID adType:CLXAdTypeInterstitial];
    
    CLXAd *adObject = [self createAdObject];
    if (self.delegate && [self.delegate respondsToSelector:@selector(revenuePaid:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate revenuePaid:adObject];
        });
    }
    
    if ([self.delegate respondsToSelector:@selector(impressionOn:)]) {
        [self.delegate impressionOn:adObject];
    }
}

- (void)didCloseWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    [self handleAdClose];
    self.currentAdapter = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didHideWithAd:)]) {
            [self.delegate didHideWithAd:[self createAdObject]];
        }
    });
}

- (void)didFailToShowWithInterstitial:(id<CLXAdapterInterstitial>)interstitial error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyShowFailure:error];
    });
}

- (void)clickWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    [self handleClickTracking];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didClickWithAd:)]) {
            [self.delegate didClickWithAd:[self createAdObject]];
        }
    });
}

- (void)expiredWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"Interstitial"];
    [logger debug:@"Interstitial adapter expired"];
    self.currentAdapter = nil;
    [self transitionToIdleState];
}

@end

NS_ASSUME_NONNULL_END

