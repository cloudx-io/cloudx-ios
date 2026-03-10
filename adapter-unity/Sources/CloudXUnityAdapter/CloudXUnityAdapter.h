//
//  CloudXUnityAdapter.h
//  CloudXUnityAdapter
//
//  Umbrella header for the CloudXUnityAdapter framework.
//

#import <Foundation/Foundation.h>

//! Project version number for CloudXUnityAdapter.
FOUNDATION_EXPORT double CloudXUnityAdapterVersionNumber;

//! Project version string for CloudXUnityAdapter.
FOUNDATION_EXPORT const unsigned char CloudXUnityAdapterVersionString[];

// Registration function for static frameworks
__attribute__((visibility("default"))) void CloudXUnityAdapterRegister(void);

// Adapter registration class
@interface CloudXUnityAdapter : NSObject
@end

#import "CLXUnityAdapterVersion.h"
#import "CLXUnityInitializer.h"
#import "CLXUnityBidTokenSource.h"
#import "CLXUnityInterstitial.h"
#import "CLXUnityInterstitialFactory.h"
#import "CLXUnityRewarded.h"
#import "CLXUnityRewardedFactory.h"
#import "CLXUnityBanner.h"
#import "CLXUnityBannerFactory.h"
