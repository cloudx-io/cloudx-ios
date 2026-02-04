//
//  CLXAdapterLoader.h
//  CloudXCore
//
//  Centralized adapter loading utility with server-configured timeout.
//  Matches Android's centralized AdLoader.createAndLoadAdapter() pattern.
//

#import <Foundation/Foundation.h>

@class CLXError;

NS_ASSUME_NONNULL_BEGIN

/**
 * Default adapter load timeout in milliseconds (10 seconds).
 * Used when adUnit.adLoadTimeoutMs is not set or invalid.
 * Matches Android SDK default.
 */
extern const int64_t CLXDefaultAdLoadTimeoutMs;

/**
 * Centralized utility for loading ad adapters with server-configured timeout.
 *
 * This provides a single source of truth for adapter load timeout handling,
 * ensuring consistent behavior across all ad formats (interstitial, rewarded, banner).
 */
@interface CLXAdapterLoader : NSObject

/**
 * Load adapter with server-configured timeout.
 *
 * @param adapter Adapter instance with -load method
 * @param timeoutMs Timeout from adUnit.adLoadTimeoutMs (default 10000 if <= 0)
 * @param isLoadingBlock Returns YES if still loading (for timeout check)
 * @param onTimeout Called if timeout fires while still loading, with pre-built error
 *
 * @discussion The timeout is implemented using dispatch_after. When the timeout fires,
 *             it checks isLoadingBlock() to determine if the adapter is still loading.
 *             If so, onTimeout is called with a CLXError. If the adapter has already
 *             completed loading (success or failure), the timeout becomes a no-op.
 *
 * Example usage:
 * @code
 * __weak typeof(self) weakSelf = self;
 * [CLXAdapterLoader loadAdapter:self.currentAdapter
 *                     timeoutMs:[self adLoadTimeoutMs]
 *                isLoadingBlock:^BOOL{ return weakSelf.isLoading; }
 *                     onTimeout:^(CLXError *error) {
 *     __strong typeof(weakSelf) strongSelf = weakSelf;
 *     if (strongSelf) {
 *         [strongSelf transitionToIdleState];
 *         [strongSelf notifyLoadFailure:error];
 *     }
 * }];
 * @endcode
 */
+ (void)loadAdapter:(id)adapter
          timeoutMs:(int64_t)timeoutMs
     isLoadingBlock:(BOOL(^)(void))isLoadingBlock
          onTimeout:(void(^)(CLXError *error))onTimeout;

@end

NS_ASSUME_NONNULL_END
