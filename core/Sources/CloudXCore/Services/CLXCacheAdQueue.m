/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CacheAdQueue.m
 * @brief Cache ad queue implementation
 */

#import <CloudXCore/CLXCacheAdQueue.h>
#import <CloudXCore/CLXEnvironmentConfig.h>
#import <CloudXCore/CLXAdEventReporting.h>
#import <CloudXCore/CLXAdEventReporter.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXCacheableAd.h>
#import <CloudXCore/CLXAppSessionService.h>
#import <CloudXCore/CLXLogger.h>

NS_ASSUME_NONNULL_BEGIN

@interface QueueItem : NSObject

@property (nonatomic, strong) id<CLXCacheableAd> ad;
@property (nonatomic, assign) double price;

- (instancetype)initWithAd:(id<CLXCacheableAd>)ad price:(double)price;

@end

@implementation QueueItem

- (instancetype)initWithAd:(id<CLXCacheableAd>)ad price:(double)price {
    self = [super init];
    if (self) {
        _ad = ad;
        _price = price;
    }
    return self;
}

- (NSComparisonResult)compare:(QueueItem *)other {
    if (self.price < other.price) {
        return NSOrderedAscending;
    } else if (self.price > other.price) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[QueueItem class]]) return NO;
    
    QueueItem *other = (QueueItem *)object;
    return [self.ad.network isEqualToString:other.ad.network];
}

@end

@interface CLXCacheAdQueue ()

@property (nonatomic, strong) id<CLXAdEventReporting> reportingService;
@property (nonatomic, strong, nullable) QueueItem *latestFirstElement;
@property (nonatomic, strong) NSMutableArray<QueueItem *> *sortedQueue;
@property (nonatomic, strong) NSOperationQueue *adLoadOperationQueue;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, copy) NSString *placementID;
@property (nonatomic, strong) id<CLXAppSessionService> appSessionService;

@end

@implementation CLXCacheAdQueue

- (instancetype)initWithMaxCapacity:(NSInteger)maxCapacity
                   reportingService:(id<CLXAdEventReporting>)reportingService
                        placementID:(NSString *)placementID {
    self = [super init];
    if (self) {
        _maxCapacity = maxCapacity;
        _reportingService = reportingService;
        _placementID = [placementID copy];
        _sortedQueue = [NSMutableArray array];
        _adLoadOperationQueue = [[NSOperationQueue alloc] init];
        _adLoadOperationQueue.maxConcurrentOperationCount = 2;
        _logger = [[CLXLogger alloc] initWithCategory:@"CacheAdQueue"];
        
        // Get app key from UserDefaults (matching Swift SDK behavior)
        NSString *appKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAppKeyKey] ?: @"";
        NSString *sessionID = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreSessionIDKey] ?: @"";
        // Use metrics URL from SDK response (stored in user defaults)
        NSString *metricsURL = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreMetricsUrlKey] ?: @"";
        _appSessionService = [[CLXAppSessionServiceImplementation alloc] initWithSessionID:sessionID
                                                                                 appKey:appKey
                                                                                    url:metricsURL];
    }
    return self;
}

- (BOOL)isEnoughSpace {
    return self.sortedQueue.count < self.maxCapacity;
}

- (BOOL)isEmpty {
    return self.sortedQueue.count == 0;
}

- (BOOL)hasItems {
    return self.sortedQueue.count > 0;
    
}

- (nullable id<CLXCacheableAd>)first {
    return self.sortedQueue.firstObject.ad;
}

- (void)enqueueAdWithPrice:(double)price
                loadTimeout:(NSTimeInterval)loadTimeout
                      bidID:(NSString *)bidID
                         ad:(nullable id<CLXCacheableAd>)ad
                 completion:(void (^)(NSError * _Nullable error))completion {
    
    if (!ad) {
        NSError *error = [NSError errorWithDomain:@"CacheAdQueue"
                                             code:CacheAdQueueErrorAdIsNil
                                         userInfo:@{NSLocalizedDescriptionKey: @"Ad is nil"}];
        completion(error);
        return;
    }
    
    [self.logger debug:@"Loading ad adapter"];
    
    NSDate *startTime = [NSDate date];
    
    // The ad object itself handles the timeout. We just need to handle the completion.
    [ad loadWithTimeout:loadTimeout completion:^(NSError * _Nullable error) {
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"Failed to load ad: %@", error.localizedDescription]];
            completion(error);
            return;
        }
        
        // Ad loaded successfully
        NSTimeInterval loadTime = [[NSDate date] timeIntervalSinceDate:startTime];
        [self.reportingService winWithBidID:bidID];
        [self addQueueItem:[[QueueItem alloc] initWithAd:ad price:price]];
        [self.appSessionService adLoadedWithPlacementID:self.placementID latency:loadTime * 1000];
        
        // Signal completion
        completion(nil);
    }];
}

- (void)addQueueItem:(QueueItem *)item {
    if (self.sortedQueue.count == 0) {
        self.latestFirstElement = item;
    }
    
    [self.logger debug:@"Adapter ad loaded. Put it in queue"];
    [self.sortedQueue addObject:item];
    
    // Sort by price (descending)
    [self.sortedQueue sortUsingComparator:^NSComparisonResult(QueueItem *obj1, QueueItem *obj2) {
        if (obj1.price > obj2.price) {
            return NSOrderedAscending;
        } else if (obj1.price < obj2.price) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    
    [self.logger debug:[NSString stringWithFormat:@"Queue contains %lu item(s)", (unsigned long)self.sortedQueue.count]];
}

- (nullable id<CLXCacheableAd>)popAd {
    if (self.sortedQueue.count == 0) {
        return nil;
    }
    
    QueueItem *item = self.sortedQueue.firstObject;
    [self.sortedQueue removeObjectAtIndex:0];
    
    [self.logger debug:[NSString stringWithFormat:@"pop ad from queue - %lu item(s) remaining", (unsigned long)self.sortedQueue.count]];
    
    return item.ad;
}

- (void)removeAd:(id<CLXCacheableAd>)ad {
    for (NSInteger i = 0; i < self.sortedQueue.count; i++) {
        QueueItem *item = self.sortedQueue[i];
        if ([item.ad.impressionID isEqualToString:ad.impressionID]) {
            [item.ad destroy];
            [self.sortedQueue removeObjectAtIndex:i];
            break;
        }
    }
}

- (void)destroy {
    for (QueueItem *item in self.sortedQueue) {
        [item.ad destroy];
    }
    [self.sortedQueue removeAllObjects];
}

@end

NS_ASSUME_NONNULL_END 
