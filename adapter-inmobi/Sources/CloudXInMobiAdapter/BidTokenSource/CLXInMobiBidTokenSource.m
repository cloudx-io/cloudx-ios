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
#import <CloudXCore/CLXSystemInformation.h>
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
    
    // Ensure we're on main thread for InMobi SDK calls
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            // Check if InMobi SDK is initialized
            if (![CLXInMobiInitializer isInitialized]) {
                [self.logger error:@"InMobi SDK not initialized. This may occur if InMobi has not been configured for this app in the CloudX dashboard. Please verify your InMobi adapter configuration includes a valid account_id."];
                
                NSError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed 
                                             description:@"InMobi SDK not initialized"];
                
                if (completion) {
                    completion(nil, error);
                }
                return;
            }
            
            // Prepare extras for InMobi token request with partner info from server config
            NSString *tp = [CLXInMobiInitializer partnerName];
            NSString *tpVer = [CLXSystemInformation shared].sdkVersion;
            
            NSMutableDictionary *extras = [NSMutableDictionary dictionary];
            if (tp) {
                extras[@"tp"] = tp;
            }
            if (tpVer) {
                extras[@"tp-ver"] = tpVer;
            }
            
            [self.logger debug:[NSString stringWithFormat:@"Requesting InMobi token with partner extras - tp: %@, tp-ver: %@", 
                               tp ?: @"(none)", tpVer ?: @"(none)"]];
            
            // Get InMobi bidder token with partner information
            id tokenResponse = [IMSdk getTokenWithExtras:[extras copy] andKeywords:nil];
            
            // InMobi SDK returns the token directly as a string, not in a dictionary
            NSString *token = nil;
            if ([tokenResponse isKindOfClass:[NSString class]]) {
                token = (NSString *)tokenResponse;
            } else if ([tokenResponse isKindOfClass:[NSDictionary class]]) {
                // Fallback: some InMobi SDK versions might return a dictionary
                token = ((NSDictionary *)tokenResponse)[@"token"];
            } else if (tokenResponse != nil) {
                [self.logger warning:[NSString stringWithFormat:@"Unexpected token response type: %@", NSStringFromClass([tokenResponse class])]];
            }
            
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

