//
//  CloudXMagniteAdapter.h
//  CloudXMagniteAdapter
//
//  Umbrella header for the CloudXMagniteAdapter framework.
//

#import <Foundation/Foundation.h>

//! Project version number for CloudXMagniteAdapter.
FOUNDATION_EXPORT double CloudXMagniteAdapterVersionNumber;

//! Project version string for CloudXMagniteAdapter.
FOUNDATION_EXPORT const unsigned char CloudXMagniteAdapterVersionString[];

// Registration function for static frameworks
__attribute__((visibility("default"))) void CloudXMagniteAdapterRegister(void);

// Adapter registration class
@interface CloudXMagniteAdapter : NSObject
@end

// Public headers - Base Infrastructure
#import "CLXMagniteErrorHandler.h"
#import "CLXMagniteInitializer.h"
#import "CLXMagniteAdapterVersion.h"
#import "CLXMagniteMetadataProvider.h"

// Public headers - Interstitial
#import "CLXMagniteInterstitial.h"
#import "CLXMagniteInterstitialFactory.h"

// Public headers - Rewarded
#import "CLXMagniteRewarded.h"
#import "CLXMagniteRewardedFactory.h"

// Public headers - Banner
#import "CLXMagniteBanner.h"
#import "CLXMagniteBannerFactory.h"
