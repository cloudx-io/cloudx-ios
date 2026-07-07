#import <Foundation/Foundation.h>

__attribute__((visibility("default"))) void CloudXMintegralAdapterRegister(void);

// Adapter registration class
@interface CloudXMintegralAdapter : NSObject
@end

#import "CLXMintegralInitializer.h"
#import "CLXMintegralBidderSignalsProvider.h"
#import "CLXMintegralAdView.h"
#import "CLXMintegralAdViewFactory.h"
#import "CLXMintegralInterstitial.h"
#import "CLXMintegralInterstitialFactory.h"
#import "CLXMintegralAppOpen.h"
#import "CLXMintegralAppOpenFactory.h"
#import "CLXMintegralRewarded.h"
#import "CLXMintegralRewardedFactory.h"
#import "CLXMintegralNative.h"
#import "CLXMintegralNativeFactory.h"
#import "CLXMintegralNativeAd.h"
#import "CLXMintegralIDExtractor.h"
#import "CLXMintegralAdapterVersion.h"
