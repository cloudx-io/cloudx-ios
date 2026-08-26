//
//  CLXGamNativeGamBridge.h
//  CloudXGAMPrebid
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** GAM-side impression/click bridge installed by the native custom event at render time. */
@protocol CLXGamNativeGamBridge <NSObject>

/** @brief Forward a CloudX-originated click into GAM's native event delegate. */
- (void)reportClicked;

/** @brief Forward CloudX's recorded impression into GAM's native event delegate. */
- (void)reportImpressed;

@end

NS_ASSUME_NONNULL_END
