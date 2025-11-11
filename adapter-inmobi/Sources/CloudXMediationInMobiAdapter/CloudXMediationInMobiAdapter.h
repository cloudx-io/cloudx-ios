//
//  CloudXMediationInMobiAdapter.h
//  CloudXMediationInMobiAdapter
//
//  Umbrella header for the CloudXMediationInMobiAdapter framework.
//

#import <Foundation/Foundation.h>

//! Project version number for CloudXMediationInMobiAdapter.
FOUNDATION_EXPORT double CloudXMediationInMobiAdapterVersionNumber;

//! Project version string for CloudXMediationInMobiAdapter.
FOUNDATION_EXPORT const unsigned char CloudXMediationInMobiAdapterVersionString[];

// Registration function for static frameworks
__attribute__((visibility("default"))) void CloudXMediationInMobiAdapterRegister(void);

// Public headers - Initializer
#import "CLXInMobiInitializer.h"

// Public headers - Bid Token Source  
#import "CLXInMobiBidTokenSource.h"

// Public headers - Interstitial
#import "CLXInMobiInterstitial.h"
#import "CLXInMobiInterstitialFactory.h"

// Public headers - Banner
#import "CLXInMobiBanner.h"
#import "CLXInMobiBannerFactory.h"

// Public headers - Rewarded
#import "CLXInMobiRewarded.h"
#import "CLXInMobiRewardedFactory.h"

// Public headers - Native
#import "CLXInMobiNative.h"
#import "CLXInMobiNativeFactory.h"

// Public headers - Base & Utils
#import "CLXInMobiBaseFactory.h"

