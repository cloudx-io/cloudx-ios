//
//  CloudXMetaAdapter.m
//  CloudXMetaAdapter
//
//  Registration implementation for CloudX Meta Adapter
//

#import "CloudXMetaAdapter.h"

// Import all factories and components
#import "CLXMetaInitializer.h"
#import "CLXMetaBidTokenSource.h"
#import "CLXMetaInterstitialFactory.h"
#import "CLXMetaRewardedFactory.h"
#import "CLXMetaBannerFactory.h"
#import "CLXMetaNativeFactory.h"

// Conditional import for CloudXCore header
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

// Version information
double CloudXMetaAdapterVersionNumber = 1.0;
const unsigned char CloudXMetaAdapterVersionString[] = "1.0.0";

// Ensure classes are loaded for static frameworks
__attribute__((visibility("default"))) void CloudXMetaAdapterRegister(void) {
    // Create a local logger for registration
    static CLXLogger *registrationLogger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        registrationLogger = [[CLXLogger alloc] initWithCategory:@"MetaAdapterRegistration"];
    });
    
    [registrationLogger debug:@"Loading Meta adapter classes"];
    
    // Force load all classes by referencing them
    [CLXMetaInitializer class];
    [CLXMetaBidTokenSource class];
    [CLXMetaInterstitialFactory class];
    [CLXMetaRewardedFactory class];
    [CLXMetaBannerFactory class];
    [CLXMetaNativeFactory class];
    
    [registrationLogger debug:@"Meta adapter classes loaded successfully"];
}

@implementation CloudXMetaAdapter

// Call registration during class load
+ (void)load {
    CloudXMetaAdapterRegister();
}

@end

