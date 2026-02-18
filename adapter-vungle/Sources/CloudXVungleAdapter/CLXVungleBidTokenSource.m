//
//  CLXVungleBidTokenSource.m
//  CloudXVungleAdapter
//

#import "CLXVungleBidTokenSource.h"

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

#import <VungleAdsSDK/VungleAdsSDK.h>

@interface CLXVungleBidTokenSource ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXVungleBidTokenSource

+ (instancetype)sharedInstance {
    static CLXVungleBidTokenSource *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (instancetype)createInstance {
    return [self sharedInstance];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXVungleBidTokenSource"];
    }
    return self;
}

#pragma mark - CLXBidTokenSource Protocol

- (void)getTokenWithCompletion:(void (^)(NSDictionary<NSString *, NSString *> * _Nullable token, NSError * _Nullable error))completion {
    [self.logger debug:@"Getting Vungle bidder token"];

    // IMPORTANT: Must use background queue, NOT main queue.
    // [VungleAds getBiddingToken] is a blocking call that acquires an internal lock.
    // When another SDK concurrently holds the lock, this can take several seconds.
    // Calling on main thread causes UI freeze/ANR.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *bidToken = [VungleAds getBiddingToken];
        [self.logger debug:[NSString stringWithFormat:@"Vungle bidder token: %@",
                                 bidToken ? @"[RECEIVED]" : @"[NIL]"]];

        NSDictionary<NSString *, NSString *> *tokenDict = nil;
        if (bidToken && bidToken.length > 0) {
            tokenDict = @{@"bid_token": bidToken};
        }

        completion(tokenDict, nil);
    });
}

@end
