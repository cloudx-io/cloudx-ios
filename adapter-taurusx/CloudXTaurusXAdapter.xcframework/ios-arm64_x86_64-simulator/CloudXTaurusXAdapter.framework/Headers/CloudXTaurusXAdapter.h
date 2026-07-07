#import <Foundation/Foundation.h>

__attribute__((visibility("default"))) void CloudXTaurusXAdapterRegister(void);

@interface CloudXTaurusXAdapter : NSObject
@end

#import "CLXTaurusXAdapterVersion.h"
#import "CLXTaurusXUtils.h"
#import "CLXTaurusXErrorHandler.h"
#import "CLXTaurusXInitializer.h"
#import "CLXTaurusXBidderSignalsProvider.h"
// Import paths are intentionally left mixed (reviewed, not normalized): some are
// folder-prefixed (Native/...), some are not, yet all resolve via header maps in
// the pod build. The podspec exposes public headers flat (no header_mappings_dir),
// so consumers import them flat regardless of the prefix used here. Normalizing is
// cosmetic and risks breaking that resolution, so it is deferred.
#import "CLXTaurusXAdView.h"
#import "CLXTaurusXAdViewFactory.h"
#import "CLXTaurusXInterstitial.h"
#import "CLXTaurusXInterstitialFactory.h"
#import "CLXTaurusXRewarded.h"
#import "CLXTaurusXRewardedFactory.h"
#import "Native/CLXTaurusXNative.h"
#import "Native/CLXTaurusXNativeAd.h"
#import "Native/CLXTaurusXNativeFactory.h"
