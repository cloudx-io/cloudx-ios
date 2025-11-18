#import "CLXMintegralBidTokenSource.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXSettings.h>
// Placeholder for Mintegral SDK
// #import <MTGSDK/MTGSDK.h>
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
        _network = @"mintegral";
    }
    return self;
}

- (void)getTokenWithCompletion:(void (^)(NSDictionary<NSString *, NSString *> * _Nullable,
                                         NSError * _Nullable))completion {
    
    [self.logger debug:@"Getting Mintegral bid token"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            // Check if SDK is initialized
            if (![CLXMintegralInitializer isInitialized]) {
                NSError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed
                                             description:@"Mintegral SDK not initialized"];
                [self.logger error:@"Cannot generate token - Mintegral SDK not initialized. This may occur if Mintegral has not been configured for this app in the CloudX dashboard. Please verify your Mintegral adapter configuration includes a valid app_id."];
                if (completion) completion(nil, error);
                return;
            }
            
            // TODO: Replace with actual Mintegral bid token API
            // NSString *bidToken = [[MTGSDK sharedInstance] getBidToken];
            
            // Placeholder: Generate mock token for testing
            NSString *bidToken = [NSString stringWithFormat:@"MTG_TOKEN_%@", 
                                 [[NSUUID UUID] UUIDString]];
            
            // Get IDFA if available
            NSString *idfa = [[CLXSettings sharedInstance] getIFA];
            
            // Build token dictionary
            NSMutableDictionary *tokenDict = [NSMutableDictionary dictionary];
            
            if (bidToken && bidToken.length > 0) {
                tokenDict[@"bid_token"] = bidToken;
                [self.logger debug:[NSString stringWithFormat:@"Generated bid token: %@", 
                                  [bidToken substringToIndex:MIN(20, bidToken.length)]]];
            } else {
                [self.logger warning:@"Mintegral returned empty bid token"];
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

@end

