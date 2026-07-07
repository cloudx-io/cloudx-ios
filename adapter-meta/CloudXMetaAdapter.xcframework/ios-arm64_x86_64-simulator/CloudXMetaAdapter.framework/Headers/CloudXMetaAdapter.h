//
//  CloudXMetaAdapter.h
//  CloudXMetaAdapter
//
//  Umbrella header for the CloudXMetaAdapter framework.
//

#import <Foundation/Foundation.h>

// Registration function for static frameworks
__attribute__((visibility("default"))) void CloudXMetaAdapterRegister(void);

// Adapter registration class
@interface CloudXMetaAdapter : NSObject
@end

#import "CLXMetaAdView.h"
#import "CLXMetaAdViewFactory.h"
#import "CLXMetaInterstitial.h"
#import "CLXMetaInterstitialFactory.h"
#import "CLXMetaRewarded.h"
#import "CLXMetaRewardedFactory.h"
#import "CLXMetaInitializer.h"
#import "CLXMetaBidderSignalsProvider.h"
#import "CLXMetaUtils.h"
#import "CLXMetaAdapterVersion.h"