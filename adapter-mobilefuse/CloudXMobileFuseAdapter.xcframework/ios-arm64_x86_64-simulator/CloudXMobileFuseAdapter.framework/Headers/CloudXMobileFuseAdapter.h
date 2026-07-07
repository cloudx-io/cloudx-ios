//
//  CloudXMobileFuseAdapter.h
//  CloudXMobileFuseAdapter
//
//  Umbrella header for the CloudXMobileFuseAdapter framework.
//

#import <Foundation/Foundation.h>

__attribute__((visibility("default"))) void CloudXMobileFuseAdapterRegister(void);

@interface CloudXMobileFuseAdapter : NSObject
@end

#import "CLXMobileFuseAdView.h"
#import "CLXMobileFuseAdViewFactory.h"
#import "CLXMobileFuseInterstitial.h"
#import "CLXMobileFuseInterstitialFactory.h"
#import "CLXMobileFuseRewarded.h"
#import "CLXMobileFuseRewardedFactory.h"
#import "CLXMobileFuseNative.h"
#import "CLXMobileFuseNativeAd.h"
#import "CLXMobileFuseNativeFactory.h"
#import "CLXMobileFuseInitializer.h"
#import "CLXMobileFuseBidderSignalsProvider.h"
#import "CLXMobileFusePrivacyHandler.h"
#import "CLXMobileFuseMetadataProvider.h"
#import "CLXMobileFuseErrorHandler.h"
#import "CLXMobileFuseAdapterVersion.h"
