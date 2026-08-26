//
//  CloudXGAMPrebid.h
//  CloudXGAMPrebid
//
//  Umbrella header for the CloudXGAMPrebid framework.
//

#import <Foundation/Foundation.h>

#import "CLXGAMPrebidVersion.h"

// Publisher configuration.
#import "CloudXGAMConfig.h"

// Publisher facades.
#import "CloudXGAMBanner.h"
#import "CloudXGAMInterstitial.h"
#import "CloudXGAMRewarded.h"
#import "CloudXGAMNative.h"

// GAM dashboard custom event classes.
#import "CloudXGAMBannerAdapter.h"
#import "CloudXGAMInterstitialAdapter.h"
#import "CloudXGAMRewardedAdapter.h"
#import "CloudXGAMNativeAdapter.h"

// Listener protocols and the key-values handed to the GAM request.
#import "CloudXGAMAdListener.h"
#import "CloudXGAMRewardedListener.h"
#import "CloudXGAMKeyValues.h"

// Integration-internal, not publisher API; exported for the demo harness only.
#import "CLXGamRuntime.h"
