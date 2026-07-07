//
//  CloudXVungleAdapter.h
//  CloudXVungleAdapter
//
//  Umbrella header for the CloudXVungleAdapter framework.
//

#import <Foundation/Foundation.h>

// Registration function for static frameworks
__attribute__((visibility("default"))) void CloudXVungleAdapterRegister(void);

// Adapter registration class
@interface CloudXVungleAdapter : NSObject
@end

// Public headers - Base Infrastructure
#import "CLXVungleInitializer.h"
#import "CLXVungleAdapterVersion.h"

// Public headers - Bidder Signals Provider
#import "CLXVungleBidderSignalsProvider.h"

// Public headers - Interstitial
#import "CLXVungleInterstitial.h"
#import "CLXVungleInterstitialFactory.h"

// Public headers - Rewarded
#import "CLXVungleRewarded.h"
#import "CLXVungleRewardedFactory.h"

// Public headers - Banner
#import "CLXVungleAdView.h"
#import "CLXVungleAdViewFactory.h"

// Public headers - Native
#import "CLXVungleNative.h"
#import "CLXVungleNativeFactory.h"
#import "CLXVungleNativeAd.h"

// Public headers - App Open
#import "CLXVungleAppOpenFactory.h"
