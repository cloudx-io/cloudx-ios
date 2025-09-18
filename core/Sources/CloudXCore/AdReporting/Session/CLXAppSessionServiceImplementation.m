#import <CloudXCore/CLXAppSessionServiceImplementation.h>
#import <CloudXCore/CLXAppSessionService.h>
#import <CloudXCore/CLXAppSession.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXCoreDataManager.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>

@interface CLXAppSessionServiceImplementation ()
@property (nonatomic, strong) CLXAppSession *currentSession;
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXAppSessionServiceImplementation

- (instancetype)initWithSessionID:(NSString *)sessionID
                           appKey:(NSString *)appKey
                              url:(NSString *)url {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"AppSessionService"];
        
        // Create URL from string
        NSURL *sessionURL = [NSURL URLWithString:url];
        if (!sessionURL) {
            // Fallback to stored metrics URL from SDK response
            NSString *fallbackURL = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreMetricsUrlKey] ?: @"";
            sessionURL = [NSURL URLWithString:fallbackURL];
        }
        
        // Create current session
        _currentSession = [[CLXAppSession alloc] initWithSessionID:sessionID
                                                           url:sessionURL
                                                         appKey:appKey];
    }
    return self;
}

#pragma mark - AppSessionService Protocol

- (NSTimeInterval)sessionDuration {
    return fabs([self.currentSession.startDate timeIntervalSinceNow]);
}

- (CLXAppSession *)currentSession {
    return _currentSession;
}

- (void)addSpendWithPlacementID:(NSString *)placementID spend:(double)spend {
    [self.currentSession addSpendWithPlacementID:placementID spend:spend];
}

- (void)addClickWithPlacementID:(NSString *)placementID {
    [self.currentSession addClickWithPlacementID:placementID];
}

- (void)addImpressionWithPlacementID:(NSString *)placementID {
    [self.currentSession addImpressionWithPlacementID:placementID];
}

- (void)addCloseWithPlacementID:(NSString *)placementID latency:(double)latency {
    [self.currentSession addCloseWithPlacementID:placementID latency:latency];
}

- (void)adFailedToLoadWithPlacementID:(NSString *)placementID {
    [self.currentSession adFailedToLoadWithPlacementID:placementID];
}

- (void)bidLoadedWithPlacementID:(NSString *)placementID latency:(double)latency {
    [self.currentSession bidLoadedWithPlacementID:placementID latency:latency];
}

- (void)adLoadedWithPlacementID:(NSString *)placementID latency:(double)latency {
    [self.currentSession adLoadedWithPlacementID:placementID latency:latency];
}

@end 