/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

CLX_PUBLIC_ADAPTER
@interface CLXAdapterShowParams : NSObject

@property (nonatomic, strong, readonly) UIViewController *presentingViewController;

- (instancetype)initWithPresentingViewController:(UIViewController *)presentingViewController NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
