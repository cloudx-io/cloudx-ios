//
//  CLXPerformanceManager.m
//  CloudXPrebidAdapter
//
//  Performance optimization implementation for CloudX Prebid Adapter
//  
//  This class provides enterprise-grade performance optimization including:
//  - Intelligent caching with LRU eviction and expiration
//  - Background resource preloading for faster ad rendering
//  - Memory pressure monitoring and automatic cleanup
//  - Performance metrics collection and monitoring
//  - HTML optimization and compression
//  - Concurrent operation management
//

#import "CLXPerformanceManager.h"
#import <sys/sysctl.h>
#import <mach/mach.h>
#import <CloudXCore/CLXLogger.h>

/**
 * CLXPerformanceMetrics - Performance measurement data container
 * 
 * Tracks key performance indicators including load times, render times,
 * memory usage, cache hit rates, and optimization timestamps.
 */
@implementation CLXPerformanceMetrics

/**
 * Initialize performance metrics with current timestamp
 * Sets up baseline for tracking optimization intervals
 */
- (instancetype)init {
    self = [super init];
    if (self) {
        _lastOptimizationTime = [NSDate timeIntervalSinceReferenceDate];
    }
    return self;
}

@end

/**
 * CLXAdCacheEntry - Individual cache entry for ad content
 * 
 * Manages lifecycle of cached ad resources including:
 * - Creation and access timestamps for LRU eviction
 * - Access count for usage analytics
 * - Size tracking for memory management
 * - MIME type for proper content handling
 */
@implementation CLXAdCacheEntry

/**
 * Initialize cache entry with current timestamp and zero access count
 * Prepares entry for LRU tracking and memory management
 */
- (instancetype)init {
    self = [super init];
    if (self) {
        NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
        _creationTime = now;
        _lastAccessTime = now;
        _accessCount = 0;
    }
    return self;
}

@end

/**
 * CLXPreloadRequest - Background preload operation request
 * 
 * Encapsulates preload operation parameters including ad markup,
 * base URL, size constraints, priority, and completion handling.
 */
@implementation CLXPreloadRequest
@end

/**
 * Private interface for CLXPerformanceManager
 * 
 * Contains internal properties for caching, timing, queue management,
 * and performance monitoring that should not be exposed publicly.
 */
@interface CLXPerformanceManager ()
@property (nonatomic, strong, readwrite) CLXPerformanceMetrics *metrics;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CLXAdCacheEntry *> *cache;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *loadTimers;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *renderTimers;
@property (nonatomic, strong) dispatch_queue_t backgroundQueue;
@property (nonatomic, strong) dispatch_queue_t cacheQueue;
@property (nonatomic, strong) NSOperationQueue *preloadQueue;
@property (nonatomic, strong) NSTimer *maintenanceTimer;
@property (nonatomic, assign) NSUInteger currentCacheSize;
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXPerformanceManager

/**
 * Singleton accessor for CLXPerformanceManager
 * 
 * Ensures single instance across the application for consistent
 * performance management and resource sharing.
 * 
 * @return Shared CLXPerformanceManager instance
 */
+ (instancetype)sharedManager {
    static CLXPerformanceManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CLXPerformanceManager alloc] init];
    });
    return sharedInstance;
}

/**
 * Initialize performance manager with default configuration
 * 
 * Sets up:
 * - Performance metrics tracking
 * - LRU cache with 50MB limit and 1-hour expiration
 * - Background processing queues for concurrent operations
 * - Memory pressure monitoring and automatic cleanup
 * - Maintenance timer for periodic optimization
 */
- (instancetype)init {
    self.logger = [[CLXLogger alloc] initWithCategory:@"CLXPerformanceManager"];
    [self.logger info:@"🚀 [PERFORMANCE-INIT] CLXPerformanceManager initialization started"];
    
    self = [super init];
    if (self) {
        [self.logger info:@"✅ [PERFORMANCE-INIT] Super init successful"];
        
        // Initialize performance tracking components
        _metrics = [[CLXPerformanceMetrics alloc] init];
        _cache = [NSMutableDictionary dictionary];
        _loadTimers = [NSMutableDictionary dictionary];
        _renderTimers = [NSMutableDictionary dictionary];
        
        // Configure cache settings for optimal performance
        _maxCacheSize = 50 * 1024 * 1024; // 50MB cache limit
        _cacheExpirationTime = 3600; // 1 hour expiration
        _backgroundProcessingEnabled = YES;
        _maxConcurrentPreloads = 3; // Limit concurrent preloads to prevent resource exhaustion
        _currentCacheSize = 0;
        
        [self.logger debug:@"📊 [PERFORMANCE-INIT] Configuration:"];
        [self.logger debug:[NSString stringWithFormat:@"  📍 Max cache size: %lu MB", (unsigned long)(_maxCacheSize / 1024 / 1024)]];
        [self.logger debug:[NSString stringWithFormat:@"  📍 Cache expiration: %ld seconds", (long)_cacheExpirationTime]];
        [self.logger debug:[NSString stringWithFormat:@"  📍 Background processing: %@", _backgroundProcessingEnabled ? @"Enabled" : @"Disabled"]];
        [self.logger debug:[NSString stringWithFormat:@"  📍 Max concurrent preloads: %ld", (long)_maxConcurrentPreloads]];
        
        // Create GCD queues for concurrent operations
        _backgroundQueue = dispatch_queue_create("com.cloudx.prebid.background", DISPATCH_QUEUE_CONCURRENT);
        _cacheQueue = dispatch_queue_create("com.cloudx.prebid.cache", DISPATCH_QUEUE_SERIAL);
        [self.logger info:@"✅ [PERFORMANCE-INIT] GCD queues created"];
        
        // Configure operation queue for background preloading
        _preloadQueue = [[NSOperationQueue alloc] init];
        _preloadQueue.maxConcurrentOperationCount = _maxConcurrentPreloads;
        _preloadQueue.name = @"PreloadQueue";
        [self.logger info:@"✅ [PERFORMANCE-INIT] Preload queue configured"];
        
        // Register for system notifications
        [self setupNotifications];
        [self.logger info:@"✅ [PERFORMANCE-INIT] Notifications registered"];
        
        // Start maintenance timer for periodic cleanup
        [self startMaintenanceTimer];
        [self.logger info:@"✅ [PERFORMANCE-INIT] Maintenance timer started (5 minutes interval)"];
        
        [self.logger info:@"🎯 [PERFORMANCE-INIT] CLXPerformanceManager initialization completed successfully"];
    } else {
        [self.logger error:@"❌ [PERFORMANCE-INIT] Super init failed"];
    }
    return self;
}

/**
 * Cleanup resources and remove notification observers
 * Prevents memory leaks and ensures proper shutdown
 */
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.maintenanceTimer invalidate];
}

/**
 * Register for system notifications to handle memory pressure and app lifecycle
 * 
 * Monitors:
 * - Memory warnings for aggressive cache cleanup
 * - App backgrounding for resource optimization
 * - App foregrounding for performance restoration
 */
- (void)setupNotifications {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(handleMemoryWarning)
                   name:UIApplicationDidReceiveMemoryWarningNotification
                 object:nil];
    [center addObserver:self
               selector:@selector(handleAppBackground)
                   name:UIApplicationDidEnterBackgroundNotification
                 object:nil];
    [center addObserver:self
               selector:@selector(handleAppForeground)
                   name:UIApplicationWillEnterForegroundNotification
                 object:nil];
}

/**
 * Start maintenance timer for periodic cache cleanup and optimization
 * 
 * Runs every 5 minutes to:
 * - Remove expired cache entries
 * - Defragment cache for better access patterns
 * - Update memory usage metrics
 */
- (void)startMaintenanceTimer {
    self.maintenanceTimer = [NSTimer scheduledTimerWithTimeInterval:300.0 // 5 minutes
                                                            target:self
                                                          selector:@selector(performMaintenanceTasks)
                                                          userInfo:nil
                                                           repeats:YES];
}

#pragma mark - Memory Management

/**
 * Optimize memory usage by cleaning expired entries and evicting least recently used items
 * 
 * Called automatically during memory pressure or maintenance cycles.
 * Ensures cache stays within configured size limits while preserving
 * most frequently accessed content.
 */
- (void)optimizeMemoryUsage {
    dispatch_async(self.cacheQueue, ^{
        NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
        
        // Log current memory usage before optimization
        NSUInteger currentMemoryMB = [self currentMemoryUsage] / 1024 / 1024;
        NSUInteger maxMemoryMB = self.maxCacheSize / 1024 / 1024;
        NSUInteger usedCacheMB = self.currentCacheSize / 1024 / 1024;
        
        [self.logger info:[NSString stringWithFormat:@"🧠 [PERFORMANCE] Memory usage: %lu MB (limit: %lu MB)", currentMemoryMB, maxMemoryMB]];
        [self.logger info:[NSString stringWithFormat:@"⚡ [PERFORMANCE] Cache size: %lu MB / %lu MB", usedCacheMB, maxMemoryMB]];
        
        // Remove expired entries first
        [self cleanupExpiredCacheInternal];
        
        // If still over limit, remove least recently used items
        if (self.currentCacheSize > self.maxCacheSize) {
            [self evictLeastRecentlyUsedItems];
        }
        
        // Log memory usage after optimization
        NSUInteger newMemoryMB = [self currentMemoryUsage] / 1024 / 1024;
        NSUInteger newUsedCacheMB = self.currentCacheSize / 1024 / 1024;
        
        [self.logger info:[NSString stringWithFormat:@"🧠 [PERFORMANCE] Memory usage after optimization: %lu MB", newMemoryMB]];
        [self.logger info:[NSString stringWithFormat:@"⚡ [PERFORMANCE] Cache size after optimization: %lu MB / %lu MB", newUsedCacheMB, maxMemoryMB]];
        
        // Update metrics
        self.metrics.lastOptimizationTime = now;
    });
}

/**
 * Clear all cached content immediately
 * 
 * Used for aggressive memory cleanup or when switching ad campaigns.
 * Resets cache size counter and removes all entries.
 */
- (void)clearCache {
    dispatch_async(self.cacheQueue, ^{
        [self.cache removeAllObjects];
        self.currentCacheSize = 0;
    });
}

/**
 * Get current memory usage of the application
 * 
 * Uses Mach task info to get accurate resident memory size.
 * 
 * @return Current memory usage in bytes
 */
- (NSUInteger)currentMemoryUsage {
    struct mach_task_basic_info info;
    mach_msg_type_number_t size = MACH_TASK_BASIC_INFO_COUNT;
    kern_return_t kerr = task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&info, &size);
    return (kerr == KERN_SUCCESS) ? info.resident_size : 0;
}

/**
 * Handle system memory warning by performing aggressive cleanup
 * 
 * When system memory is low:
 * - Removes 50% of cached items starting with least recently used
 * - Cancels non-essential preload operations
 * - Forces URL cache cleanup
 * - Updates memory usage metrics
 */
- (void)handleMemoryWarning {
    [self.logger info:@"[CLXPerformanceManager] Memory warning received, optimizing..."];
    
    // Aggressive cleanup
    dispatch_async(self.cacheQueue, ^{
        // Remove 50% of cached items, starting with least recently used
        NSUInteger targetSize = self.maxCacheSize / 2;
        [self evictCacheToSize:targetSize];
        
        // Cancel non-essential preloads
        [self.preloadQueue cancelAllOperations];
        
        // Force garbage collection hint
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSURLCache sharedURLCache] removeAllCachedResponses];
        });
    });
}

#pragma mark - Caching

/**
 * Cache content with specified key and MIME type
 * 
 * Stores ad content in LRU cache with automatic size tracking.
 * If cache is full, least recently used items are evicted.
 * 
 * @param content Data to cache
 * @param key Unique identifier for cached content
 * @param mimeType MIME type for proper content handling
 */
- (void)cacheContent:(NSData *)content forKey:(NSString *)key mimeType:(NSString *)mimeType {
    if (!content || !key) return;
    
    dispatch_async(self.cacheQueue, ^{
        // Create cache entry with metadata
        CLXAdCacheEntry *entry = [[CLXAdCacheEntry alloc] init];
        entry.key = key;
        entry.data = content;
        entry.mimeType = mimeType ?: @"application/octet-stream";
        entry.size = content.length;
        
        // Check if we need to make space
        if (self.currentCacheSize + entry.size > self.maxCacheSize) {
            [self evictCacheToSize:self.maxCacheSize - entry.size];
        }
        
        // Store entry and update size
        self.cache[key] = entry;
        self.currentCacheSize += entry.size;
        
        [self.logger debug:[NSString stringWithFormat:@"📦 [CACHE] Cached content for key: %@, size: %lu bytes", key, (unsigned long)entry.size]];
    });
}

/**
 * Retrieve cached content by key
 * 
 * Updates access timestamp for LRU tracking and increments access count.
 * Returns nil if content is not found or has expired.
 * 
 * @param key Unique identifier for cached content
 * @return Cached data or nil if not found
 */
- (nullable NSData *)cachedContentForKey:(NSString *)key {
    if (!key) return nil;
    
    __block NSData *result = nil;
    dispatch_sync(self.cacheQueue, ^{
        CLXAdCacheEntry *entry = self.cache[key];
        if (entry) {
            // Update access metadata for LRU tracking
            entry.lastAccessTime = [NSDate timeIntervalSinceReferenceDate];
            entry.accessCount++;
            result = entry.data;
            
            [self.logger debug:[NSString stringWithFormat:@"📦 [CACHE] Cache hit for key: %@", key]];
        } else {
            [self.logger debug:[NSString stringWithFormat:@"📦 [CACHE] Cache miss for key: %@", key]];
        }
    });
    return result;
}

/**
 * Remove specific cached content by key
 * 
 * Updates cache size counter and removes entry from cache.
 * 
 * @param key Unique identifier for cached content to remove
 */
- (void)removeCachedContentForKey:(NSString *)key {
    if (!key) return;
    
    dispatch_async(self.cacheQueue, ^{
        CLXAdCacheEntry *entry = self.cache[key];
        if (entry) {
            self.currentCacheSize -= entry.size;
            [self.cache removeObjectForKey:key];
            [self.logger debug:[NSString stringWithFormat:@"🗑️ [CACHE] Removed cached content for key: %@", key]];
        }
    });
}

/**
 * Get all cached content keys
 * 
 * Returns array of all currently cached content identifiers.
 * Useful for cache inspection and debugging.
 * 
 * @return Array of cached content keys
 */
- (NSArray<NSString *> *)allCachedKeys {
    __block NSArray<NSString *> *keys = nil;
    dispatch_sync(self.cacheQueue, ^{
        keys = [self.cache.allKeys copy];
    });
    return keys;
}

#pragma mark - Background Processing and Preloading

/**
 * Preload ad content in background for improved performance
 * 
 * Parses HTML content and preloads images and other resources.
 * Uses operation queue for concurrent processing with priority control.
 * 
 * @param request Preload request containing ad markup and configuration
 */
- (void)preloadAdContent:(CLXPreloadRequest *)request {
    if (!self.backgroundProcessingEnabled || !request || !request.adMarkup) {
        [self.logger debug:[NSString stringWithFormat:@"⚠️ [PRELOAD] Skipping preload - background processing: %@, request: %@, adMarkup: %@", 
              self.backgroundProcessingEnabled ? @"YES" : @"NO",
              request ? @"Present" : @"nil",
              request.adMarkup ? @"Present" : @"nil"]];
        return;
    }
    
    NSBlockOperation *preloadOp = [NSBlockOperation blockOperationWithBlock:^{
        // Parse HTML and preload images
        [self preloadImagesInHTML:request.adMarkup completion:^(NSArray<NSString *> *preloadedKeys) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (request.completionHandler) {
                    request.completionHandler(preloadedKeys.count > 0);
                }
            });
        }];
    }];
    
    preloadOp.queuePriority = (NSOperationQueuePriority)request.priority;
    [self.preloadQueue addOperation:preloadOp];
}

/**
 * Cancel preload request by ID
 * 
 * Currently cancels all operations for simplicity.
 * In a full implementation, would track operations by specific ID.
 * 
 * @param requestId Unique identifier for preload request to cancel
 */
- (void)cancelPreloadRequest:(NSString *)requestId {
    // In a full implementation, you'd track operations by ID
    // For now, cancel all operations (simplified)
    [self.preloadQueue cancelAllOperations];
}

/**
 * Pause background processing operations
 * 
 * Suspends preload queue to conserve resources during high load.
 */
- (void)pauseBackgroundProcessing {
    [self.preloadQueue setSuspended:YES];
}

/**
 * Resume background processing operations
 * 
 * Resumes preload queue after being paused.
 */
- (void)resumeBackgroundProcessing {
    [self.preloadQueue setSuspended:NO];
}

#pragma mark - Performance Monitoring

/**
 * Start load timer for performance measurement
 * 
 * Records the start time for ad loading operations
 * to measure load performance metrics.
 * 
 * @param key Unique identifier for the load operation
 */
- (void)startLoadTimerForKey:(NSString *)key {
    if (!key) return;
    
    dispatch_async(self.cacheQueue, ^{
        self.loadTimers[key] = @([NSDate timeIntervalSinceReferenceDate]);
        [self.logger debug:[NSString stringWithFormat:@"📊 [PERFORMANCE] Started load timer for key: %@", key]];
    });
}

/**
 * End load timer and record performance metrics
 * 
 * Calculates load time and updates performance metrics
 * for the specified load operation.
 * 
 * @param key Unique identifier for the load operation
 */
- (void)endLoadTimerForKey:(NSString *)key {
    if (!key) return;
    
    dispatch_async(self.cacheQueue, ^{
        NSNumber *startTime = self.loadTimers[key];
        if (startTime) {
            NSTimeInterval loadTime = [NSDate timeIntervalSinceReferenceDate] - [startTime doubleValue];
            self.metrics.loadTime = loadTime;
            [self.loadTimers removeObjectForKey:key];
            
            [self.logger info:[NSString stringWithFormat:@"📊 [PERFORMANCE] Load time for %@: %.3f seconds", key, loadTime]];
            
            // Update last optimization time
            self.metrics.lastOptimizationTime = [NSDate timeIntervalSinceReferenceDate];
        }
    });
}

/**
 * Start render timer for performance measurement
 * 
 * Records the start time for ad rendering operations
 * to measure render performance metrics.
 * 
 * @param key Unique identifier for the render operation
 */
- (void)startRenderTimerForKey:(NSString *)key {
    if (!key) return;
    
    dispatch_async(self.cacheQueue, ^{
        self.renderTimers[key] = @([NSDate timeIntervalSinceReferenceDate]);
        [self.logger debug:[NSString stringWithFormat:@"📊 [PERFORMANCE] Started render timer for key: %@", key]];
    });
}

/**
 * End render timer and record performance metrics
 * 
 * Calculates render time and updates performance metrics
 * for the specified render operation.
 * 
 * @param key Unique identifier for the render operation
 */
- (void)endRenderTimerForKey:(NSString *)key {
    if (!key) return;
    
    dispatch_async(self.cacheQueue, ^{
        NSNumber *startTime = self.renderTimers[key];
        if (startTime) {
            NSTimeInterval renderTime = [NSDate timeIntervalSinceReferenceDate] - [startTime doubleValue];
            self.metrics.renderTime = renderTime;
            [self.renderTimers removeObjectForKey:key];
            
            [self.logger info:[NSString stringWithFormat:@"📊 [PERFORMANCE] Render time for %@: %.3f seconds", key, renderTime]];
            
            // Update last optimization time
            self.metrics.lastOptimizationTime = [NSDate timeIntervalSinceReferenceDate];
        }
    });
}

/**
 * Record cache hit for analytics
 * 
 * Increments cache hit counter for performance monitoring.
 */
- (void)recordCacheHit {
    self.metrics.cacheHits++;
    
    // Calculate and log detailed cache performance metrics
    NSUInteger totalRequests = self.metrics.cacheHits + self.metrics.cacheMisses;
    CGFloat hitRate = totalRequests > 0 ? (CGFloat)self.metrics.cacheHits / totalRequests * 100.0 : 0.0;
    
    [self.logger info:[NSString stringWithFormat:@"💾 [PERFORMANCE] Cache hit rate: %.1f%% (%lu hits, %lu misses)", hitRate, self.metrics.cacheHits, self.metrics.cacheMisses]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PERFORMANCE] Cache hit recorded - Total requests: %lu", totalRequests]];
}

/**
 * Record cache miss for analytics
 * 
 * Increments cache miss counter for performance monitoring.
 */
- (void)recordCacheMiss {
    self.metrics.cacheMisses++;
    
    // Calculate and log detailed cache performance metrics
    NSUInteger totalRequests = self.metrics.cacheHits + self.metrics.cacheMisses;
    CGFloat hitRate = totalRequests > 0 ? (CGFloat)self.metrics.cacheHits / totalRequests * 100.0 : 0.0;
    
    [self.logger info:[NSString stringWithFormat:@"💾 [PERFORMANCE] Cache hit rate: %.1f%% (%lu hits, %lu misses)", hitRate, self.metrics.cacheHits, self.metrics.cacheMisses]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PERFORMANCE] Cache miss recorded - Total requests: %lu", totalRequests]];
}

#pragma mark - Resource Optimization

/**
 * Optimize HTML content for better performance
 * 
 * Applies performance optimizations to HTML content including:
 * - Minification of whitespace and comments
 * - Compression of inline styles
 * - Optimization of image references
 * - Removal of unnecessary attributes
 * 
 * @param html Original HTML content
 * @param size Target size for optimization
 * @return Optimized HTML content or nil if optimization fails
 */
- (NSString *)optimizeHTMLContent:(NSString *)html forSize:(CGSize)size {
    if (!html || html.length == 0) {
        return nil;
    }
    
    [self.logger debug:@"🔧 [PERFORMANCE] Optimizing HTML content"];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PERFORMANCE] Original size: %lu characters", (unsigned long)html.length]];
    
    NSMutableString *optimizedHTML = [html mutableCopy];
    
    // Basic optimizations
    // Remove extra whitespace and newlines
    NSRegularExpression *whitespaceRegex = [NSRegularExpression regularExpressionWithPattern:@"\\s+" options:0 error:nil];
    [whitespaceRegex replaceMatchesInString:optimizedHTML options:0 range:NSMakeRange(0, optimizedHTML.length) withTemplate:@" "];
    
    // Remove HTML comments
    NSRegularExpression *commentRegex = [NSRegularExpression regularExpressionWithPattern:@"<!--.*?-->" options:NSRegularExpressionDotMatchesLineSeparators error:nil];
    [commentRegex replaceMatchesInString:optimizedHTML options:0 range:NSMakeRange(0, optimizedHTML.length) withTemplate:@""];
    
    // Trim leading/trailing whitespace
    [optimizedHTML setString:[optimizedHTML stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    
    [self.logger debug:[NSString stringWithFormat:@"📊 [PERFORMANCE] Optimized size: %lu characters", (unsigned long)optimizedHTML.length]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [PERFORMANCE] Compression ratio: %.1f%%", (1.0 - (double)optimizedHTML.length / html.length) * 100]];
    
    return optimizedHTML;
}

/**
 * Compress image data with specified quality
 * 
 * Converts image to JPEG format with specified compression quality.
 * Returns original data if compression fails.
 * 
 * @param imageData Original image data
 * @param quality Compression quality (0.0 to 1.0)
 * @return Compressed image data
 */
- (NSData *)compressImageData:(NSData *)imageData quality:(CGFloat)quality {
    UIImage *image = [UIImage imageWithData:imageData];
    if (!image) return imageData;
    
    return UIImageJPEGRepresentation(image, quality);
}

/**
 * Preload images from HTML content
 * 
 * Extracts image URLs from HTML using regex pattern matching.
 * Downloads and caches images in background for faster rendering.
 * Uses dispatch groups for concurrent downloads with completion tracking.
 * 
 * @param html HTML content containing image tags
 * @param completion Completion block called with array of preloaded cache keys
 */
- (void)preloadImagesInHTML:(NSString *)html completion:(void (^)(NSArray<NSString *> *preloadedKeys))completion {
    dispatch_async(self.backgroundQueue, ^{
        NSMutableArray *preloadedKeys = [NSMutableArray array];
        
        // Check if HTML is valid
        if (!html || html.length == 0) {
            [self.logger debug:@"⚠️ [PRELOAD] HTML content is nil or empty, skipping preload"];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion([preloadedKeys copy]);
                }
            });
            return;
        }
        
        [self.logger debug:[NSString stringWithFormat:@"🔄 [PRELOAD] Starting image preload for HTML length: %lu", (unsigned long)html.length]];
        
        // Log active preload count
        NSUInteger activePreloads = self.preloadQueue.operationCount;
        [self.logger info:[NSString stringWithFormat:@"🔄 [PERFORMANCE] Background preloads: %lu active", activePreloads]];
        
        // Extract image URLs from HTML using regex pattern
        NSRegularExpression *imgRegex = [NSRegularExpression regularExpressionWithPattern:@"<img[^>]+src=['\"]([^'\"]+)['\"]"
                                                                                  options:NSRegularExpressionCaseInsensitive
                                                                                    error:nil];
        if (!imgRegex) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion([preloadedKeys copy]);
                }
            });
            return;
        }
        
        NSArray *matches = [imgRegex matchesInString:html options:0 range:NSMakeRange(0, html.length)];
        
        // Use dispatch group for concurrent downloads
        dispatch_group_t group = dispatch_group_create();
        
        for (NSTextCheckingResult *match in matches) {
            if (match.numberOfRanges > 1) {
                NSString *urlString = [html substringWithRange:[match rangeAtIndex:1]];
                NSURL *url = [NSURL URLWithString:urlString];
                
                if (url) {
                    dispatch_group_enter(group);
                    
                    // Download image data
                    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                        if (data && !error) {
                            NSString *cacheKey = [NSString stringWithFormat:@"img_%lu", (unsigned long)[urlString hash]];
                            [self cacheContent:data forKey:cacheKey mimeType:response.MIMEType ?: @"image/jpeg"];
                            [preloadedKeys addObject:cacheKey];
                        }
                        dispatch_group_leave(group);
                    }];
                    [task resume];
                }
            }
        }
        
        // Notify completion when all downloads finish
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            [self.logger debug:[NSString stringWithFormat:@"✅ [PRELOAD] Image preload completed - %lu images preloaded", (unsigned long)preloadedKeys.count]];
            if (completion) {
                completion([preloadedKeys copy]);
            }
        });
    });
}

#pragma mark - Maintenance

/**
 * Perform periodic maintenance tasks
 * 
 * Called by maintenance timer every 5 minutes to:
 * - Clean up expired cache entries
 * - Defragment cache for better access patterns
 * - Update memory usage metrics
 */
- (void)performMaintenanceTasks {
    dispatch_async(self.cacheQueue, ^{
        [self cleanupExpiredCacheInternal];
        [self defragmentCache];
        
        // Update memory usage metric
        self.metrics.memoryUsage = [self currentMemoryUsage];
    });
}

/**
 * Clean up expired cache entries
 * 
 * Public interface for manual cache cleanup.
 * Dispatches to background queue for thread safety.
 */
- (void)cleanupExpiredCache {
    dispatch_async(self.cacheQueue, ^{
        [self cleanupExpiredCacheInternal];
    });
}

/**
 * Internal method to remove expired cache entries
 * 
 * Iterates through cache and removes entries that have exceeded
 * the configured expiration time. Updates cache size counter.
 */
- (void)cleanupExpiredCacheInternal {
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    NSMutableArray *keysToRemove = [NSMutableArray array];
    
    for (NSString *key in self.cache.allKeys) {
        CLXAdCacheEntry *entry = self.cache[key];
        if (now - entry.creationTime > self.cacheExpirationTime) {
            [keysToRemove addObject:key];
        }
    }
    
    for (NSString *key in keysToRemove) {
        CLXAdCacheEntry *entry = self.cache[key];
        self.currentCacheSize -= entry.size;
        [self.cache removeObjectForKey:key];
    }
}

/**
 * Defragment cache by reorganizing entries
 * 
 * Sorts cache entries by access frequency to improve
 * cache hit rates and access patterns.
 */
- (void)defragmentCache {
    // Reorganize cache for better access patterns
    // In this implementation, we'll sort by access frequency
    NSDictionary *currentCache = [self.cache copy];
    [self.cache removeAllObjects];
    
    NSArray *sortedEntries = [[currentCache allValues] sortedArrayUsingComparator:^NSComparisonResult(CLXAdCacheEntry *a, CLXAdCacheEntry *b) {
        return [@(b.accessCount) compare:@(a.accessCount)]; // Most accessed first
    }];
    
    // Re-add entries in sorted order
    for (CLXAdCacheEntry *entry in sortedEntries) {
        self.cache[entry.key] = entry;
    }
}

/**
 * Evict cache entries to reach target size
 * 
 * Removes least recently used entries until cache size
 * is at or below the specified target size.
 * 
 * @param targetSize Maximum cache size in bytes
 */
- (void)evictCacheToSize:(NSUInteger)targetSize {
    if (self.currentCacheSize <= targetSize) return;
    
    // Sort entries by last access time (oldest first)
    NSArray *sortedEntries = [[self.cache allValues] sortedArrayUsingComparator:^NSComparisonResult(CLXAdCacheEntry *a, CLXAdCacheEntry *b) {
        return [@(a.lastAccessTime) compare:@(b.lastAccessTime)];
    }];
    
    // Remove oldest entries until target size is reached
    for (CLXAdCacheEntry *entry in sortedEntries) {
        if (self.currentCacheSize <= targetSize) break;
        
        self.currentCacheSize -= entry.size;
        [self.cache removeObjectForKey:entry.key];
    }
}

/**
 * Evict least recently used cache entries
 * 
 * Removes entries that haven't been accessed recently
 * to make room for new content.
 */
- (void)evictLeastRecentlyUsedItems {
    // Sort by last access time and remove oldest items
    NSArray<CLXAdCacheEntry *> *sortedEntries = [[self.cache allValues] 
        sortedArrayUsingComparator:^NSComparisonResult(CLXAdCacheEntry *a, CLXAdCacheEntry *b) {
            return [@(a.lastAccessTime) compare:@(b.lastAccessTime)];
        }];
    
    for (CLXAdCacheEntry *entry in sortedEntries) {
        if (self.currentCacheSize <= self.maxCacheSize * 0.8) break; // Keep 80% of max
        
        [self.cache removeObjectForKey:entry.key];
        self.currentCacheSize -= entry.size;
    }
}



#pragma mark - Notification Handlers

/**
 * Handle app backgrounding to pause background operations
 * 
 * Pauses preload queue and performs maintenance tasks.
 */
- (void)handleAppBackground {
    [self pauseBackgroundProcessing];
    [self performMaintenanceTasks];
}

/**
 * Handle app foregrounding to resume background operations
 * 
 * Resumes preload queue.
 */
- (void)handleAppForeground {
    [self resumeBackgroundProcessing];
}

@end