//
//  CloudXMintegralAdapter.m
//  CloudXMintegralAdapter
//
//  Registration implementation for CloudX Mintegral Adapter
//

#import "CloudXMintegralAdapter.h"

// Import all factories and components
#import "CLXMintegralInitializer.h"
#import "CLXMintegralBidTokenSource.h"
#import "CLXMintegralInterstitialFactory.h"
#import "CLXMintegralRewardedFactory.h"
#import "CLXMintegralBannerFactory.h"

// Conditional import for CloudXCore header
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

// Version information
double CloudXMintegralAdapterVersionNumber = 1.0;
const unsigned char CloudXMintegralAdapterVersionString[] = "1.0.0";

// Ensure classes are loaded for static frameworks
__attribute__((visibility("default"))) void CloudXMintegralAdapterRegister(void) {
    // Create a local logger for registration
    static CLXLogger *registrationLogger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        registrationLogger = [[CLXLogger alloc] initWithCategory:@"MintegralAdapterRegistration"];
    });
    
    [registrationLogger debug:@"Loading Mintegral adapter classes"];
    
    // Force load all classes by referencing them
    [CLXMintegralInitializer class];
    [CLXMintegralBidTokenSource class];
    [CLXMintegralInterstitialFactory class];
    [CLXMintegralRewardedFactory class];
    [CLXMintegralBannerFactory class];
    
    [registrationLogger debug:@"Mintegral adapter classes loaded successfully"];
}

@implementation CloudXMintegralAdapter

// Call registration during class load
+ (void)load {
    CloudXMintegralAdapterRegister();
}

@end

