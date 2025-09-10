//
//  CLXMetaBidTokenSource.m
//  CloudXMetaAdapter
//
//  Created by CLX on 2024-12-19.
//

// Conditional import for internal headers to support both SPM and CocoaPods/Xcode.
#if __has_include(<CloudXMetaAdapter/CLXMetaBidTokenSource.h>)
#import <CloudXMetaAdapter/CLXMetaBidTokenSource.h>
#else
#import "CLXMetaBidTokenSource.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXSettings.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <AdSupport/AdSupport.h>

@interface CLXMetaBidTokenSource ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXMetaBidTokenSource

+ (instancetype)sharedInstance {
    static CLXMetaBidTokenSource *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CLXMetaBidTokenSource alloc] init];
    });
    return sharedInstance;
}

+ (instancetype)createInstance {
    // Return shared instance for consistent token generation
    return [self sharedInstance];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMetaBidTokenSource"];
    }
    return self;
}

#pragma mark - CLXBidTokenSource

- (void)getTokenWithCompletion:(void (^)(NSDictionary<NSString *, NSString *> * _Nullable token, NSError * _Nullable error))completion {
    [self.logger debug:@"🔧 [CLXMetaBidTokenSource] Getting Meta bidder token"];
    
    // Ensure we're on main thread for Meta SDK calls
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            // Get Meta bidder token - this is required for every bid request
            NSString *bidderToken = [FBAdSettings bidderToken];
            NSString *idfa = [[CLXSettings sharedInstance] getIFA];
            [self.logger debug:[NSString stringWithFormat:@"📊 [CLXMetaBidTokenSource] Meta bidder token: %@ | IDFA from CLXSettings: %@", 
                               bidderToken ? @"[RECEIVED]" : @"[NIL]", idfa ? @"[AVAILABLE]" : @"[NIL]"]];
            
            // Create token dictionary with Meta-specific data
            NSMutableDictionary<NSString *, NSString *> *tokenDict = [NSMutableDictionary dictionary];
            
            if (bidderToken && bidderToken.length > 0) {
                tokenDict[@"bidder_token"] = bidderToken;
            }
            
            if (idfa && idfa.length > 0) {
                tokenDict[@"device_ifa"] = idfa;
                [self.logger info:[NSString stringWithFormat:@"🔧 [CLXMetaBidTokenSource] Using centralized IFA in device_ifa: %@", idfa]];
            }
            
            // Add network identifier
            tokenDict[@"network"] = @"audienceNetwork";
            
            [self.logger info:[NSString stringWithFormat:@"✅ [CLXMetaBidTokenSource] Token created with %lu keys", (unsigned long)tokenDict.count]];
            
            if (completion) {
                completion([tokenDict copy], nil);
            }
            
        } @catch (NSException *exception) {
            [self.logger error:[NSString stringWithFormat:@"❌ [CLXMetaBidTokenSource] Exception getting token: %@", exception.reason]];
            
            NSError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed 
                                         description:exception.reason ?: @"Unknown exception occurred while getting bid token"];
            
            if (completion) {
                completion(nil, error);
            }
        }
    });
}

@end
