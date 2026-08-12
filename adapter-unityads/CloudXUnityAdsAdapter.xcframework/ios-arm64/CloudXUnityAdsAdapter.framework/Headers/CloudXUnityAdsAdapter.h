//
//  CloudXUnityAdsAdapter.h
//  CloudXUnityAdsAdapter
//
//  Umbrella header for the CloudXUnityAdsAdapter framework.
//

#import <Foundation/Foundation.h>

// Registration function for static frameworks
__attribute__((visibility("default"))) void CloudXUnityAdsAdapterRegister(void);

// Adapter registration class
@interface CloudXUnityAdsAdapter : NSObject
@end

#import "CLXUnityAdsAdapterVersion.h"
#import "CLXUnityAdsInitializer.h"
#import "CLXUnityAdsBidderSignalsProvider.h"
#import "CLXUnityAdsInterstitial.h"
#import "CLXUnityAdsInterstitialFactory.h"
#import "CLXUnityAdsRewarded.h"
#import "CLXUnityAdsRewardedFactory.h"
#import "CLXUnityAdsAdView.h"
#import "CLXUnityAdsAdViewFactory.h"
#import "CLXUnityAdsMetadataProvider.h"
#import "CLXUnityAdsPrivacyHandler.h"
