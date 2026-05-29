//
//  CloudXGoogleWaterfallAdapter.h
//  CloudXGoogleWaterfallAdapter
//
//  Umbrella header for the CloudXGoogleWaterfallAdapter framework.
//

#import <Foundation/Foundation.h>

//! Project version number for CloudXGoogleWaterfallAdapter.
FOUNDATION_EXPORT double CloudXGoogleWaterfallAdapterVersionNumber;

//! Project version string for CloudXGoogleWaterfallAdapter.
FOUNDATION_EXPORT const unsigned char CloudXGoogleWaterfallAdapterVersionString[];

// Registration function for static frameworks
__attribute__((visibility("default"))) void CloudXGoogleWaterfallAdapterRegister(void);

// Adapter registration class
@interface CloudXGoogleWaterfallAdapter : NSObject
@end

// Banner + MREC are the only served formats. Fullscreen factories exist but
// fail closed (see the interstitial/rewarded adapters) so the factory surface
// matches sibling adapters; the SSP never routes fullscreen here.
#import "CLXGoogleWaterfallBanner.h"
#import "CLXGoogleWaterfallBannerFactory.h"
#import "CLXGoogleWaterfallInterstitial.h"
#import "CLXGoogleWaterfallInterstitialFactory.h"
#import "CLXGoogleWaterfallRewarded.h"
#import "CLXGoogleWaterfallRewardedFactory.h"
#import "CLXGoogleWaterfallInitializer.h"
#import "CLXGoogleWaterfallBidTokenSource.h"
#import "CLXGoogleWaterfallMetadataProvider.h"
#import "CLXGoogleWaterfallAdapterVersion.h"
