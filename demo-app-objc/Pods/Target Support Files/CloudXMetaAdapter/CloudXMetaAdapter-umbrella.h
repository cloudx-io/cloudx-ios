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

#import "CLXMetaBanner.h"
#import "CLXMetaBannerFactory.h"
#import "CLXMetaBaseFactory.h"
#import "CloudXMetaAdapter.h"
#import "CLXMetaBidTokenSource.h"
#import "CLXMetaInitializer.h"
#import "CLXMetaInterstitial.h"
#import "CLXMetaInterstitialFactory.h"
#import "CLXMetaNative.h"
#import "CLXMetaNativeFactory.h"
#import "CLXMetaRewarded.h"
#import "CLXMetaRewardedFactory.h"
#import "CLXMetaErrorHandler.h"

FOUNDATION_EXPORT double CloudXMetaAdapterVersionNumber;
FOUNDATION_EXPORT const unsigned char CloudXMetaAdapterVersionString[];

