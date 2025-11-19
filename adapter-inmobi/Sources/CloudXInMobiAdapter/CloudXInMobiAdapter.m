//
//  CloudXInMobiAdapter.m
//  CloudXInMobiAdapter
//
//  Registration implementation for CloudX InMobi Adapter
//

#import "CloudXInMobiAdapter.h"

// Import all factories and components
#import "CLXInMobiInitializer.h"
#import "CLXInMobiBidTokenSource.h"
#import "CLXInMobiInterstitialFactory.h"
#import "CLXInMobiRewardedFactory.h"
#import "CLXInMobiBannerFactory.h"
#import "CLXInMobiNativeFactory.h"

// Conditional import for CloudXCore header
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

// Version information
double CloudXInMobiAdapterVersionNumber = 1.0;
const unsigned char CloudXInMobiAdapterVersionString[] = "1.0.0";

// Ensure classes are loaded for static frameworks
__attribute__((visibility("default"))) void CloudXInMobiAdapterRegister(void) {
    // Create a local logger for registration
    static CLXLogger *registrationLogger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        registrationLogger = [[CLXLogger alloc] initWithCategory:@"InMobiAdapterRegistration"];
    });
    
    [registrationLogger debug:@"Loading InMobi adapter classes"];
    
    // Force load all classes by referencing them
    [CLXInMobiInitializer class];
    [CLXInMobiBidTokenSource class];
    [CLXInMobiInterstitialFactory class];
    [CLXInMobiRewardedFactory class];
    [CLXInMobiBannerFactory class];
    [CLXInMobiNativeFactory class];
    
    [registrationLogger debug:@"InMobi adapter classes loaded successfully"];
}

@implementation CloudXInMobiAdapter

// Call registration during class load
+ (void)load {
    CloudXInMobiAdapterRegister();
}

@end

