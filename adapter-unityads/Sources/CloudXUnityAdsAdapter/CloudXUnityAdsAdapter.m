//
//  CloudXUnityAdsAdapter.m
//  CloudXUnityAdsAdapter
//

#import "CloudXUnityAdsAdapter.h"
#import "CLXUnityAdsInitializer.h"
#import "CLXUnityAdsBidTokenSource.h"
#import "CLXUnityAdsInterstitialFactory.h"
#import "CLXUnityAdsRewardedFactory.h"
#import "CLXUnityAdsBannerFactory.h"
#import "CLXUnityAdsMetadataProvider.h"

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

double CloudXUnityAdsAdapterVersionNumber = 1.0;
const unsigned char CloudXUnityAdsAdapterVersionString[] = "1.0.0";

__attribute__((visibility("default"))) void CloudXUnityAdsAdapterRegister(void) {
    static CLXLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[CLXLogger alloc] initWithCategory:@"UnityAdsAdapterRegistration"];
    });

    [logger debug:@"Loading Unity Ads adapter classes"];

    [CLXUnityAdsInitializer class];
    [CLXUnityAdsBidTokenSource class];
    [CLXUnityAdsInterstitialFactory class];
    [CLXUnityAdsRewardedFactory class];
    [CLXUnityAdsBannerFactory class];
    [CLXUnityAdsMetadataProvider class];

    [logger debug:@"Unity Ads adapter classes loaded"];
}

@implementation CloudXUnityAdsAdapter

+ (void)load {
    CloudXUnityAdsAdapterRegister();
}

@end
