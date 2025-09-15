//
//  CloudXVungleAdapter.h
//  CloudXVungleAdapter
//
//  Umbrella header for the CloudXVungleAdapter framework.
//

#import <Foundation/Foundation.h>

//! Project version number for CloudXVungleAdapter.
FOUNDATION_EXPORT double CloudXVungleAdapterVersionNumber;

//! Project version string for CloudXVungleAdapter.
FOUNDATION_EXPORT const unsigned char CloudXVungleAdapterVersionString[];

// Registration function for static frameworks
__attribute__((visibility("default"))) void CloudXVungleAdapterRegister(void);

// Public headers - Base Infrastructure
#import "CLXVungleBaseFactory.h"
#import "CLXVungleErrorHandler.h"
#import "CLXVungleInitializer.h"

// Public headers - Bid Token Source
#import "CLXVungleBidTokenSource.h"

// Public headers - Interstitial
#import "CLXVungleInterstitial.h"
#import "CLXVungleInterstitialFactory.h"

// Public headers - Rewarded
#import "CLXVungleRewarded.h"
#import "CLXVungleRewardedFactory.h"

// Public headers - Banner
#import "CLXVungleBanner.h"
#import "CLXVungleBannerFactory.h"

// Public headers - Native
#import "CLXVungleNative.h"
#import "CLXVungleNativeFactory.h"

// Public headers - App Open
#import "CLXVungleAppOpen.h"
#import "CLXVungleAppOpenFactory.h"
