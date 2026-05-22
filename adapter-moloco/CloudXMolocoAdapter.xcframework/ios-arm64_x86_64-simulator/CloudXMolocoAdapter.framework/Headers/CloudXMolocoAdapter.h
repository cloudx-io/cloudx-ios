//
//  CloudXMolocoAdapter.h
//  CloudXMolocoAdapter
//
//  Umbrella header for the CloudXMolocoAdapter framework.
//

#import <Foundation/Foundation.h>

//! Project version number for CloudXMolocoAdapter.
FOUNDATION_EXPORT double CloudXMolocoAdapterVersionNumber;

//! Project version string for CloudXMolocoAdapter.
FOUNDATION_EXPORT const unsigned char CloudXMolocoAdapterVersionString[];

// Registration function for static frameworks
__attribute__((visibility("default"))) void CloudXMolocoAdapterRegister(void);

// Adapter registration class
@interface CloudXMolocoAdapter : NSObject
@end

// Public headers - Base Infrastructure
#import "CLXMolocoInitializer.h"
#import "CLXMolocoAdapterVersion.h"
#import "CLXMolocoMetadataProvider.h"
#import "CLXMolocoPrivacyHandler.h"

// Public headers - Bid Token Source
#import "CLXMolocoBidTokenSource.h"

// Public headers - Banner / MREC
#import "CLXMolocoBanner.h"
#import "CLXMolocoBannerFactory.h"

// Public headers - Interstitial
#import "CLXMolocoInterstitial.h"
#import "CLXMolocoInterstitialFactory.h"

// Public headers - Rewarded
#import "CLXMolocoRewarded.h"
#import "CLXMolocoRewardedFactory.h"

// Public headers - Native
#import "CLXMolocoNative.h"
#import "CLXMolocoNativeAd.h"
#import "CLXMolocoNativeFactory.h"
