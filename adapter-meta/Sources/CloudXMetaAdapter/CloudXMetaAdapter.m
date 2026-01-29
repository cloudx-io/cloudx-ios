//
//  CloudXMetaAdapter.m
//  CloudXMetaAdapter
//

#import "CloudXMetaAdapter.h"
#import "CLXMetaInitializer.h"
#import "CLXMetaBidTokenSource.h"
#import "CLXMetaInterstitialFactory.h"
#import "CLXMetaRewardedFactory.h"
#import "CLXMetaBannerFactory.h"

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

double CloudXMetaAdapterVersionNumber = 1.0;
const unsigned char CloudXMetaAdapterVersionString[] = "1.0.0";

__attribute__((visibility("default"))) void CloudXMetaAdapterRegister(void) {
    static CLXLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[CLXLogger alloc] initWithCategory:@"MetaAdapterRegistration"];
    });

    [logger debug:@"Loading Meta adapter classes"];

    [CLXMetaInitializer class];
    [CLXMetaBidTokenSource class];
    [CLXMetaInterstitialFactory class];
    [CLXMetaRewardedFactory class];
    [CLXMetaBannerFactory class];

    [logger debug:@"Meta adapter classes loaded"];
}

@implementation CloudXMetaAdapter

+ (void)load {
    CloudXMetaAdapterRegister();
}

@end
