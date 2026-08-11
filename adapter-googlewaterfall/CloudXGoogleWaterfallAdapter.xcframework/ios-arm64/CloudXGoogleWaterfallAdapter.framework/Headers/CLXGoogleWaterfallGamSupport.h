#import <Foundation/Foundation.h>

@class GADRequest;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CLXGoogleWaterfallPlacementType) {
    CLXGoogleWaterfallPlacementTypeAdMob = 0,
    CLXGoogleWaterfallPlacementTypeGam = 1,
};

/// Supplies the ad request for one prefetch load, letting the caller decide the
/// concrete request class and any per-placement configuration.
typedef GADRequest * _Nonnull (^CLXGoogleWaterfallRequestProvider)(void);

/// Returns the request provider matching a placement's serving stack.
CLXGoogleWaterfallRequestProvider CLXGWRequestProviderForType(CLXGoogleWaterfallPlacementType type);

NS_ASSUME_NONNULL_END
