//
//  CloudXDigitalTurbineAdapter.h
//  CloudXDigitalTurbineAdapter
//
//  Umbrella header for the CloudXDigitalTurbineAdapter framework.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double CloudXDigitalTurbineAdapterVersionNumber;
FOUNDATION_EXPORT const unsigned char CloudXDigitalTurbineAdapterVersionString[];

__attribute__((visibility("default"))) void CloudXDigitalTurbineAdapterRegister(void);

@interface CloudXDigitalTurbineAdapter : NSObject
@end

#import "CLXDigitalTurbineBanner.h"
#import "CLXDigitalTurbineBannerFactory.h"
#import "CLXDigitalTurbineInterstitial.h"
#import "CLXDigitalTurbineInterstitialFactory.h"
#import "CLXDigitalTurbineRewarded.h"
#import "CLXDigitalTurbineRewardedFactory.h"
#import "CLXDigitalTurbineNative.h"
#import "CLXDigitalTurbineNativeFactory.h"
#import "CLXDigitalTurbineNativeAd.h"
#import "CLXDigitalTurbineInitializer.h"
#import "CLXDigitalTurbineBidTokenSource.h"
#import "CLXDigitalTurbinePrivacyHandler.h"
#import "CLXDigitalTurbineErrorHandler.h"
#import "CLXDigitalTurbineUtils.h"
#import "CLXDigitalTurbineAdapterVersion.h"
#import "CLXDigitalTurbineMetadataProvider.h"
