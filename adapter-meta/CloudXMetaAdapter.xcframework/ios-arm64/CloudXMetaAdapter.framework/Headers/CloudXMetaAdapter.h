//
//  CloudXMetaAdapter.h
//  CloudXMetaAdapter
//
//  Umbrella header for the CloudXMetaAdapter framework.
//

#import <Foundation/Foundation.h>

//! Project version number for CloudXMetaAdapter.
FOUNDATION_EXPORT double CloudXMetaAdapterVersionNumber;

//! Project version string for CloudXMetaAdapter.
FOUNDATION_EXPORT const unsigned char CloudXMetaAdapterVersionString[];

// Registration function for static frameworks
__attribute__((visibility("default"))) void CloudXMetaAdapterRegister(void);

// Adapter registration class
@interface CloudXMetaAdapter : NSObject
@end

#import "CLXMetaBanner.h"
#import "CLXMetaBannerFactory.h"
#import "CLXMetaInterstitial.h"
#import "CLXMetaInterstitialFactory.h"
#import "CLXMetaRewarded.h"
#import "CLXMetaRewardedFactory.h"
#import "CLXMetaInitializer.h"
#import "CLXMetaBidTokenSource.h"
#import "CLXMetaUtils.h"
#import "CLXMetaAdapterVersion.h"