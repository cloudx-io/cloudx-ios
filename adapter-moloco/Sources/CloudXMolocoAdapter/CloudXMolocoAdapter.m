//
//  CloudXMolocoAdapter.m
//  CloudXMolocoAdapter
//
//  Registration implementation for CloudX Moloco Adapter
//

#import "CloudXMolocoAdapter.h"

// Import all factories and components
#import "CLXMolocoInitializer.h"
#import "CLXMolocoBidTokenSource.h"
#import "CLXMolocoInterstitialFactory.h"
#import "CLXMolocoRewardedFactory.h"
#import "CLXMolocoBannerFactory.h"
#import "CLXMolocoNativeFactory.h"

// Conditional import for CloudXCore header
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

// Version information
double CloudXMolocoAdapterVersionNumber = 1.0;
const unsigned char CloudXMolocoAdapterVersionString[] = "1.0.0";

// Ensure classes are loaded for static frameworks
__attribute__((visibility("default"))) void CloudXMolocoAdapterRegister(void) {
    // Create a local logger for registration
    static CLXLogger *registrationLogger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        registrationLogger = [[CLXLogger alloc] initWithCategory:@"MolocoAdapterRegistration"];
    });
    
    [registrationLogger debug:@"Loading Moloco adapter classes"];
    
    // Force load all classes by referencing them
    [CLXMolocoInitializer class];
    [CLXMolocoBidTokenSource class];
    [CLXMolocoInterstitialFactory class];
    [CLXMolocoRewardedFactory class];
    [CLXMolocoBannerFactory class];
    [CLXMolocoNativeFactory class];
    
    [registrationLogger debug:@"Moloco adapter classes loaded successfully"];
}

@implementation CloudXMolocoAdapter

// Call registration during class load
+ (void)load {
    CloudXMolocoAdapterRegister();
}

@end

