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
    
    for (CLXAppSessionModel *model in models) {
        // Do not remove current session
        if ([model.id isEqualToString:currentSessionID]) {
            continue;
        }
        
        NSURL *url = [NSURL URLWithString:model.url];
        if (url) {
            NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
            config.timeoutIntervalForRequest = 30.0;
            config.timeoutIntervalForResource = 60.0;
            NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
            
            NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (error) {
                    [self.logger error:[NSString stringWithFormat:@"Failed to end session: %@", error.localizedDescription]];
                } else {
                    [CLXCoreDataManager.shared deleteObject:model];
                }
            }];
            
            [task resume];
        } else {
            [CLXCoreDataManager.shared deleteObject:model];
        }
    }
    
    [CLXCoreDataManager.shared saveContext];
    
    if (completion) {
        completion();
    }
}

@end 