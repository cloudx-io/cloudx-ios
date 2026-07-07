//
//  CloudXDigitalTurbineAdapter.h
//  CloudXDigitalTurbineAdapter
//
//  Umbrella header for the CloudXDigitalTurbineAdapter framework.
//

#import <Foundation/Foundation.h>

__attribute__((visibility("default"))) void CloudXDigitalTurbineAdapterRegister(void);

@interface CloudXDigitalTurbineAdapter : NSObject
@end

#import "CLXDigitalTurbineAdView.h"
#import "CLXDigitalTurbineAdViewFactory.h"
#import "CLXDigitalTurbineInterstitial.h"
#import "CLXDigitalTurbineInterstitialFactory.h"
#import "CLXDigitalTurbineRewarded.h"
#import "CLXDigitalTurbineRewardedFactory.h"
#import "CLXDigitalTurbineNative.h"
#import "CLXDigitalTurbineNativeFactory.h"
#import "CLXDigitalTurbineNativeAd.h"
#import "CLXDigitalTurbineInitializer.h"
#import "CLXDigitalTurbineBidderSignalsProvider.h"
#import "CLXDigitalTurbinePrivacyHandler.h"
#import "CLXDigitalTurbineErrorHandler.h"
#import "CLXDigitalTurbineUtils.h"
#import "CLXDigitalTurbineAdapterVersion.h"
#import "CLXDigitalTurbineMetadataProvider.h"
