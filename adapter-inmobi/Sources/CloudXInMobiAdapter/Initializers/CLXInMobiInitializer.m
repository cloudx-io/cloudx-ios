//
//  CLXInMobiInitializer.m
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#if __has_include(<CloudXInMobiAdapter/CLXInMobiInitializer.h>)
#import <CloudXInMobiAdapter/CLXInMobiInitializer.h>
#else
#import "CLXInMobiInitializer.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXSystemInformation.h>
#import <InMobiSDK/InMobiSDK.h>

@interface CLXInMobiInitializer ()
+ (CLXLogger *)logger;
@end

@implementation CLXInMobiInitializer

static BOOL CLXInMobiSDKInitialized = NO;
static NSString *partnerName = nil;

+ (CLXLogger *)logger {
    static CLXLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[CLXLogger alloc] initWithCategory:@"CLXInMobiInitializer"];
    });
    return logger;
}

+ (BOOL)isInitialized {
    return CLXInMobiSDKInitialized;
}

+ (NSDictionary<NSString *, NSString *> *)extras {
    NSMutableDictionary *extras = [NSMutableDictionary dictionary];
    if (partnerName) {
        extras[@"tp"] = partnerName;
    }
    NSString *tpVer = [CLXSystemInformation shared].sdkVersion;
    if (tpVer) {
        extras[@"tp-ver"] = tpVer;
    }
    return [extras copy];
}

+ (instancetype)createInstance {
    return [[CLXInMobiInitializer alloc] init];
}

+ (NSString *)sdkVersion {
    NSString *version = [IMSdk getVersion];
    return version ?: @"unknown";
}

- (void)initializeWithConfig:(nullable CLXBidderConfig *)config
                    testMode:(BOOL)testMode
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion {

    if (CLXInMobiSDKInitialized) {
        [[CLXInMobiInitializer logger] debug:@"InMobi SDK already initialized"];
        completion(YES, nil);
        return;
    }

    [[CLXInMobiInitializer logger] debug:[NSString stringWithFormat:@"Initializing InMobi SDK adapter (testMode: %@)", testMode ? @"YES" : @"NO"]];

    // Extract configuration from initData
    NSString *accountID = nil;
    if (config && config.initializationData) {
        accountID = config.initializationData[@"accountId"];
        partnerName = config.initializationData[@"tp"];
    }

    [[CLXInMobiInitializer logger] info:[NSString stringWithFormat:@"Initializing with account ID: %@", accountID ?: @"nil"]];

    if (!accountID || accountID.length == 0) {
        [[CLXInMobiInitializer logger] error:@"InMobi account ID not provided in configuration"];
        CLXError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInvalidServerExtras
                                      description:@"InMobi account ID is required"];
        completion(NO, error);
        return;
    }

    // Debug mode only works on simulators
    [IMUnifiedIdService enableDebugMode:testMode];

    // InMobi SDK reads IAB consent strings (TCF/US Privacy) from UserDefaults automatically
    [IMSdk initWithAccountID:accountID consentDictionary:@{} andCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            [[CLXInMobiInitializer logger] error:[NSString stringWithFormat:@"InMobi SDK initialization failed: %@", error.localizedDescription]];
            CLXError *clxError = [CLXError errorWithCode:CLXErrorCodeAdapterInitializationError
                                             description:error.localizedDescription ?: @"InMobi SDK initialization failed"];
            completion(NO, clxError);
        } else {
            [[CLXInMobiInitializer logger] info:@"InMobi SDK initialized successfully"];
            CLXInMobiSDKInitialized = YES;
            completion(YES, nil);
        }
    }];

    [IMSdk setLogLevel:testMode ? IMSDKLogLevelDebug : IMSDKLogLevelError];
}

@end

