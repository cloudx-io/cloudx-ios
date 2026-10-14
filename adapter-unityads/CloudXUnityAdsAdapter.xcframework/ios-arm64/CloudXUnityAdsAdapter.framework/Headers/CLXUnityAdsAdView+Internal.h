//
//  CLXUnityAdsAdView+Internal.h
//  CloudXUnityAdsAdapter
//

#if __has_include(<CloudXUnityAdsAdapter/CLXUnityAdsAdView.h>)
#import <CloudXUnityAdsAdapter/CLXUnityAdsAdView.h>
#else
#import "CLXUnityAdsAdView.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface CLXUnityAdsAdView (Internal)

/**
 * Depth-first search for the first view of @p klass in @p root's tree, @p root
 * included. Returns nil when @p root or @p klass is nil, or nothing matches.
 *
 * Exposed so the ad-quality object-resolution rule can be tested against a
 * synthetic view tree: the partner's own banner hierarchy cannot be built in a
 * unit test without loading a real ad.
 */
+ (nullable UIView *)clx_firstViewOfClass:(nullable Class)klass inTree:(nullable UIView *)root;

@end

NS_ASSUME_NONNULL_END
