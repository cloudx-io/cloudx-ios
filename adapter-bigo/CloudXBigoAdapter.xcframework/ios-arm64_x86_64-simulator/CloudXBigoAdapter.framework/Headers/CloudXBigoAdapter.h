#import <Foundation/Foundation.h>

__attribute__((visibility("default"))) void CloudXBigoAdapterRegister(void);

// Adapter registration class
@interface CloudXBigoAdapter : NSObject
@end

#import "CLXBigoInitializer.h"
#import "CLXBigoBidderSignalsProvider.h"
#import "CLXBigoAdView.h"
#import "CLXBigoAdViewFactory.h"
#import "CLXBigoInterstitial.h"
#import "CLXBigoInterstitialFactory.h"
#import "CLXBigoRewarded.h"
#import "CLXBigoRewardedFactory.h"
#import "CLXBigoPrivacyHandler.h"
#import "CLXBigoMetadataProvider.h"
#import "CLXBigoErrorHandler.h"
#import "CLXBigoIDExtractor.h"
#import "CLXBigoMediationInfo.h"
#import "CLXBigoAdapterVersion.h"
