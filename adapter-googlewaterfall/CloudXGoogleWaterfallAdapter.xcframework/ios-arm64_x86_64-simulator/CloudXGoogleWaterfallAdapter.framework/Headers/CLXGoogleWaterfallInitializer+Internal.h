#import "CLXGoogleWaterfallInitializer.h"
#import <UIKit/UIKit.h>

@class CLXGoogleWaterfallPreloaderRegistry;
@class CLXGoogleWaterfallPrefetchWorker;

NS_ASSUME_NONNULL_BEGIN

typedef void (^CLXGoogleWaterfallMediationStart)(void (^completion)(void));
typedef UIApplicationState (^CLXGoogleWaterfallAppStateProvider)(void);
typedef void (^CLXGoogleWaterfallPrefetchStart)(CLXGoogleWaterfallPreloaderRegistry * _Nullable registry,
                                                CLXGoogleWaterfallPrefetchWorker * _Nullable worker);

@interface CLXGoogleWaterfallInitializer ()

/// Bundle the application identifier is read from. Defaults to the main bundle.
@property (nonatomic, strong) NSBundle *appIdBundle;

/// Starts the mediation SDK and invokes `completion` when it has finished.
/// Defaults to `GADMobileAds.sharedInstance startWithCompletionHandler:`.
@property (nonatomic, copy) CLXGoogleWaterfallMediationStart startMediation;

/// Current application state, read on main. Defaults to `UIApplication.applicationState`.
@property (nonatomic, copy) CLXGoogleWaterfallAppStateProvider appStateProvider;

/// Starts fullscreen preloading and the prefetch worker. Defaults to
/// `-[registry startAll]` then `-[worker start]`.
@property (nonatomic, copy) CLXGoogleWaterfallPrefetchStart startPrefetch;

@end

NS_ASSUME_NONNULL_END
