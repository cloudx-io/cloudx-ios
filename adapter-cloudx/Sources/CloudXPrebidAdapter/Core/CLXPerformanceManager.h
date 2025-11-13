//
//  CLXPerformanceManager.h
//  CloudXPrebidAdapter
//
//  Performance optimization and memory management for prebid ads
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Performance metrics data
 */
@interface CLXPerformanceMetrics : NSObject
@property (nonatomic, assign) NSTimeInterval loadTime;
@property (nonatomic, assign) NSTimeInterval renderTime;
@property (nonatomic, assign) NSUInteger memoryUsage;
@property (nonatomic, assign) NSUInteger cacheHits;
@property (nonatomic, assign) NSUInteger cacheMisses;
@property (nonatomic, assign) NSTimeInterval lastOptimizationTime;
@end

/**
 * Cache entry for ad content
 */
@interface CLXAdCacheEntry : NSObject
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSString *mimeType;
@property (nonatomic, assign) NSTimeInterval creationTime;
@property (nonatomic, assign) NSTimeInterval lastAccessTime;
@property (nonatomic, assign) NSUInteger accessCount;
@property (nonatomic, assign) NSUInteger size;
@end

/**
 * Preload request for background processing
 */
@interface CLXPreloadRequest : NSObject
@property (nonatomic, strong) NSString *adMarkup;
@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, assign) CGSize adSize;
@property (nonatomic, assign) NSInteger priority;
@property (nonatomic, copy) void (^completionHandler)(BOOL success);
@end

/**
 * Performance and memory optimization manager
 */
@interface CLXPerformanceManager : NSObject

@property (nonatomic, strong, readonly) CLXPerformanceMetrics *metrics;
@property (nonatomic, assign) NSUInteger maxCacheSize; // Default: 50MB
@property (nonatomic, assign) NSTimeInterval cacheExpirationTime; // Default: 1 hour
@property (nonatomic, assign) BOOL backgroundProcessingEnabled; // Default: YES
@property (nonatomic, assign) NSUInteger maxConcurrentPreloads; // Default: 3

/**
 * Singleton instance
 */
+ (instancetype)sharedManager;

/**
 * Memory management
 */
- (void)optimizeMemoryUsage;
- (void)clearCache;
- (NSUInteger)currentMemoryUsage;
- (void)handleMemoryWarning;

/**
 * Caching
 */
- (void)cacheContent:(NSData *)content forKey:(NSString *)key mimeType:(NSString *)mimeType;
- (nullable NSData *)cachedContentForKey:(NSString *)key;
- (void)removeCachedContentForKey:(NSString *)key;
- (NSArray<NSString *> *)allCachedKeys;

/**
 * Background processing and preloading
 */
- (void)preloadAdContent:(CLXPreloadRequest *)request;
- (void)cancelPreloadRequest:(NSString *)requestId;
- (void)pauseBackgroundProcessing;
- (void)resumeBackgroundProcessing;

/**
 * Performance monitoring
 */
- (void)startLoadTimerForKey:(NSString *)key;
- (void)endLoadTimerForKey:(NSString *)key;
- (void)startRenderTimerForKey:(NSString *)key;
- (void)endRenderTimerForKey:(NSString *)key;
- (void)recordCacheHit;
- (void)recordCacheMiss;

/**
 * Resource optimization
 */
- (NSString *)optimizeHTMLContent:(NSString *)html forSize:(CGSize)size;
- (NSData *)compressImageData:(NSData *)imageData quality:(CGFloat)quality;
- (void)preloadImagesInHTML:(NSString *)html completion:(void (^)(NSArray<NSString *> *preloadedKeys))completion;

/**
 * Cleanup and maintenance
 */
- (void)performMaintenanceTasks;
- (void)cleanupExpiredCache;
- (void)defragmentCache;

@end

NS_ASSUME_NONNULL_END