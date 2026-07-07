//
//  CLXMagniteDispatch.h
//  CloudXMagniteAdapter
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Dispatches @c block synchronously if already on the main thread, otherwise
 * asynchronously on the main queue.
 *
 * The Magnite SDK's public documentation and sample code show every SDK call —
 * initialization, consent, extras, ad load, show, and view teardown — performed
 * inside @c AppDelegate or @c UIViewController lifecycle methods (all main).
 * Empirically, the singleton also asserts on background access. Routing every
 * SDK and delegate-forwarding call through this helper keeps us on the thread
 * the SDK was designed for.
 */
NS_INLINE void CLXMagniteDispatchOnMain(dispatch_block_t block) {
    if (!block) return;
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

NS_ASSUME_NONNULL_END
