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
#import <CloudXCore/CLXSettings.h>
#import <InMobiSDK/InMobiSDK.h>

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
    
    // Ensure we're on main thread for InMobi SDK calls
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            // Check if InMobi SDK is initialized
            if (![IMSdk isSDKInitialized]) {
                [self.logger error:@"InMobi SDK not initialized"];
                
                NSError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed 
                                             description:@"InMobi SDK not initialized"];
                
                if (completion) {
                    completion(nil, error);
                }
                return;
            }
            
            // Get InMobi bidder token
            NSDictionary *tokenDict = [IMSdk getToken];
            NSString *token = tokenDict[@"token"];
            NSString *idfa = [[CLXSettings sharedInstance] getIFA];
            
            [self.logger debug:[NSString stringWithFormat:@"InMobi bidder token: %@ | IDFA from CLXSettings: %@", 
                               token ? @"[RECEIVED]" : @"[NIL]", idfa ? @"[AVAILABLE]" : @"[NIL]"]];
            
            // Create token dictionary with InMobi-specific data
            NSMutableDictionary<NSString *, NSString *> *result = [NSMutableDictionary dictionary];
            
            if (token && token.length > 0) {
                result[@"bid_token"] = token;
            }
            
            if (idfa && idfa.length > 0) {
                result[@"device_ifa"] = idfa;
                [self.logger info:[NSString stringWithFormat:@"Using centralized IFA in device_ifa: %@", idfa]];
            }
            
            // Add network identifier
            result[@"network"] = @"inmobi";
            
            [self.logger info:[NSString stringWithFormat:@"Token created with %lu keys", (unsigned long)result.count]];
            
            if (completion) {
                completion([result copy], nil);
            }
            
        } @catch (NSException *exception) {
            [self.logger error:[NSString stringWithFormat:@"Exception getting token: %@", exception.reason]];
            
            NSError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed 
                                         description:exception.reason ?: @"Unknown exception occurred while getting bid token"];
            
            if (completion) {
                completion(nil, error);
            }
        }
    });
}

@end

