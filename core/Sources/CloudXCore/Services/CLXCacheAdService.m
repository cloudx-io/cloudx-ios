/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CacheAdService.m
 * @brief Cache ad service implementation
 */

#import <CloudXCore/CLXCacheAdService.h>
#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXAdEventReporting.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXCacheableAd.h>
#import <CloudXCore/CLXDestroyable.h>
#import <CloudXCore/CLXSDKConfigPlacement.h>
#import <CloudXCore/CLXCacheAdQueue.h>
#import <CloudXCore/CLXExponentialBackoffStrategy.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXReachabilityService.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXAdType.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXCacheAdService ()

@property (nonatomic, strong, nullable) id<CLXBidAdSourceProtocol> bidAdSource;
@property (nonatomic, assign) NSTimeInterval bidLoadTimeout;
@property (nonatomic, copy) id<CLXCacheableAd> _Nullable (^createCacheableAd)(id _Nullable destroyable);
@property (nonatomic, strong, nullable) CLXReachabilityService *reachabilityService;
@property (nonatomic, strong) CLXSDKConfigPlacement *placement;
@property (nonatomic, strong) CLXCacheAdQueue *cachedQueue;
@property (nonatomic, assign) NSInteger showCount;
@property (nonatomic, strong) CLXExponentialBackoffStrategy *waterfallBackoffAlgorithm;
@property (nonatomic, strong, nullable) id willResignActiveObserver;
@property (nonatomic, strong, nullable) id didBecomeActiveNotification;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL winSuccess;
@property (nonatomic, assign) BOOL isSuspended;
@property (nonatomic, strong) CLXSettings *settings;
@property (nonatomic, assign) NSInteger adType;
@property (nonatomic, copy, nullable) NSString *currentCorrelationId;

@end

@implementation CLXCacheAdService

// Helper method to check if retries are enabled for the current ad type
- (BOOL)shouldEnableRetries {
    BOOL enabled = NO;
    NSString *adTypeName = @"unknown";
    
    switch (self.adType) {
        case CLXAdTypeBanner:
        case CLXAdTypeMrec:
            enabled = [self.settings shouldEnableBannerRetries];
            adTypeName = @"banner";
            break;
        case CLXAdTypeInterstitial:
            enabled = [self.settings shouldEnableInterstitialRetries];
            adTypeName = @"interstitial";
            break;
        case CLXAdTypeRewarded:
            enabled = [self.settings shouldEnableRewardedRetries];
            adTypeName = @"rewarded";
            break;
        case CLXAdTypeNative:
            enabled = [self.settings shouldEnableNativeRetries];
            adTypeName = @"native";
            break;
        default:
            break;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"%@ retries: %@", adTypeName, enabled ? @"enabled" : @"disabled"]];
    return enabled;
}



- (instancetype)initWithPlacement:(CLXSDKConfigPlacement *)placement
                      bidAdSource:(nullable id<CLXBidAdSourceProtocol>)bidAdSource
            waterfallMaxBackOffTime:(nullable NSNumber *)waterfallMaxBackOffTime
                          cacheSize:(NSInteger)cacheSize
                     bidLoadTimeout:(NSTimeInterval)bidLoadTimeout
                   reportingService:(id<AdEventReporting>)reportingService
                           settings:(CLXSettings *)settings
                            adType:(NSInteger)adType
                  createCacheableAd:(id<CLXCacheableAd> _Nullable (^)(id _Nullable destroyable))createCacheableAd {
    self = [super init];
    if (self) {
        _bidAdSource = bidAdSource;
        _placement = placement;
        _bidLoadTimeout = bidLoadTimeout;
        _createCacheableAd = [createCacheableAd copy];
        _reachabilityService = [[CLXReachabilityService alloc] init];
        _waterfallBackoffAlgorithm = [[CLXExponentialBackoffStrategy alloc] initWithInitialDelay:1.0
                                                                                      maxDelay:waterfallMaxBackOffTime ? waterfallMaxBackOffTime.doubleValue : 60.0];
        _cachedQueue = [[CLXCacheAdQueue alloc] initWithMaxCapacity:cacheSize
                                                reportingService:reportingService
                                                     placementID:placement.id];
        _logger = [[CLXLogger alloc] initWithCategory:@"CacheAdService"];
        _winSuccess = NO;
        _isSuspended = NO;
        _settings = settings;
        _adType = adType;
        
        // Set up notification observers
        _didBecomeActiveNotification = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                                                         object:nil
                                                                                          queue:[NSOperationQueue mainQueue]
                                                                                     usingBlock:^(NSNotification * _Nonnull note) {
            [self continueLoading];
        }];
        
        _willResignActiveObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification
                                                                                      object:nil
                                                                                       queue:[NSOperationQueue mainQueue]
                                                                                  usingBlock:^(NSNotification * _Nonnull note) {
            [self suspendLoading];
        }];
        
        [self startLoading];
    }
    return self;
}

- (void)dealloc {
    if (self.didBecomeActiveNotification) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.didBecomeActiveNotification];
    }
    
    if (self.willResignActiveObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.willResignActiveObserver];
    }
}

- (BOOL)hasAds {
    BOOL hasItems = self.cachedQueue.hasItems;
    [self.logger debug:[NSString stringWithFormat:@"hasAds called - cachedQueue: %@, hasItems: %d", self.cachedQueue, hasItems]];
    return hasItems;
}

- (nullable id<CLXCacheableAd>)first {
    return self.cachedQueue.first;
}

- (void)startLoading {
    // Implement async loading logic following Swift SDK pattern
    [self.logger debug:@"Start filling fullscreen ad queue"];
    
    // Start loading queue items
    [self loadQueueItem];
}

- (void)loadQueueItem {
    // Generate correlation ID for this cache ad load request
    self.currentCorrelationId = [[NSUUID UUID] UUIDString];
    
    // Implement actual queue item loading with async/await pattern
    if (!self.bidAdSource || self.isSuspended) {
        [self.logger debug:[NSString stringWithFormat:@"[%@] Queue loading %@", self.currentCorrelationId, self.isSuspended ? @"suspended" : @"no bid source"]];
        return;
    }
    
    [self.logger info:[NSString stringWithFormat:@"[%@] 🎬 [CacheAdService] Starting cache ad load for placement: %@", self.currentCorrelationId, self.placement.id]];
    
    __weak typeof(self) weakSelf = self;
    [self.bidAdSource requestBidWithAdUnitID:self.placement.id
                           storedImpressionId:self.placement.id
                                    impModel:nil
                                   successWin:self.winSuccess
                                correlationId:self.currentCorrelationId
                                   completion:^(CLXBidAdSourceResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        if (error) {
            [strongSelf.logger error:[NSString stringWithFormat:@"[%@] ❌ [CacheAdService] Bid failed: %@ (domain:%@, code:%ld)", strongSelf.currentCorrelationId, error.localizedDescription, error.domain, (long)error.code]];
            
            // Check if retries are enabled for this ad type
            if (![strongSelf shouldEnableRetries]) {
                [strongSelf.logger info:[NSString stringWithFormat:@"[%@] 🚫 [CacheAdService] Retries disabled for this ad type - failing immediately", strongSelf.currentCorrelationId]];
                return; // Exit without retrying
            }
            
            // Log retry attempt
            [strongSelf.logger debug:[NSString stringWithFormat:@"[%@] [CacheAdService] Retries enabled - will retry after backoff delay", strongSelf.currentCorrelationId]];
            
            // Implement waterfall backoff delay logic
            NSError *backoffError;
            NSTimeInterval delay = [strongSelf.waterfallBackoffAlgorithm nextDelayWithError:&backoffError];
            if (backoffError) {
                delay = 1.0; // Default delay if backoff fails
            }
            
            [strongSelf.logger debug:[NSString stringWithFormat:@"[%@] Sleep for %.1f seconds", strongSelf.currentCorrelationId, delay]];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if (strongSelf.cachedQueue.isEnoughSpace && !strongSelf.isSuspended) {
                    [strongSelf loadQueueItem];
                }
            });
        } else {
            strongSelf.winSuccess = YES;
            
            // Reset waterfall backoff algorithm
            NSTimeInterval delay = [strongSelf.waterfallBackoffAlgorithm reset];
            
            [strongSelf.logger info:[NSString stringWithFormat:@"[%@] [CacheAdService] Bid response received - Network: %@, BidID: %@", strongSelf.currentCorrelationId, response.networkName, response.bidID]];
            
            // Create cacheable ad from response
            if (strongSelf.createCacheableAd && response) {
                [strongSelf.logger debug:[NSString stringWithFormat:@"[%@] [CacheAdService] Creating cacheable ad - Network: %@, BidID: %@", strongSelf.currentCorrelationId, response.networkName, response.bidID]];
                
                // Call createBidAd block without parameters (it captures parameters internally)
                id destroyable = response.createBidAd();
                
                if (destroyable) {
                    id<CLXCacheableAd> cacheableAd = strongSelf.createCacheableAd(destroyable);
                    [strongSelf.logger debug:[NSString stringWithFormat:@"Cacheable ad created: %@", cacheableAd]];
                    
                    if (cacheableAd) {
                        // Set the bid response on the cacheable ad for NURL firing
                        CLXBidResponse *bidResponse = [strongSelf.bidAdSource getCurrentBidResponse];
                        cacheableAd.bidResponse = bidResponse;
                        [strongSelf.logger debug:@"Set bidResponse on cacheable ad and enqueueing"];
                        [strongSelf.cachedQueue enqueueAdWithPrice:response.price
                                                       loadTimeout:strongSelf.bidLoadTimeout
                                                             bidID:response.bidID
                                                                ad:cacheableAd
                                                        completion:^(NSError * _Nullable error) {
                            if (error) {
                                [strongSelf.logger error:[NSString stringWithFormat:@"Failed to enqueue ad: %@", error.localizedDescription]];
                            } else {
                                [strongSelf.logger info:[NSString stringWithFormat:@"Ad successfully enqueued to service: %@", strongSelf]];
                            }
                        }];
                    } else {
                        [strongSelf.logger error:@"Failed to create cacheable ad from destroyable"];
                    }
                } else {
                    [strongSelf.logger error:@"Failed to create destroyable from bid response"];
                }
            } else {
                [strongSelf.logger error:[NSString stringWithFormat:@"Missing createCacheableAd block (%d) or response (%d)", strongSelf.createCacheableAd != nil, response != nil]];
            }
            
            // Schedule next load
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if (strongSelf.cachedQueue.isEnoughSpace && !strongSelf.isSuspended) {
                    [strongSelf loadQueueItem];
                }
            });
        }
    }];
}

- (void)suspendLoading {
    // Implement pause queue loading
    [self.logger debug:@"Suspending queue loading"];
    // TODO: Add a flag to track suspended state and prevent new loads
    self.isSuspended = YES;
}

- (void)continueLoading {
    // Implement continue queue loading
    [self.logger debug:@"Continuing queue loading"];
    self.isSuspended = NO;
    [self startLoading];
}

- (void)destroy {
    [self.cachedQueue destroy];
}

- (nullable id<CLXCacheableAd>)popAd {
    id<CLXCacheableAd> ad = [self.cachedQueue popAd];
    [self startLoading];
    return ad;
}

- (void)adError:(id)ad {
    [self.cachedQueue removeAd:ad];
    [self startLoading];
}

@end

NS_ASSUME_NONNULL_END 
