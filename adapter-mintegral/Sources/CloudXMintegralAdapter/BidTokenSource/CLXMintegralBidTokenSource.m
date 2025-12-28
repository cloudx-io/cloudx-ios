#import "CLXMintegralBidTokenSource.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXAdTrackingService.h>
#import <MTGSDK/MTGSDK.h>
#import <MTGSDKBidding/MTGBiddingSDK.h>
#import "CLXMintegralInitializer.h"

// Mintegral Ad Type enum for buyerUIDWithDictionary
typedef NS_ENUM(NSInteger, MintegralAdType) {
    MintegralIntersitialAd = 1,
    MintegralRewardVideoAd = 2,
    MintegralBannerAd = 6,
    MintegralSplashAd = 7,
    MintegralNativeAd = 8,
};

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
        _network = @"mintegral";
    }
    return self;
}

- (void)getTokenWithCompletion:(void (^)(NSDictionary<NSString *, NSString *> * _Nullable,
                                         NSError * _Nullable))completion {
    // Use default implementation without ad info
    [self getTokenWithPlacementId:nil unitId:nil adType:nil completion:completion];
}

- (void)getTokenWithPlacementId:(nullable NSString *)placementId
                         unitId:(nullable NSString *)unitId
                         adType:(nullable NSNumber *)adType
                     completion:(void (^)(NSDictionary<NSString *, NSString *> * _Nullable,
                                         NSError * _Nullable))completion {
    
    [self.logger debug:@"Getting Mintegral bid token"];
    
    // IMPORTANT: Must use background queue, NOT main queue.
    // Bid token generation can be a blocking call that acquires internal locks.
    // When another SDK concurrently calls the same method, this can take several seconds.
    // Calling on main thread causes UI freeze/ANR.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            // Check if SDK is initialized
            if (![CLXMintegralInitializer isInitialized]) {
                NSError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed
                                             description:@"Mintegral SDK not initialized"];
                [self.logger error:@"Cannot generate token - Mintegral SDK not initialized. This may occur if Mintegral has not been configured for this app in the CloudX dashboard. Please verify your Mintegral adapter configuration includes a valid app_id."];
                if (completion) completion(nil, error);
                return;
            }
            
            NSString *bidToken = nil;
            
            // Use enhanced buyerUIDWithDictionary if we have ad info (matching AppLovin)
            if (placementId.length > 0 && unitId.length > 0 && adType != nil) {
                NSDictionary *bidInfo = @{
                    @"placementId": placementId ?: @"",
                    @"unitId": unitId ?: @"",
                    @"adType": adType
                };
                bidToken = [MTGBiddingSDK buyerUIDWithDictionary:bidInfo];
                [self.logger debug:[NSString stringWithFormat:@"Using enhanced bid token with adType: %@", adType]];
            } else {
                // Fallback to basic buyerUID
                bidToken = [MTGBiddingSDK buyerUID];
                [self.logger debug:@"Using basic bid token"];
            }
            
            if (!bidToken || bidToken.length == 0) {
                [self.logger warn:@"Mintegral returned empty bid token"];
                bidToken = @""; // Use empty string instead of nil
            } else {
                [self.logger debug:[NSString stringWithFormat:@"Generated bid token (prefix): %@...", 
                                  [bidToken substringToIndex:MIN(20, bidToken.length)]]];
            }
            
            // Get IDFA if available
            NSString *idfa = [CLXAdTrackingService getIDFA];
            
            // Build token dictionary
            NSMutableDictionary *tokenDict = [NSMutableDictionary dictionary];
            
            if (bidToken && bidToken.length > 0) {
                tokenDict[@"bid_token"] = bidToken;
            }
            
            if (idfa && idfa.length > 0) {
                tokenDict[@"device_ifa"] = idfa;
            }
            
            tokenDict[@"network"] = self.network;
            tokenDict[@"sdk_version"] = [CLXMintegralInitializer sdkVersion];
            
            [self.logger info:[NSString stringWithFormat:@"Mintegral token generated with %lu keys",
                              (unsigned long)tokenDict.count]];
            
            if (completion) completion([tokenDict copy], nil);
            
        } @catch (NSException *exception) {
            NSError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed
                                         description:exception.reason ?: @"Mintegral token generation failed"];
            [self.logger error:[NSString stringWithFormat:@"Token generation exception: %@", exception.reason]];
            if (completion) completion(nil, error);
        }
    });
}

#pragma mark - Ad Type Helpers

+ (NSNumber *)adTypeForBanner {
    return @(MintegralBannerAd);
}

+ (NSNumber *)adTypeForInterstitial {
    return @(MintegralIntersitialAd);
}

+ (NSNumber *)adTypeForRewarded {
    return @(MintegralRewardVideoAd);
}

+ (NSNumber *)adTypeForNative {
    return @(MintegralNativeAd);
}

+ (NSNumber *)adTypeForSplash {
    return @(MintegralSplashAd);
}

@end

