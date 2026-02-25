//
//  CloudXInMobiAdapter.h
//  CloudXInMobiAdapter
//
//  Umbrella header for the CloudXInMobiAdapter framework.
//

#import <Foundation/Foundation.h>

//! Project version number for CloudXInMobiAdapter.
FOUNDATION_EXPORT double CloudXInMobiAdapterVersionNumber;

//! Project version string for CloudXInMobiAdapter.
FOUNDATION_EXPORT const unsigned char CloudXInMobiAdapterVersionString[];

// Registration function for static frameworks
__attribute__((visibility("default"))) void CloudXInMobiAdapterRegister(void);

// Adapter registration class
@interface CloudXInMobiAdapter : NSObject
@end

#import "CLXInMobiBanner.h"
#import "CLXInMobiBannerFactory.h"
#import "CLXInMobiInterstitial.h"
#import "CLXInMobiInterstitialFactory.h"
#import "CLXInMobiRewarded.h"
#import "CLXInMobiRewardedFactory.h"
#import "CLXInMobiInitializer.h"
#import "CLXInMobiBidTokenSource.h"
#import "CLXInMobiAdapterVersion.h"


