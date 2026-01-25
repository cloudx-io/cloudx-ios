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
#import <CloudXCore/CLXDebugOverlayManager.h>

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
    [self.logger debug:[NSString stringWithFormat:@"Creating interstitial: AdID=%@, BidID=%@, Network=%@, ADM=%lu chars", adId, bidId, network, (unsigned long)adm.length]];
    
    CLXAdNetworkFactories *factories = [self valueForKey:@"adFactories"];
    if (!factories) {
        [self.logger error:@"❌ adFactories is nil!"];
        return nil;
    }
    
    id<CLXAdapterInterstitialFactory> factory = factories.interstitials[network];
    if (!factory) {
        [self.logger error:[NSString stringWithFormat:@"❌ No factory found for network: %@ (Available: %@)", network, [factories.interstitials allKeys]]];
        return nil;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Interstitial factory found for network: %@ (class: %@)", network, NSStringFromClass([factory class])]];
    
    id<CLXAdapterInterstitial> interstitial = [factory createWithAdId:adId
                                                                 bidId:bidId
                                                                   adm:adm
                                                                extras:adapterExtras
                                                         placementName:self.placementName
                                                              delegate:self];
    
    if (!interstitial) {
        [self.logger error:@"❌ Factory returned nil interstitial"];
        return nil;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Interstitial created - Network: %@, BidID: %@", interstitial.network, interstitial.bidID]];
    
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
            [self.logger error:@"Interstitial load timeout after 30 seconds"];
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
        CLXAd *ad = [self createAdObject];
        [self.logger logDelegateCallback:@"✅ Interstitial didLoadAd" ad:ad];
        [self.delegate didLoadAd:ad];
    }
}

- (void)notifyLoadFailure:(CLXError *)error {
    [[CLXDebugOverlayManager shared] flashError];
    if ([self.delegate respondsToSelector:@selector(didFailToLoadAd:error:)]) {
        [self.logger logDelegateError:@"❌ Interstitial didFailToLoadAd" error:error];
        [self.delegate didFailToLoadAd:self.placementName error:error];
    }
}

- (void)notifyShowFailure:(CLXError *)error {
    [[CLXDebugOverlayManager shared] flashError];
    if ([self.delegate respondsToSelector:@selector(didFailToDisplayAd:error:)]) {
        [self.logger logDelegateError:@"❌ Interstitial didFailToDisplayAd" error:error];
        [self.delegate didFailToDisplayAd:[self createAdObject] error:error];
    }
}

- (void)notifyForceClose {
    if ([self.delegate respondsToSelector:@selector(didHideAd:)]) {
        CLXAd *ad = [self createAdObject];
        [self.logger logDelegateCallback:@"🔚 Interstitial didHideAd" ad:ad];
        [self.delegate didHideAd:ad];
    }
}

#pragma mark - CLXAdapterInterstitialDelegate

- (void)didLoadWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    [self.logger debug:[NSString stringWithFormat:@"didLoadWithInterstitial - Class: %@", NSStringFromClass([(NSObject *)interstitial class])]];
    
    // Track adapter load latency (success)
    [self trackAdapterLoadLatencyWithError:nil];
    
    self.currentAdapter = interstitial;
    [self transitionToReadyState];
    
    [self fireLoadSuccessEventForBidID:interstitial.bidID price:self.lastBidResponse ? self.lastBidResponse.price : 0.0];
    [self fireLosingBidLurls];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyLoadSuccess];
    });
}

- (void)didFailToLoadWithInterstitial:(id<CLXAdapterInterstitial>)interstitial error:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"❌ didFailToLoadWithInterstitial (%@): %@", interstitial, error.localizedDescription]];
    
    // Track adapter load latency (failure)
    [self trackAdapterLoadLatencyWithError:error];
    
    [self sendLossNotificationForFailedAdWithError:error];
    self.currentAdapter = nil;
    [self transitionToIdleState];
    
    CLXError *clxError = [CLXError errorFromError:error withFallbackCode:CLXErrorCodeLoadFailed];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyLoadFailure:clxError];
    });
}

- (void)didShowWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didDisplayAd:)]) {
            CLXAd *ad = [self createAdObject];
            [self.logger logDelegateCallback:@"👀 Interstitial didDisplayAd" ad:ad];
            [self.delegate didDisplayAd:ad];
        }
    });
}

- (void)impressionWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    [self fireRenderSuccessEventForBidID:interstitial.bidID adType:CLXAdTypeInterstitial];
    
    CLXAd *adObject = [self createAdObject];
    if (self.revenueDelegate && [self.revenueDelegate respondsToSelector:@selector(didPayRevenueForAd:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.revenueDelegate didPayRevenueForAd:adObject];
        });
    }
}

- (void)didCloseWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    [self handleAdClose];
    self.currentAdapter = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didHideAd:)]) {
            CLXAd *ad = [self createAdObject];
            [self.logger logDelegateCallback:@"🔚 Interstitial didHideAd" ad:ad];
            [self.delegate didHideAd:ad];
        }
    });
}

- (void)didFailToShowWithInterstitial:(id<CLXAdapterInterstitial>)interstitial error:(NSError *)error {
    // Clear state BEFORE callback (enables immediate reload)
    [self handleShowFailure];
    self.currentAdapter = nil;
    
    CLXError *clxError = [CLXError errorFromError:error withFallbackCode:CLXErrorCodeShowFailed];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyShowFailure:clxError];
    });
}

- (void)clickWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    [self handleClickTracking];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didClickAd:)]) {
            CLXAd *ad = [self createAdObject];
            [self.logger logDelegateCallback:@"👆 Interstitial didClickAd" ad:ad];
            [self.delegate didClickAd:ad];
        }
    });
}

- (void)expiredWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    [self.logger debug:@"Interstitial adapter expired"];
    self.currentAdapter = nil;
    [self transitionToIdleState];
}

@end

NS_ASSUME_NONNULL_END

