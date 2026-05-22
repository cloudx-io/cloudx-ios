#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double CloudXMintegralAdapterVersionNumber;
FOUNDATION_EXPORT const unsigned char CloudXMintegralAdapterVersionString[];

__attribute__((visibility("default"))) void CloudXMintegralAdapterRegister(void);

// Adapter registration class
@interface CloudXMintegralAdapter : NSObject
@end

#import "CLXMintegralInitializer.h"
#import "CLXMintegralBidTokenSource.h"
#import "CLXMintegralBanner.h"
#import "CLXMintegralBannerFactory.h"
#import "CLXMintegralInterstitial.h"
#import "CLXMintegralInterstitialFactory.h"
#import "CLXMintegralRewarded.h"
#import "CLXMintegralRewardedFactory.h"
#import "CLXMintegralNative.h"
#import "CLXMintegralNativeFactory.h"
#import "CLXMintegralNativeAd.h"
#import "CLXMintegralIDExtractor.h"
#import "CLXMintegralAdapterVersion.h"
