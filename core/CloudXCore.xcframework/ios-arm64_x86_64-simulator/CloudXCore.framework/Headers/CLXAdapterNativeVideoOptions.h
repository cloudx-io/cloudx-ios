/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief localExtraParameters key disabling fullscreen on native video taps.
 * @discussion Adapter-tier. Set with `@YES`/`@NO`. Honored by adapters that
 *             support native video playback; silently ignored by adapters that
 *             do not.
 */
CLX_PUBLIC_ADAPTER
extern NSString *const CLXAdapterNativeVideoDisableFullScreenKey;

/**
 * @brief localExtraParameters key starting native video playback unmuted.
 * @discussion Adapter-tier. Set with `@YES`/`@NO`. Honored by adapters that
 *             support native video playback; silently ignored by adapters that
 *             do not.
 */
CLX_PUBLIC_ADAPTER
extern NSString *const CLXAdapterNativeVideoStartUnmutedKey;

/**
 * @brief localExtraParameters key hiding media controls on native video.
 * @discussion Adapter-tier. Set with `@YES`/`@NO`. Honored by adapters that
 *             support native video playback; silently ignored by adapters that
 *             do not.
 */
CLX_PUBLIC_ADAPTER
extern NSString *const CLXAdapterNativeVideoHideMediaControlsKey;

NS_ASSUME_NONNULL_END
