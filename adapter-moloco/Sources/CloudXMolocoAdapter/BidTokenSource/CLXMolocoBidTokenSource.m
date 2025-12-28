//
//  CLXMolocoBidTokenSource.m
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#if __has_include(<CloudXMolocoAdapter/CLXMolocoBidTokenSource.h>)
#import <CloudXMolocoAdapter/CLXMolocoBidTokenSource.h>
#else
#import "CLXMolocoBidTokenSource.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXSettings.h>
#import <MolocoSDK/MolocoSDK.h>

#if __has_include(<CloudXMolocoAdapter/CLXMolocoInitializer.h>)
#import <CloudXMolocoAdapter/CLXMolocoInitializer.h>
#else
#import "CLXMolocoInitializer.h"
#endif

@interface CLXMolocoBidTokenSource ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXMolocoBidTokenSource

+ (instancetype)sharedInstance {
    static CLXMolocoBidTokenSource *sharedInstance = nil;
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
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMolocoBidTokenSource"];
        _network = @"moloco";
    }
    return self;
}

- (void)getTokenWithCompletion:(void (^)(NSDictionary<NSString *, NSString *> * _Nullable, 
                                         NSError * _Nullable))completion {
    
    [self.logger debug:@"Getting bid token"];
    
    // IMPORTANT: Must use background queue, NOT main queue.
    // Bid token generation can be a blocking call that acquires internal locks.
    // When another SDK concurrently calls the same method, this can take several seconds.
    // Calling on main thread causes UI freeze/ANR.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            if (![CLXMolocoInitializer isInitialized]) {
                NSError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed
                                             description:@"Moloco SDK not initialized"];
                [self.logger error:@"Cannot generate token - Moloco SDK not initialized. This may occur if Moloco has not been configured for this app in the CloudX dashboard. Please verify your Moloco adapter configuration includes a valid app_key."];
                if (completion) completion(nil, error);
                return;
            }
            
            // Get token from Moloco SDK
            // Note: Update with actual Moloco SDK token generation API
            // This is a placeholder - adjust based on actual Moloco SDK documentation
            NSString *bidToken = [MolocoSDK getBidToken];
            NSString *idfa = [[CLXSettings sharedInstance] getIFA];
            
            NSMutableDictionary *tokenDict = [NSMutableDictionary dictionary];
            
            if (bidToken && bidToken.length > 0) {
                tokenDict[@"bid_token"] = bidToken;
                [self.logger debug:[NSString stringWithFormat:@"Generated bid token: %@", 
                                   [bidToken substringToIndex:MIN(10, bidToken.length)]]];
            } else {
                [self.logger warn:@"Bid token is empty"];
            }
            
            if (idfa && idfa.length > 0) {
                tokenDict[@"device_ifa"] = idfa;
                [self.logger debug:@"Added IDFA to token"];
            }
            
            tokenDict[@"network"] = self.network;
            
            [self.logger info:[NSString stringWithFormat:@"Token generated with %lu keys", 
                              (unsigned long)tokenDict.count]];
            
            if (completion) completion([tokenDict copy], nil);
            
        } @catch (NSException *exception) {
            NSError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed
                                         description:exception.reason ?: @"Token generation failed"];
            [self.logger error:[NSString stringWithFormat:@"Token generation failed: %@", exception.reason]];
            if (completion) completion(nil, error);
        }
    });
}

@end

