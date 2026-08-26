#import "CLXGoogleWaterfallInitializer.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^CLXGoogleWaterfallMediationStart)(void (^completion)(void));

@interface CLXGoogleWaterfallInitializer ()

/// Bundle the application identifier is read from. Defaults to the main bundle.
@property (nonatomic, strong) NSBundle *appIdBundle;

/// Starts the mediation SDK and invokes `completion` when it has finished.
/// Defaults to `GADMobileAds.sharedInstance startWithCompletionHandler:`.
@property (nonatomic, copy) CLXGoogleWaterfallMediationStart startMediation;

@end

NS_ASSUME_NONNULL_END
