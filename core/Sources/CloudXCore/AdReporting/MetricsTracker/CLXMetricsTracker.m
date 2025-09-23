/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file MetricsTracker.m
 * @brief Metrics tracker implementation
 */

#import <CloudXCore/CLXMetricsTracker.h>
#import <CloudXCore/CLXAppSessionModel.h>
#import <CloudXCore/CLXAppSessionService.h>
#import <CloudXCore/CLXAppSessionServiceImplementation.h>
#import <CloudXCore/CLXCoreDataManager.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXDIContainer.h>
#import <CloudXCore/CLXMetricsNetworkService.h>
#import <CloudXCore/CLXAppSession.h>

@interface CLXMetricsTracker ()
@property (nonatomic, strong) CLXLogger *logger;
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
    }
    return self;
}

- (void)trySendPendingMetricsWithCompletion:(void (^)(void))completion {
    // Fetch AppSessionModel from CoreDataManager
    NSArray<CLXAppSessionModel *> *models = [CLXCoreDataManager.shared fetch:[CLXAppSessionModel class]];
    
    // Get current session to filter it out - use DIContainer singleton like Swift SDK
    id<CLXAppSessionService> appSessionService = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXAppSessionServiceImplementation class]];
    CLXAppSession *currentSession = (CLXAppSession *)appSessionService.currentSession;
    NSString *currentSessionID = currentSession.sessionID;
    
    // Get the metrics network service from DI container
    CLXMetricsNetworkService *metricsNetworkService = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsNetworkService class]];
    
    NSInteger totalRequests = 0;
    __block NSInteger completedRequests = 0;
    
    for (CLXAppSessionModel *model in models) {
        // Do not remove current session
        if ([model.id isEqualToString:currentSessionID]) {
            continue;
        }
        
        if (model.url && model.url.absoluteString.length > 0) {
            totalRequests++;
            
            [self.logger debug:[NSString stringWithFormat:@"Sending pending metrics for session: %@", model.id]];
            
            // Use CLXMetricsNetworkService instead of direct URL calls
            [metricsNetworkService trackEndSessionWithSession:model completion:^(BOOL success, NSError * _Nullable error) {
                completedRequests++;
                
                if (success) {
                    [self.logger debug:[NSString stringWithFormat:@"Successfully sent metrics for session: %@", model.id]];
                    [CLXCoreDataManager.shared deleteObject:model];
                } else {
                    [self.logger error:[NSString stringWithFormat:@"Failed to send metrics for session %@: %@", model.id, error.localizedDescription ?: @"Unknown error"]];
                }
                
                // Check if all requests are complete
                if (completedRequests == totalRequests) {
                    [CLXCoreDataManager.shared saveContext];
                    
                    if (completion) {
                        completion();
                    }
                }
            }];
        } else {
            // Invalid URL, just delete the model
            [self.logger error:[NSString stringWithFormat:@"Invalid metrics URL for session: %@, deleting model", model.id]];
            [CLXCoreDataManager.shared deleteObject:model];
        }
    }
    
    // If no requests were made, complete immediately
    if (totalRequests == 0) {
        [CLXCoreDataManager.shared saveContext];
        
        if (completion) {
            completion();
        }
    }
}

@end 