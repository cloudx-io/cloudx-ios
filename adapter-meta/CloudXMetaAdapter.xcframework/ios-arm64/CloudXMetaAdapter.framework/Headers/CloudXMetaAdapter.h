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
#import "CLXMetaBanner.h"
#import "CLXMetaBannerFactory.h"
#import "CLXMetaInterstitial.h"
#import "CLXMetaInterstitialFactory.h"
#import "CLXMetaNative.h"
#import "CLXMetaNativeFactory.h"
#import "CLXMetaRewarded.h"
#import "CLXMetaRewardedFactory.h"
#import "CLXMetaInitializer.h"
#import "CLXMetaBidTokenSource.h"
#import "CLXMetaBaseFactory.h"

// Add other public headers here, for example:
// #import "SomePublicHeader.h" 