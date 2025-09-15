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

/**
 * Registration function for CloudX Vungle Adapter
 * This function is called by the CloudX SDK to register all adapter components
 */
void CloudXVungleAdapterRegister(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Create logger for registration process
        CLXLogger *logger = [CLXLogger loggerWithTag:@"VungleAdapterRegistration"];
        
        [logger logInfo:@"Registering CloudX Vungle Adapter v1.0.0"];
        
        // Register the network initializer
        [CLXAdNetworkRegistry registerInitializer:[CLXVungleInitializer class]
                                       forNetwork:@"Vungle"];
        
        // Register bid token source
        [CLXBidTokenRegistry registerBidTokenSource:[CLXVungleBidTokenSource class]
                                         forNetwork:@"Vungle"];
        
        // Register adapter factories
        [CLXAdapterFactoryRegistry registerInterstitialFactory:[CLXVungleInterstitialFactory class]
                                                    forNetwork:@"Vungle"];
        
        [CLXAdapterFactoryRegistry registerRewardedFactory:[CLXVungleRewardedFactory class]
                                                forNetwork:@"Vungle"];
        
        [CLXAdapterFactoryRegistry registerBannerFactory:[CLXVungleBannerFactory class]
                                              forNetwork:@"Vungle"];
        
        [CLXAdapterFactoryRegistry registerNativeFactory:[CLXVungleNativeFactory class]
                                              forNetwork:@"Vungle"];
        
        // Register App Open factory (uses interstitial factory protocol)
        [CLXAdapterFactoryRegistry registerInterstitialFactory:[CLXVungleAppOpenFactory class]
                                                    forNetwork:@"VungleAppOpen"];
        
        [logger logInfo:@"CloudX Vungle Adapter registration completed successfully"];
        [logger logInfo:@"Supported ad formats: Interstitial, Rewarded, Banner/MREC, Native, App Open"];
        [logger logInfo:@"Features: Header Bidding, Waterfall, Error Handling, Privacy Compliance"];
    });
}

/**
 * Automatic registration using constructor attribute
 * This ensures the adapter is registered when the framework is loaded
 */
__attribute__((constructor))
static void CloudXVungleAdapterAutoRegister(void) {
    CloudXVungleAdapterRegister();
}
