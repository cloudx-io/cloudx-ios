/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

__attribute__((visibility("default"))) void CloudXVerveAdapterRegister(void);

@interface CloudXVerveAdapter : NSObject
@end

#import "CLXVerveAdapterVersion.h"
#import "CLXVerveMetadataProvider.h"
#import "CLXVervePrivacyHandler.h"
#import "CLXVerveInitializer.h"
#import "CLXVerveBidderSignalsProvider.h"
#import "CLXVerveErrorHandler.h"
#import "CLXVerveAdView.h"
#import "CLXVerveAdViewFactory.h"
#import "CLXVerveInterstitial.h"
#import "CLXVerveInterstitialFactory.h"
#import "CLXVerveRewarded.h"
#import "CLXVerveRewardedFactory.h"
#import "CLXVerveNative.h"
#import "CLXVerveNativeAd.h"
#import "CLXVerveNativeFactory.h"
