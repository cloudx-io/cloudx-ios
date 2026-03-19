//
//  CloudXUnityAdsAdapter.h
//  CloudXUnityAdsAdapter
//
//  Umbrella header for the CloudXUnityAdsAdapter framework.
//

#import <Foundation/Foundation.h>

//! Project version number for CloudXUnityAdsAdapter.
FOUNDATION_EXPORT double CloudXUnityAdsAdapterVersionNumber;

//! Project version string for CloudXUnityAdsAdapter.
FOUNDATION_EXPORT const unsigned char CloudXUnityAdsAdapterVersionString[];

// Registration function for static frameworks
__attribute__((visibility("default"))) void CloudXUnityAdsAdapterRegister(void);

// Adapter registration class
@interface CloudXUnityAdsAdapter : NSObject
@end

#import "CLXUnityAdsAdapterVersion.h"
#import "CLXUnityAdsInitializer.h"
#import "CLXUnityAdsBidTokenSource.h"
#import "CLXUnityAdsInterstitial.h"
#import "CLXUnityAdsInterstitialFactory.h"
#import "CLXUnityAdsRewarded.h"
#import "CLXUnityAdsRewardedFactory.h"
#import "CLXUnityAdsBanner.h"
#import "CLXUnityAdsBannerFactory.h"
