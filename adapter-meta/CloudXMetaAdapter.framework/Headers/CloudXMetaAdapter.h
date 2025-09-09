//
//  CloudXMetaAdapter.h
//  CloudXMetaAdapter
//
//  Umbrella header for the CloudXMetaAdapter framework.
//

#import <Foundation/Foundation.h>

//! Project version number for CloudXMetaAdapter.
FOUNDATION_EXPORT double CloudXMetaAdapterVersionNumber;

//! Project version string for CloudXMetaAdapter.
FOUNDATION_EXPORT const unsigned char CloudXMetaAdapterVersionString[];

// Registration function for static frameworks
__attribute__((visibility("default"))) void CloudXMetaAdapterRegister(void);

// Public headers
#import "CloudXMetaBanner.h"
#import "CloudXMetaBannerFactory.h"
#import "CloudXMetaInterstitial.h"
#import "CloudXMetaInterstitialFactory.h"
#import "CloudXMetaNative.h"
#import "CloudXMetaNativeFactory.h"
#import "CloudXMetaRewarded.h"
#import "CloudXMetaRewardedFactory.h"
#import "CloudXMetaInitializer.h"

// Add other public headers here, for example:
// #import "SomePublicHeader.h" 