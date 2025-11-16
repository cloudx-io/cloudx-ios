//
//  CloudXInMobiAdapter.h
//  CloudXInMobiAdapter
//
//  Umbrella header for the CloudXInMobiAdapter framework.
//

#import <Foundation/Foundation.h>

//! Project version number for CloudXInMobiAdapter.
FOUNDATION_EXPORT double CloudXInMobiAdapterVersionNumber;

//! Project version string for CloudXInMobiAdapter.
FOUNDATION_EXPORT const unsigned char CloudXInMobiAdapterVersionString[];

// Registration function for static frameworks
__attribute__((visibility("default"))) void CloudXInMobiAdapterRegister(void);

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

