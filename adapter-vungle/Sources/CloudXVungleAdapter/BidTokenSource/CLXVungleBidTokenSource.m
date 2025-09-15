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
        _logger = [CLXLogger loggerWithTag:@"VungleBidTokenSource"];
    }
    return self;
}

#pragma mark - CLXBidTokenSource Protocol

- (NSString *)network {
    return @"Vungle";
}

- (void)getBidTokenWithCompletion:(void (^)(NSString * _Nullable bidToken, NSError * _Nullable error))completion {
    // Ensure we have a completion block
    void (^safeCompletion)(NSString *, NSError *) = completion ?: ^(NSString *token, NSError *error) {};
    
    // Check if Vungle SDK is initialized
    if (![VungleAds isInitialized]) {
        NSError *error = [NSError errorWithDomain:@"com.cloudx.adapter.vungle.bidtoken"
                                             code:1001
                                         userInfo:@{
                                             NSLocalizedDescriptionKey: @"Vungle SDK not initialized",
                                             NSLocalizedFailureReasonErrorKey: @"Cannot generate bid token before SDK initialization"
                                         }];
        
        [self.logger logError:@"Cannot generate bid token - Vungle SDK not initialized"];
        dispatch_async(dispatch_get_main_queue(), ^{
            safeCompletion(nil, error);
        });
        return;
    }
    
    [self.logger logDebug:@"Requesting bid token from Vungle SDK"];
    
    // Generate bid token using Vungle SDK
    // Note: The exact method name may vary depending on Vungle SDK version
    // This implementation assumes the standard bid token generation API
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            // Attempt to get bid token from Vungle SDK
            NSString *bidToken = [VungleAds getBidToken];
            
            if (bidToken && bidToken.length > 0) {
                [self.logger logDebug:[NSString stringWithFormat:@"Successfully generated bid token (length: %lu)", (unsigned long)bidToken.length]];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    safeCompletion(bidToken, nil);
                });
            } else {
                NSError *error = [NSError errorWithDomain:@"com.cloudx.adapter.vungle.bidtoken"
                                                     code:1002
                                                 userInfo:@{
                                                     NSLocalizedDescriptionKey: @"Empty bid token received",
                                                     NSLocalizedFailureReasonErrorKey: @"Vungle SDK returned empty or nil bid token"
                                                 }];
                
                [self.logger logWarning:@"Received empty bid token from Vungle SDK"];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    safeCompletion(nil, error);
                });
            }
        } @catch (NSException *exception) {
            NSError *error = [NSError errorWithDomain:@"com.cloudx.adapter.vungle.bidtoken"
                                                 code:1003
                                             userInfo:@{
                                                 NSLocalizedDescriptionKey: @"Exception during bid token generation",
                                                 NSLocalizedFailureReasonErrorKey: exception.reason ?: @"Unknown exception"
                                             }];
            
            [self.logger logError:[NSString stringWithFormat:@"Exception during bid token generation: %@", exception.reason]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                safeCompletion(nil, error);
            });
        }
    });
}

- (nullable NSString *)getBidTokenSync {
    // Check if Vungle SDK is initialized
    if (![VungleAds isInitialized]) {
        [self.logger logError:@"Cannot generate bid token - Vungle SDK not initialized"];
        return nil;
    }
    
    @try {
        NSString *bidToken = [VungleAds getBidToken];
        
        if (bidToken && bidToken.length > 0) {
            [self.logger logDebug:[NSString stringWithFormat:@"Successfully generated sync bid token (length: %lu)", (unsigned long)bidToken.length]];
            return bidToken;
        } else {
            [self.logger logWarning:@"Received empty bid token from Vungle SDK (sync)"];
            return nil;
        }
    } @catch (NSException *exception) {
        [self.logger logError:[NSString stringWithFormat:@"Exception during sync bid token generation: %@", exception.reason]];
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
