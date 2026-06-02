//
//  CloudXPangleAdapter.h
//  CloudXPangleAdapter
//
//  Umbrella header for the CloudXPangleAdapter framework.
//

#import <Foundation/Foundation.h>

//! Project version number for CloudXPangleAdapter.
FOUNDATION_EXPORT double CloudXPangleAdapterVersionNumber;

//! Project version string for CloudXPangleAdapter.
FOUNDATION_EXPORT const unsigned char CloudXPangleAdapterVersionString[];

// Registration function for static frameworks
__attribute__((visibility("default"))) void CloudXPangleAdapterRegister(void);

// Adapter registration class
@interface CloudXPangleAdapter : NSObject
@end

// Public headers - Base Infrastructure
#import "CLXPangleErrorHandler.h"
#import "CLXPangleInitializer.h"
#import "CLXPangleAdapterVersion.h"
#import "CLXPangleMetadataProvider.h"

// Public headers - Bid Token Source
#import "CLXPangleBidTokenSource.h"

// Public headers - Interstitial
#import "CLXPangleInterstitial.h"
#import "CLXPangleInterstitialFactory.h"

// Public headers - Rewarded
#import "CLXPangleRewarded.h"
#import "CLXPangleRewardedFactory.h"

// Public headers - Banner
#import "CLXPangleBanner.h"
#import "CLXPangleBannerFactory.h"
