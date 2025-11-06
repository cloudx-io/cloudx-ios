//
//  CLXVungleBidTokenSource.m
//  CloudXVungleAdapter
//
//  Created by CloudX Team on 2024-09-14.
//

#import "CLXVungleBidTokenSource.h"

// Conditional import for CloudXCore header
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXSettings.h>
#import <VungleAdsSDK/VungleAdsSDK.h>

@interface CLXVungleBidTokenSource ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXVungleBidTokenSource

#pragma mark - Singleton

+ (instancetype)sharedInstance {
    static CLXVungleBidTokenSource *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (instancetype)createInstance {
    return [[self alloc] init];
}

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"VungleBidTokenSource"];
    }
    return self;
}

#pragma mark - CLXBidTokenSource Protocol

- (NSString *)network {
    return @"Vungle";
}

- (void)getTokenWithCompletion:(void (^)(NSDictionary<NSString *, NSString *> * _Nullable token, NSError * _Nullable error))completion {
    [self.logger debug:@"🔧 [CLXVungleBidTokenSource] Getting Vungle bidding token"];
    
    // Ensure we're on main thread for Vungle SDK calls
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            // Check if Vungle SDK is initialized
            if (![VungleAds isInitialized]) {
                NSError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed 
                                             description:@"Vungle SDK not initialized"];
                
                [self.logger error:@"Cannot generate bid token - Vungle SDK not initialized"];
                if (completion) {
                    completion(nil, error);
                }
                return;
            }
            
            // Get Vungle bidding token
            NSString *bidToken = [VungleAds getBiddingToken];
            NSString *idfa = [[CLXSettings sharedInstance] getIFA];
            [self.logger debug:[NSString stringWithFormat:@"📊 [CLXVungleBidTokenSource] Vungle bidding token: %@ | IDFA from CLXSettings: %@", 
                               bidToken ? @"[RECEIVED]" : @"[NIL]", idfa ? @"[AVAILABLE]" : @"[NIL]"]];
            
            // Create token dictionary with Vungle-specific data
            NSMutableDictionary<NSString *, NSString *> *tokenDict = [NSMutableDictionary dictionary];
            
            if (bidToken && bidToken.length > 0) {
                tokenDict[@"bid_token"] = bidToken;
            }
            
            if (idfa && idfa.length > 0) {
                tokenDict[@"device_ifa"] = idfa;
                [self.logger info:[NSString stringWithFormat:@"🔧 [CLXVungleBidTokenSource] Using centralized IFA in device_ifa: %@", idfa]];
            }
            
            // Add network identifier
            tokenDict[@"network"] = @"vungle";
            
            [self.logger info:[NSString stringWithFormat:@"✅ [CLXVungleBidTokenSource] Token created with %lu keys", (unsigned long)tokenDict.count]];
            
            if (completion) {
                completion([tokenDict copy], nil);
            }
            
        } @catch (NSException *exception) {
            NSError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed 
                                         description:exception.reason ?: @"Unknown exception occurred while getting bid token"];
            
            if (completion) {
                completion(nil, error);
            }
        }
    });
}

- (nullable NSString *)getBiddingTokenSync {
    // Check if Vungle SDK is initialized
    if (![VungleAds isInitialized]) {
        [self.logger error:@"Cannot generate bid token - Vungle SDK not initialized"];
        return nil;
    }
    
    @try {
        NSString *bidToken = [VungleAds getBiddingToken];
        
        if (bidToken && bidToken.length > 0) {
            [self.logger debug:[NSString stringWithFormat:@"Successfully generated sync bid token (length: %lu)", (unsigned long)bidToken.length]];
            return bidToken;
        } else {
            [self.logger error:@"Received empty bid token from Vungle SDK (sync)"];
            return nil;
        }
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"Exception during sync bid token generation: %@", exception.reason]];
        return nil;
    }
}

- (BOOL)isAvailable {
    return [VungleAds isInitialized];
}

- (NSTimeInterval)tokenExpirationTime {
    // Vungle bid tokens typically expire after 30 minutes
    // This is a conservative estimate - actual expiration may vary
    return 1800.0; // 30 minutes in seconds
}

@end
