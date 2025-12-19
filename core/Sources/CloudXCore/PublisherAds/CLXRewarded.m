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
#import <CloudXCore/CLXDebugOverlayManager.h>
#import <CloudXCore/CLXReward.h>
#import <CloudXCore/CLXBidLifecycleEvent.h>
#import <CloudXCore/CLXSDKConfigPlacement.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXBidTokenSource.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXRewarded () <CLXAdapterRewardedDelegate>

@property (nonatomic, strong, nullable) id<CLXAdapterRewarded> currentAdapter;

// Reward configuration from placement
@property (nonatomic, assign) NSInteger placementRewardAmount;
@property (nonatomic, copy, nullable) NSString *placementRewardCurrency;

@end

@implementation CLXRewarded

#pragma mark - Initialization

- (instancetype)initWithPlacement:(nullable CLXSDKConfigPlacement *)placement
                      publisherID:(NSString *)publisherID
                           userID:(nullable NSString *)userID
              rewardedCallbackUrl:(nullable NSString *)rewardedCallbackUrl
                         impModel:(nullable CLXConfigImpressionModel *)impModel
                      adFactories:(nullable CLXAdNetworkFactories *)adFactories
         waterfallMaxBackOffTime:(nullable NSNumber *)waterfallMaxBackOffTime
                  bidTokenSources:(NSDictionary<NSString *, id<CLXBidTokenSource>> *)bidTokenSources
               bidRequestTimeout:(NSTimeInterval)bidRequestTimeout
                reportingService:(id<CLXAdEventReporting>)reportingService
                        settings:(CLXSettings *)settings {
    self = [super initWithPlacement:placement
                        publisherID:publisherID
                             userID:userID
                rewardedCallbackUrl:rewardedCallbackUrl
                           impModel:impModel
                        adFactories:adFactories
           waterfallMaxBackOffTime:waterfallMaxBackOffTime
                    bidTokenSources:bidTokenSources
                 bidRequestTimeout:bidRequestTimeout
                  reportingService:reportingService
                          settings:settings];
    
    if (self) {
        // Capture reward configuration from placement
        if (placement) {
            _placementRewardAmount = placement.rewardAmount;
            _placementRewardCurrency = [placement.rewardCurrency copy];
            
            CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXRewarded"];
            [logger debug:[NSString stringWithFormat:@"Reward config from placement: amount=%ld, currency=%@", 
                          (long)_placementRewardAmount, _placementRewardCurrency ?: @"(nil)"]];
        }
    }
    return self;
}

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
    [self.logger debug:[NSString stringWithFormat:@"Creating rewarded: AdID=%@, BidID=%@, Network=%@", adId, bidId, network]];
    
    CLXAdNetworkFactories *factories = [self valueForKey:@"adFactories"];
    if (!factories) {
        [self.logger error:@"❌ adFactories is nil!"];
        return nil;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"adFactories.rewardedInterstitials: %@", factories.rewardedInterstitials]];
    
    id<CLXAdapterRewardedFactory> factory = factories.rewardedInterstitials[network];
    if (!factory) {
        [self.logger error:[NSString stringWithFormat:@"❌ No rewarded factory found for network: %@ (Available: %@)", network, [factories.rewardedInterstitials allKeys]]];
        return nil;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Rewarded factory found for network: %@ (class: %@)", network, NSStringFromClass([factory class])]];
    
    id<CLXAdapterRewarded> rewarded = [factory createWithAdId:adId
                                                         bidId:bidId
                                                            adm:adm
                                                        extras:adapterExtras
                                                      delegate:self];
    
    if (!rewarded) {
        [self.logger error:@"❌ Factory returned nil rewarded"];
        return nil;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Rewarded created - Network: %@, BidID: %@", rewarded.network, rewarded.bidID]];
    
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
            [self.logger error:@"Rewarded load timeout after 30 seconds"];
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
        [self.logger logDelegateCallback:@"✅ Rewarded didLoadAd" ad:ad];
        [self.delegate didLoadAd:ad];
    }
}

- (void)notifyLoadFailure:(NSError *)error {
    [[CLXDebugOverlayManager shared] flashError];
    if ([self.delegate respondsToSelector:@selector(didFailToLoadAdWithError:)]) {
        [self.logger logDelegateError:@"❌ Rewarded didFailToLoadAd" error:error];
        [self.delegate didFailToLoadAdWithError:error];
    }
}

- (void)notifyShowFailure:(NSError *)error {
    [[CLXDebugOverlayManager shared] flashError];
    if ([self.delegate respondsToSelector:@selector(didFailToDisplayAd:error:)]) {
        [self.logger logDelegateError:@"❌ Rewarded didFailToDisplayAd" error:error];
        [self.delegate didFailToDisplayAd:[self createAdObject] error:error];
    }
}

- (void)notifyForceClose {
    if ([self.delegate respondsToSelector:@selector(didHideAd:)]) {
        CLXAd *ad = [self createAdObject];
        [self.logger logDelegateCallback:@"🔚 Rewarded didHideAd" ad:ad];
        [self.delegate didHideAd:ad];
    }
}

#pragma mark - CLXAdapterRewardedDelegate

- (void)didLoadWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    [self.logger debug:@"Rewarded adapter loaded successfully"];
    
    self.currentAdapter = rewarded;
    [self transitionToReadyState];
    
    [self fireLoadSuccessEventForBidID:rewarded.bidID price:self.lastBidResponse ? self.lastBidResponse.price : 0.0];
    [self fireLosingBidLurls];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyLoadSuccess];
    });
}

- (void)didFailToLoadWithRewarded:(id<CLXAdapterRewarded>)rewarded error:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"❌ didFailToLoadWithRewarded (%@): %@", rewarded, error.localizedDescription]];
    
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
            CLXAd *ad = [self createAdObject];
            [self.logger logDelegateCallback:@"👀 Rewarded didDisplayAd" ad:ad];
            [self.delegate didDisplayAd:ad];
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
        [self.logger logDelegateCallback:@"👁️ Rewarded didRecordImpression" ad:adObject];
        [self.delegate didRecordImpressionForAd:adObject];
    }
}

- (void)didCloseWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    [self handleAdClose];
    self.currentAdapter = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didHideAd:)]) {
            CLXAd *ad = [self createAdObject];
            [self.logger logDelegateCallback:@"🔚 Rewarded didHideAd" ad:ad];
            [self.delegate didHideAd:ad];
        }
    });
}

- (void)clickWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    [self handleClickTracking];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didClickAd:)]) {
            CLXAd *ad = [self createAdObject];
            [self.logger logDelegateCallback:@"👆 Rewarded didClickAd" ad:ad];
            [self.delegate didClickAd:ad];
        }
    });
}

- (void)userRewardWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    // Default to placement-configured reward values
    [self userRewardWithRewarded:rewarded amount:0 label:nil];
}

- (void)userRewardWithRewarded:(id<CLXAdapterRewarded>)rewarded amount:(NSInteger)amount label:(nullable NSString *)label {
    // Fire reward notification event to server
    [self fireRewardEventForBidID:rewarded.bidID];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CLXAd *ad = [self createAdObject];
        
        // Determine final reward values: adapter values override placement values if provided
        // If adapter provides non-zero amount, use it; otherwise fall back to placement config
        NSInteger finalAmount = (amount > 0) ? amount : self.placementRewardAmount;
        NSString *finalLabel = (label.length > 0) ? label : self.placementRewardCurrency;
        
        // Create reward object
        CLXReward *reward;
        if (finalAmount > 0 || finalLabel.length > 0) {
            reward = [CLXReward rewardWithAmount:finalAmount > 0 ? finalAmount : [CLXReward defaultAmount]
                                           label:finalLabel.length > 0 ? finalLabel : [CLXReward defaultLabel]];
        } else {
            reward = [CLXReward reward];
        }
        
        [self.logger logDelegateCallback:[NSString stringWithFormat:@"🎁 Rewarded didRewardUser\n  🎯 Amount: %ld\n  🏷️ Currency: %@", (long)reward.amount, reward.label] ad:ad];
        
        // Notify delegate of reward (required method per CLXRewardedDelegate protocol)
        [self.delegate didRewardUserForAd:ad withReward:reward];
    });
}

#pragma mark - Private Methods

- (void)fireRewardEventForBidID:(NSString *)bidID {
    if (bidID && self.currentBidResponse && self.currentBidResponse.id) {
        CLXBidResponseBid *winningBid = [self.currentBidResponse findBidWithID:bidID];
        double price = winningBid ? winningBid.price : 0.0;
        
        [self.logger debug:[NSString stringWithFormat:@"Firing REWARD event for bidID=%@, price=%.2f", bidID, price]];
        
        [self.winLossTracker sendEvent:self.currentBidResponse.id
                                 bidId:bidID
                                 event:[CLXBidLifecycleEvent rewardEvent]
                            lossReason:nil
                        winnerBidPrice:price];
        
        [self.logger debug:@"[CLXRewarded] REWARD event fired"];
    } else {
        [self.logger debug:[NSString stringWithFormat:@"Cannot fire reward event: bidID=%@, currentBidResponse=%@", 
                           bidID ?: @"(nil)", self.currentBidResponse ? @"present" : @"(nil)"]];
    }
}

- (void)didFailToShowWithRewarded:(id<CLXAdapterRewarded>)rewarded error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyShowFailure:error];
    });
}

- (void)expiredWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    [self.logger debug:@"Rewarded adapter expired"];
    self.currentAdapter = nil;
    [self transitionToIdleState];
}

@end

NS_ASSUME_NONNULL_END

