/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

CLX_PUBLIC_ADAPTER
@interface CLXAdapterUtils : NSObject

/// Returns the top-most presented view controller from the key window, or nil in extensions/background.
@property (class, nonatomic, readonly, nullable) UIViewController *topViewControllerFromKeyWindow;

/// Runs a block on the main queue, executing synchronously when already on the main thread.
+ (void)runOnMain:(dispatch_block_t)block;

@end

NS_ASSUME_NONNULL_END
