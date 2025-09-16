#import <CloudXCore/CLXEnvironmentConfig.h>

// MARK: - Static Configuration Maps

/**
 * Development environment configuration
 */
static NSDictionary<NSString *, NSString *> *kDevEnvironmentConfig = nil;

/**
 * Staging environment configuration  
 */
static NSDictionary<NSString *, NSString *> *kStagingEnvironmentConfig = nil;

/**
 * Production environment configuration
 */
static NSDictionary<NSString *, NSString *> *kProductionEnvironmentConfig = nil;

// MARK: - Configuration Keys

static NSString *const kConfigKeyAuctionBase = @"auction_base";
static NSString *const kConfigKeyMetricsBase = @"metrics_base";
static NSString *const kConfigKeyTrackerBase = @"tracker_base";
static NSString *const kConfigKeyInitBase = @"init_base";
static NSString *const kConfigKeyGeoBase = @"geo_base";

static NSString *const kConfigKeyAuctionPath = @"auction_path";
static NSString *const kConfigKeyMetricsPath = @"metrics_path";
static NSString *const kConfigKeyEventPath = @"event_path";
static NSString *const kConfigKeyTrackerBulkPath = @"tracker_bulk_path";
static NSString *const kConfigKeyTrackerRillPath = @"tracker_rill_path";
static NSString *const kConfigKeyInitPath = @"init_path";

static NSString *const kConfigKeyDefaultParams = @"default_params";
static NSString *const kConfigKeyDebugParams = @"debug_params";

// MARK: - User Defaults Key for Debug Environment Selection

static NSString *const kCLXDebugEnvironmentKey = @"CLXDebugEnvironment";

@interface CLXEnvironmentConfig ()
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *currentConfig;
@end

@implementation CLXEnvironmentConfig

+ (void)initialize {
    if (self == [CLXEnvironmentConfig class]) {
        // Initialize static configuration dictionaries
        kDevEnvironmentConfig = @{
            // Base URLs
            kConfigKeyAuctionBase: @"https://au-dev.cloudx.io",
            kConfigKeyMetricsBase: @"https://ads.cloudx.io",
            kConfigKeyTrackerBase: @"https://tracker-dev.cloudx.io",
            kConfigKeyInitBase: @"https://pro-dev.cloudx.io",
            kConfigKeyGeoBase: @"https://geoip.cloudx.io",
            
            // Paths
            kConfigKeyAuctionPath: @"/openrtb2/auction",
            kConfigKeyMetricsPath: @"/metrics",
            kConfigKeyEventPath: @"/event",
            kConfigKeyTrackerBulkPath: @"/t/bulk",
            kConfigKeyTrackerRillPath: @"/t/",
            kConfigKeyInitPath: @"/sdk",
            
            // Default parameters
            kConfigKeyDefaultParams: @"?a=test",
            kConfigKeyDebugParams: @"?debug=true"
        };
        
        kStagingEnvironmentConfig = @{
            // Base URLs
            kConfigKeyAuctionBase: @"https://au-stage.cloudx.io",
            kConfigKeyMetricsBase: @"https://ads.cloudx.io",
            kConfigKeyTrackerBase: @"https://tracker-stage.cloudx.io",
            kConfigKeyInitBase: @"https://pro-stage.cloudx.io",
            kConfigKeyGeoBase: @"https://geoip.cloudx.io",
            
            // Paths
            kConfigKeyAuctionPath: @"/openrtb2/auction",
            kConfigKeyMetricsPath: @"/metrics",
            kConfigKeyEventPath: @"/event",
            kConfigKeyTrackerBulkPath: @"/t/bulk",
            kConfigKeyTrackerRillPath: @"/t/",
            kConfigKeyInitPath: @"/sdk",
            
            // Default parameters
            kConfigKeyDefaultParams: @"?a=test",
            kConfigKeyDebugParams: @"?debug=true"
        };
        
        kProductionEnvironmentConfig = @{
            // Base URLs
            kConfigKeyAuctionBase: @"https://au.cloudx.io",
            kConfigKeyMetricsBase: @"https://ads.cloudx.io",
            kConfigKeyTrackerBase: @"https://tracker.cloudx.io",
            kConfigKeyInitBase: @"https://pro.cloudx.io",
            kConfigKeyGeoBase: @"https://geoip.cloudx.io",
            
            // Paths
            kConfigKeyAuctionPath: @"/openrtb2/auction",
            kConfigKeyMetricsPath: @"/metrics",
            kConfigKeyEventPath: @"/event",
            kConfigKeyTrackerBulkPath: @"/t/bulk",
            kConfigKeyTrackerRillPath: @"/t/",
            kConfigKeyInitPath: @"/sdk",
            
            // Default parameters
            kConfigKeyDefaultParams: @"?a=test",
            kConfigKeyDebugParams: @""  // No debug params in production
        };
    }
}

+ (instancetype)shared {
    static CLXEnvironmentConfig *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CLXEnvironmentConfig alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self selectEnvironmentConfiguration];
    }
    return self;
}

- (void)selectEnvironmentConfiguration {
#ifdef DEBUG
    // In DEBUG mode, check user defaults for environment preference
    NSString *debugEnvironment = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXDebugEnvironmentKey];
    
    if ([debugEnvironment isEqualToString:@"dev"]) {
        _currentConfig = kDevEnvironmentConfig;
        _environmentName = @"development";
        _isDebugEnvironment = YES;
    } else if ([debugEnvironment isEqualToString:@"staging"]) {
        _currentConfig = kStagingEnvironmentConfig;
        _environmentName = @"staging";
        _isDebugEnvironment = YES;
    } else {
        // Default to dev in DEBUG if no preference set
        _currentConfig = kDevEnvironmentConfig;
        _environmentName = @"development";
        _isDebugEnvironment = YES;
    }
#else
    // Production build always uses production config
    _currentConfig = kProductionEnvironmentConfig;
    _environmentName = @"production";
    _isDebugEnvironment = NO;
#endif
}

// MARK: - Public API for Environment Selection (DEBUG only)

+ (void)setDebugEnvironment:(NSString *)environment {
#ifdef DEBUG
    // Store the environment preference (even if invalid)
    [[NSUserDefaults standardUserDefaults] setObject:environment forKey:kCLXDebugEnvironmentKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Force re-initialization of shared instance to pick up the change
    [[CLXEnvironmentConfig shared] selectEnvironmentConfiguration];
#endif
}

+ (NSArray<NSString *> *)availableDebugEnvironments {
#ifdef DEBUG
    return @[@"dev", @"staging"];
#else
    return @[];
#endif
}

// MARK: - Complete Endpoint URLs

- (NSString *)auctionEndpointURL {
    return [NSString stringWithFormat:@"%@%@", 
            self.currentConfig[kConfigKeyAuctionBase],
            self.currentConfig[kConfigKeyAuctionPath]];
}

- (NSString *)metricsEndpointURL {
    return [NSString stringWithFormat:@"%@%@%@", 
            self.currentConfig[kConfigKeyMetricsBase],
            self.currentConfig[kConfigKeyMetricsPath],
            self.currentConfig[kConfigKeyDefaultParams]];
}

- (NSString *)eventTrackingEndpointURL {
    return [NSString stringWithFormat:@"%@%@%@", 
            self.currentConfig[kConfigKeyMetricsBase],
            self.currentConfig[kConfigKeyEventPath],
            self.currentConfig[kConfigKeyDefaultParams]];
}

- (NSString *)trackerBulkEndpointURL {
    NSString *debugParams = self.isDebugEnvironment ? self.currentConfig[kConfigKeyDebugParams] : @"";
    return [NSString stringWithFormat:@"%@%@%@", 
            self.currentConfig[kConfigKeyTrackerBase],
            self.currentConfig[kConfigKeyTrackerBulkPath],
            debugParams];
}

- (NSString *)trackerRillBaseURL {
    return [NSString stringWithFormat:@"%@%@", 
            self.currentConfig[kConfigKeyTrackerBase],
            self.currentConfig[kConfigKeyTrackerRillPath]];
}

- (NSString *)initializationEndpointURL {
    return [NSString stringWithFormat:@"%@%@", 
            self.currentConfig[kConfigKeyInitBase],
            self.currentConfig[kConfigKeyInitPath]];
}

- (NSString *)geoEndpointURL {
    return self.currentConfig[kConfigKeyGeoBase];
}

@end