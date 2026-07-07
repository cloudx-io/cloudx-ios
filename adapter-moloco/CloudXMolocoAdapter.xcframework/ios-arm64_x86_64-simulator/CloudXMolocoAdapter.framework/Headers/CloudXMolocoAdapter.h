//
//  CloudXMolocoAdapter.h
//  CloudXMolocoAdapter
//
//  Umbrella header for the CloudXMolocoAdapter framework.
//

#import <Foundation/Foundation.h>

// Registration function for static frameworks
__attribute__((visibility("default"))) void CloudXMolocoAdapterRegister(void);

// Adapter registration class
@interface CloudXMolocoAdapter : NSObject
@end

// Public headers - Base Infrastructure
#import "CLXMolocoInitializer.h"
#import "CLXMolocoAdapterVersion.h"
#import "CLXMolocoMetadataProvider.h"
#import "CLXMolocoPrivacyHandler.h"

// Public headers - Bidder Signals Provider
#import "CLXMolocoBidderSignalsProvider.h"

// Public headers - Banner / MREC
#import "CLXMolocoAdView.h"
#import "CLXMolocoAdViewFactory.h"

// Public headers - Interstitial
#import "CLXMolocoInterstitial.h"
#import "CLXMolocoInterstitialFactory.h"

// Public headers - Rewarded
#import "CLXMolocoRewarded.h"
#import "CLXMolocoRewardedFactory.h"

// Public headers - Native
#import "CLXMolocoNative.h"
#import "CLXMolocoNativeAd.h"
#import "CLXMolocoNativeFactory.h"
