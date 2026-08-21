#import <Foundation/Foundation.h>

@class CLXGoogleWaterfallPreloaderRegistry;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief Module-global slot for the preloader registry the initializer built.
 */
@interface CLXGoogleWaterfallRegistryHolder : NSObject

/**
 * @brief The live registry.
 * @return nil before initialization and after shutdown.
 */
+ (nullable CLXGoogleWaterfallPreloaderRegistry *)current;

/**
 * @brief Replaces the live registry.
 * @param registry The registry, or nil to clear.
 */
+ (void)setCurrent:(nullable CLXGoogleWaterfallPreloaderRegistry *)registry;

@end

NS_ASSUME_NONNULL_END
