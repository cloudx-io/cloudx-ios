//
//  CloudXVungleAdapter.m
//  CloudXVungleAdapter
//

#import "CloudXVungleAdapter.h"
#import "CLXVungleInitializer.h"
#import "CLXVungleBidTokenSource.h"
#import "CLXVungleInterstitialFactory.h"
#import "CLXVungleRewardedFactory.h"
#import "CLXVungleBannerFactory.h"
#import "CLXVungleAppOpenFactory.h"
#import "CLXVungleMetadataProvider.h"

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

__attribute__((visibility("default"))) void CloudXVungleAdapterRegister(void) {
    static CLXLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[CLXLogger alloc] initWithCategory:@"VungleAdapterRegistration"];
    });

    [logger debug:@"Loading Vungle adapter classes"];

    [CLXVungleInitializer class];
    [CLXVungleBidTokenSource class];
    [CLXVungleInterstitialFactory class];
    [CLXVungleRewardedFactory class];
    [CLXVungleBannerFactory class];
    [CLXVungleAppOpenFactory class];
    [CLXVungleMetadataProvider class];

    [logger debug:@"Vungle adapter classes loaded"];
}

@implementation CloudXVungleAdapter

+ (void)load {
    CloudXVungleAdapterRegister();
}

@end
