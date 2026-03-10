//
//  CLXUnityBidTokenSource.m
//  CloudXUnityAdapter
//

#if __has_include(<CloudXUnityAdapter/CLXUnityBidTokenSource.h>)
#import <CloudXUnityAdapter/CLXUnityBidTokenSource.h>
#else
#import "CLXUnityBidTokenSource.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXVersion.h>
#import <UnityAds/UnityAds.h>

#if __has_include(<CloudXUnityAdapter/CLXUnityAdapterVersion.h>)
#import <CloudXUnityAdapter/CLXUnityAdapterVersion.h>
#else
#import "CLXUnityAdapterVersion.h"
#endif

@interface CLXUnityBidTokenSource ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXUnityBidTokenSource

+ (instancetype)sharedInstance {
    static CLXUnityBidTokenSource *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CLXUnityBidTokenSource alloc] init];
    });
    return sharedInstance;
}

+ (instancetype)createInstance {
    return [self sharedInstance];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXUnityBidTokenSource"];
    }
    return self;
}

#pragma mark - CLXBidTokenSource

- (void)getTokenWithCompletion:(void (^)(NSDictionary<NSString *, NSString *> * _Nullable token, NSError * _Nullable error))completion {
    [self.logger debug:@"Getting Unity bidder token"];

    // Beta API: UADSTokenConfiguration with ad format and mediation info
    UADSMediationInfo *mediationInfo = [[UADSMediationInfo alloc] initWithName:@"cloudx"
                                                                      version:CLXSDKVersion
                                                               adapterVersion:CLXUnityAdapterVersion];

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
            [strongSelf.logger debug:@"Unity bidder token: [RECEIVED]"];
            if (completion) {
                completion(@{@"bid_token": token}, nil);
            }
        } else {
            [strongSelf.logger debug:@"Unity bidder token: [NIL]"];
            if (completion) {
                completion(nil, nil);
            }
        }
    }];
}

@end
