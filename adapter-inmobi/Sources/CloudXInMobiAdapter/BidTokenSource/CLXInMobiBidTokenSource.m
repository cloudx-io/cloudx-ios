//
//  CLXInMobiBidTokenSource.m
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#if __has_include(<CloudXInMobiAdapter/CLXInMobiBidTokenSource.h>)
#import <CloudXInMobiAdapter/CLXInMobiBidTokenSource.h>
#else
#import "CLXInMobiBidTokenSource.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <InMobiSDK/InMobiSDK.h>

#if __has_include(<CloudXInMobiAdapter/CLXInMobiInitializer.h>)
#import <CloudXInMobiAdapter/CLXInMobiInitializer.h>
#else
#import "../Initializers/CLXInMobiInitializer.h"
#endif

@interface CLXInMobiBidTokenSource ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXInMobiBidTokenSource

+ (instancetype)sharedInstance {
    static CLXInMobiBidTokenSource *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CLXInMobiBidTokenSource alloc] init];
    });
    return sharedInstance;
}

+ (instancetype)createInstance {
    return [self sharedInstance];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXInMobiBidTokenSource"];
    }
    return self;
}

#pragma mark - CLXBidTokenSource

- (void)getTokenWithCompletion:(void (^)(NSDictionary<NSString *, NSString *> * _Nullable token, NSError * _Nullable error))completion {
    [self.logger debug:@"Getting InMobi bidder token"];
    
    // IMPORTANT: Must use background queue, NOT main queue.
    // Bid token generation can be a blocking call that acquires internal locks.
    // When another SDK concurrently calls the same method, this can take several seconds.
    // Calling on main thread causes UI freeze/ANR.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Check if InMobi SDK is initialized
        if (![CLXInMobiInitializer isInitialized]) {
            [self.logger error:@"InMobi SDK not initialized. This may occur if InMobi has not been configured for this app in the CloudX dashboard. Please verify your InMobi adapter configuration includes a valid account_id."];

            NSError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed
                                         description:@"InMobi SDK not initialized"];

            completion(nil, error);
            return;
        }

        NSDictionary *extras = [CLXInMobiInitializer extras];
        NSString *token = [IMSdk getTokenWithExtras:extras andKeywords:nil];

        [self.logger debug:[NSString stringWithFormat:@"InMobi bidder token: %@",
                           token ? @"[RECEIVED]" : @"[NIL]"]];

        NSDictionary<NSString *, NSString *> *result = nil;
        if (token && token.length > 0) {
            result = @{@"bid_token": token};
        }

        completion(result, nil);
    });
}

@end

