/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file MetricsTracker.m
 * @brief Metrics tracker implementation
 */

#import <CloudXCore/CLXMetricsTracker.h>
#import <CloudXCore/CLXCloudXDatabase.h>
#import <CloudXCore/CLXSession.h>
#import <CloudXCore/CLXAppSessionService.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXDIContainer.h>
#import <CloudXCore/CLXMetricsNetworkService.h>
#import <CloudXCore/CLXAppSession.h>
#import <CloudXCore/CLXDaoProtocols.h>

@interface CLXMetricsTracker ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong) CLXCloudXDatabase *database;
@end

@implementation CLXMetricsTracker

+ (instancetype)shared {
    static CLXMetricsTracker *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"MetricsTracker"];
        _database = [CLXCloudXDatabase sharedInstance];
    }
    return self;
}


- (void)trySendPendingMetricsWithCompletion:(void (^)(void))completion {
    // Fetch SQLite sessions from database
    NSArray<CLXSession *> *sessions = [self.database.sessionDao findAll];
    
    // Get current session to filter it out - use DIContainer singleton like Swift SDK
    CLXAppSessionService *appSessionService = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXAppSessionService class]];
    CLXAppSession *currentSession = (CLXAppSession *)appSessionService.currentSession;
    NSString *currentSessionID = currentSession.sessionID;
    
    // Get the metrics network service from DI container
    CLXMetricsNetworkService *metricsNetworkService = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsNetworkService class]];
    
    NSInteger totalRequests = 0;
    __block NSInteger completedRequests = 0;
    
    for (CLXSession *session in sessions) {
        // Do not remove current session
        if ([session.sessionId isEqualToString:currentSessionID]) {
            continue;
        }
        
        if (session.url && session.url.length > 0) {
            totalRequests++;
            
            [self.logger debug:[NSString stringWithFormat:@"Sending pending metrics for session: %@", session.sessionId]];
            
            // TODO: Update network service to accept CLXSession and CLXPerformanceMetric instead of Core Data models
            // For now, we'll mark the session as processed and delete it
            // The network service integration will be updated in a separate phase
            [self.logger debug:[NSString stringWithFormat:@"Marking session as processed (network service will be updated): %@", session.sessionId]];
            
            // Simulate successful processing and delete the session
            completedRequests++;
            [self.database.sessionDao deleteById:session.sessionId];
            
            // Check if all requests are complete
            if (completedRequests == totalRequests) {
                if (completion) {
                    completion();
                }
            }
        } else {
            // Invalid URL, just delete the session
            [self.logger error:[NSString stringWithFormat:@"Invalid metrics URL for session: %@, deleting session", session.sessionId]];
            [self.database.sessionDao deleteById:session.sessionId];
        }
    }
    
    // If no requests were made, complete immediately
    if (totalRequests == 0) {
        if (completion) {
            completion();
        }
    }
}

@end 