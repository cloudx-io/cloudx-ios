//
//  CloudXPangleAdapter.h
//  CloudXPangleAdapter
//
//  Umbrella header for the CloudXPangleAdapter framework.
//

#import <Foundation/Foundation.h>

// Registration function for static frameworks
__attribute__((visibility("default"))) void CloudXPangleAdapterRegister(void);

// Adapter registration class
@interface CloudXPangleAdapter : NSObject
@end

// Public headers - Base Infrastructure
#import "CLXPangleInitializer.h"
#import "CLXPangleAdapterVersion.h"
#import "CLXPangleMetadataProvider.h"

// Public headers - Bidder Signals Provider
#import "CLXPangleBidderSignalsProvider.h"

// Public headers - Interstitial
#import "CLXPangleInterstitial.h"
#import "CLXPangleInterstitialFactory.h"

// Public headers - App Open
#import "CLXPangleAppOpen.h"
#import "CLXPangleAppOpenFactory.h"

// Public headers - Rewarded
#import "CLXPangleRewarded.h"
#import "CLXPangleRewardedFactory.h"

// Public headers - Banner
#import "CLXPangleAdView.h"
#import "CLXPangleAdViewFactory.h"

// Public headers - Native
#import "CLXPangleNative.h"
#import "CLXPangleNativeFactory.h"
#import "CLXPangleNativeAd.h"
