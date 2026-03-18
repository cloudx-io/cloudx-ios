//
//  CLXUnityAdsBidTokenSource.m
//  CloudXUnityAdsAdapter
//

#if __has_include(<CloudXUnityAdsAdapter/CLXUnityAdsBidTokenSource.h>)
#import <CloudXUnityAdsAdapter/CLXUnityAdsBidTokenSource.h>
#else
#import "CLXUnityAdsBidTokenSource.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXVersion.h>
#import <UnityAds/UnityAds.h>

#if __has_include(<CloudXUnityAdsAdapter/CLXUnityAdsAdapterVersion.h>)
#import <CloudXUnityAdsAdapter/CLXUnityAdsAdapterVersion.h>
#else
#import "CLXUnityAdsAdapterVersion.h"
#endif

@interface CLXUnityAdsBidTokenSource ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXUnityAdsBidTokenSource

+ (instancetype)sharedInstance {
    static CLXUnityAdsBidTokenSource *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CLXUnityAdsBidTokenSource alloc] init];
    });
    return sharedInstance;
}

+ (instancetype)createInstance {
    return [self sharedInstance];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXUnityAdsBidTokenSource"];
    }
    return self;
}

#pragma mark - CLXBidTokenSource

- (void)getTokenWithCompletion:(void (^)(NSDictionary<NSString *, NSString *> * _Nullable token, NSError * _Nullable error))completion {
    [self.logger debug:@"Getting Unity Ads bidder token"];

    // Beta API: UADSTokenConfiguration with ad format and mediation info
    UADSMediationInfo *mediationInfo = [[UADSMediationInfo alloc] initWithName:@"cloudx"
                                                                      version:CLXSDKVersion
                                                               adapterVersion:CLXUnityAdsAdapterVersion];

    // TODO: Pass actual ad format once CLXBidTokenSource protocol supports it
    // Using UADSAdFormatUnspecified — CloudX doesn't pass ad format to the token source
    UADSTokenConfiguration *tokenConfig = [[[[UADSTokenConfigurationBuilder alloc]
        initWithAdFormat:UADSAdFormatUnspecified]
        withMediationInfo:mediationInfo]
        build];

    __weak typeof(self) weakSelf = self;
    [UnityAds getToken:tokenConfig completion:^(NSString * _Nullable token) {
        typeof(self) strongSelf = weakSelf;
        if (token && token.length > 0) {
            [strongSelf.logger debug:@"Unity Ads bidder token: [RECEIVED]"];
            if (completion) {
                completion(@{@"bid_token": token}, nil);
            }
        } else {
            [strongSelf.logger debug:@"Unity Ads bidder token: [NIL]"];
            if (completion) {
                completion(nil, nil);
            }
        }
    }];
}

@end
