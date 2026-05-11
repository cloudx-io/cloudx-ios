/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

CLX_PUBLIC
@interface CLXNativeAdImage : NSObject

@property (nonatomic, strong, readonly, nullable) UIImage *image;
@property (nonatomic, copy, readonly, nullable) NSURL *URL;
@property (nonatomic, copy, readonly, nullable) NSURL *url
    __attribute__((deprecated("Use URL instead.")));

- (instancetype)initWithImage:(UIImage *)image;
- (instancetype)initWithURL:(NSURL *)url;
- (instancetype)initWithImage:(nullable UIImage *)image url:(nullable NSURL *)url NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
