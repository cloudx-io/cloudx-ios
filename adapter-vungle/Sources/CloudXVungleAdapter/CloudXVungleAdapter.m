//
//  CloudXVungleAdapter.m
//  CloudXVungleAdapter
//
//  Registration implementation for CloudX Vungle Adapter
//

#import "CloudXVungleAdapter.h"

// Import all factories and components
#import "CLXVungleInitializer.h"
#import "CLXVungleBidTokenSource.h"
#import "CLXVungleInterstitialFactory.h"
#import "CLXVungleRewardedFactory.h"
#import "CLXVungleBannerFactory.h"
#import "CLXVungleNativeFactory.h"
#import "CLXVungleAppOpenFactory.h"

// Conditional import for CloudXCore header
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

// Version information
double CloudXVungleAdapterVersionNumber = 1.0;
const unsigned char CloudXVungleAdapterVersionString[] = "1.0.0";

// Ensure classes are loaded for static frameworks
__attribute__((visibility("default"))) void CloudXVungleAdapterRegister(void) {
    // Create a local logger for registration
    static CLXLogger *registrationLogger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        registrationLogger = [[CLXLogger alloc] initWithCategory:@"VungleAdapterRegistration"];
    });
    
    [registrationLogger debug:@"Loading Vungle adapter classes"];
    
    // Force load all classes by referencing them
    [CLXVungleInitializer class];
    [CLXVungleBidTokenSource class];
    [CLXVungleInterstitialFactory class];
    [CLXVungleRewardedFactory class];
    [CLXVungleBannerFactory class];
    [CLXVungleNativeFactory class];
    [CLXVungleAppOpenFactory class];
    
    [registrationLogger debug:@"Vungle adapter classes loaded successfully"];
}

@implementation CloudXVungleAdapter

// Call registration during class load
+ (void)load {
    CloudXVungleAdapterRegister();
}

@end
