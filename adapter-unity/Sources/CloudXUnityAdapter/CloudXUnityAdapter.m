//
//  CloudXUnityAdapter.m
//  CloudXUnityAdapter
//

#import "CloudXUnityAdapter.h"
#import "CLXUnityInitializer.h"
#import "CLXUnityBidTokenSource.h"
#import "CLXUnityInterstitialFactory.h"
#import "CLXUnityRewardedFactory.h"
#import "CLXUnityBannerFactory.h"
#import "CLXUnityMetadataProvider.h"

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

double CloudXUnityAdapterVersionNumber = 1.0;
const unsigned char CloudXUnityAdapterVersionString[] = "1.0.0";

__attribute__((visibility("default"))) void CloudXUnityAdapterRegister(void) {
    static CLXLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[CLXLogger alloc] initWithCategory:@"UnityAdapterRegistration"];
    });

    [logger debug:@"Loading Unity adapter classes"];

    [CLXUnityInitializer class];
    [CLXUnityBidTokenSource class];
    [CLXUnityInterstitialFactory class];
    [CLXUnityRewardedFactory class];
    [CLXUnityBannerFactory class];
    [CLXUnityMetadataProvider class];

    [logger debug:@"Unity adapter classes loaded"];
}

@implementation CloudXUnityAdapter

+ (void)load {
    CloudXUnityAdapterRegister();
}

@end
