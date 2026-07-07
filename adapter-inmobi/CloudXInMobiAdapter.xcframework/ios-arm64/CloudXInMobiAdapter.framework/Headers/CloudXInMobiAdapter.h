//
//  CloudXInMobiAdapter.h
//  CloudXInMobiAdapter
//
//  Umbrella header for the CloudXInMobiAdapter framework.
//

#import <Foundation/Foundation.h>

// Registration function for static frameworks
__attribute__((visibility("default"))) void CloudXInMobiAdapterRegister(void);

// Adapter registration class
@interface CloudXInMobiAdapter : NSObject
@end

#import "CLXInMobiAdView.h"
#import "CLXInMobiAdViewFactory.h"
#import "CLXInMobiInterstitial.h"
#import "CLXInMobiInterstitialFactory.h"
#import "CLXInMobiRewarded.h"
#import "CLXInMobiRewardedFactory.h"
#import "CLXInMobiNative.h"
#import "CLXInMobiNativeFactory.h"
#import "CLXInMobiNativeAd.h"
#import "CLXInMobiInitializer.h"
#import "CLXInMobiBidderSignalsProvider.h"
#import "CLXInMobiAdapterVersion.h"


