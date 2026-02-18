#import "CLXMintegralBidTokenSource.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <MTGSDKBidding/MTGBiddingSDK.h>
#import "CLXMintegralInitializer.h"

@interface CLXMintegralBidTokenSource ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXMintegralBidTokenSource

+ (instancetype)sharedInstance {
    static CLXMintegralBidTokenSource *sharedInstance = nil;
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
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMintegralBidTokenSource"];
    }
    return self;
}

- (void)getTokenWithCompletion:(void (^)(NSDictionary<NSString *, NSString *> * _Nullable,
                                         NSError * _Nullable))completion {
    [self.logger debug:@"Getting Mintegral bid token"];

    // IMPORTANT: Must use background queue, NOT main queue.
    // Bid token generation can be a blocking call that acquires internal locks.
    // When another SDK concurrently calls the same method, this can take several seconds.
    // Calling on main thread causes UI freeze/ANR.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            if (![CLXMintegralInitializer isInitialized]) {
                NSError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed
                                             description:@"Mintegral SDK not initialized"];
                [self.logger error:@"Cannot generate token - Mintegral SDK not initialized. This may occur if Mintegral has not been configured for this app in the CloudX dashboard. Please verify your Mintegral adapter configuration includes a valid app_id."];
                if (completion) completion(nil, error);
                return;
            }

            // AppLovin uses buyerUIDWithDictionary: passing placementId/unitId/adType
            // when available, falling back to basic buyerUID. Our protocol doesn't
            // carry ad-unit context, so we use the basic variant; the server adds
            // placement/unit IDs to the bid request on its side.
            NSString *bidToken = [MTGBiddingSDK buyerUID];

            if (!bidToken || bidToken.length == 0) {
                [self.logger warn:@"Mintegral returned empty bid token"];
                if (completion) completion(nil, nil);
                return;
            }

            [self.logger debug:[NSString stringWithFormat:@"Generated bid token (prefix): %@...",
                              [bidToken substringToIndex:MIN(20, bidToken.length)]]];

            NSDictionary *tokenDict = @{@"bid_token": bidToken};

            [self.logger info:@"Mintegral token generated"];

            if (completion) completion(tokenDict, nil);

        } @catch (NSException *exception) {
            NSError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed
                                         description:exception.reason ?: @"Mintegral token generation failed"];
            [self.logger error:[NSString stringWithFormat:@"Token generation exception: %@", exception.reason]];
            if (completion) completion(nil, error);
        }
    });
}

@end
