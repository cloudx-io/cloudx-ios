#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "CLXVerveBanner.h"
#import "CLXVerveBannerFactory.h"
#import "CLXVerveBidTokenSource.h"
#import "CloudXVerveAdapter.h"
#import "CLXVerveAdapterVersion.h"
#import "CLXVerveMetadataProvider.h"
#import "CLXVervePrivacyHandler.h"
#import "CLXVerveInitializer.h"
#import "CLXVerveInterstitial.h"
#import "CLXVerveInterstitialFactory.h"
#import "CLXVerveNative.h"
#import "CLXVerveNativeAd.h"
#import "CLXVerveNativeFactory.h"
#import "CLXVerveRewarded.h"
#import "CLXVerveRewardedFactory.h"
#import "CLXVerveErrorHandler.h"

FOUNDATION_EXPORT double CloudXVerveAdapterVersionNumber;
FOUNDATION_EXPORT const unsigned char CloudXVerveAdapterVersionString[];

