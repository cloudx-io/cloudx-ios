#import "CLXMintegralBidTokenSource.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXSettings.h>
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
        _network = @"mintegral";
    }
    return self;
}

- (void)getTokenWithCompletion:(void (^)(NSDictionary<NSString *, NSString *> * _Nullable, 
                                         NSError * _Nullable))completion {
    
    [self.logger debug:@"Getting bid token"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            if (![CLXMintegralInitializer isInitialized]) {
                NSError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed
                                             description:@"SDK not initialized"];
                [self.logger error:@"Cannot generate token - SDK not initialized"];
                if (completion) completion(nil, error);
                return;
            }
            
            NSString *bidToken = [[MTGBiddingSDK sharedInstance] buyerUID];
            NSString *idfa = [[CLXSettings sharedInstance] getIFA];
            
            NSMutableDictionary *tokenDict = [NSMutableDictionary dictionary];
            
            if (bidToken && bidToken.length > 0) {
                tokenDict[@"bid_token"] = bidToken;
            }
            
            if (idfa && idfa.length > 0) {
                tokenDict[@"device_ifa"] = idfa;
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

