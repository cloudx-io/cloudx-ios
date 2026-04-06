/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXNativeAdViewBinderBuilder : NSObject

@property (nonatomic, assign) NSInteger titleLabelTag;
@property (nonatomic, assign) NSInteger advertiserLabelTag;
@property (nonatomic, assign) NSInteger bodyLabelTag;
@property (nonatomic, assign) NSInteger callToActionButtonTag;
@property (nonatomic, assign) NSInteger iconImageViewTag;
@property (nonatomic, assign) NSInteger iconContentViewTag
    __attribute__((deprecated("Use iconImageViewTag instead.")));
@property (nonatomic, assign) NSInteger optionsContentViewTag;
@property (nonatomic, assign) NSInteger mediaContentViewTag;
@property (nonatomic, assign) NSInteger starRatingContentViewTag;

@end

typedef void (^CLXNativeAdViewBinderBuilderBlock)(CLXNativeAdViewBinderBuilder *builder);

@interface CLXNativeAdViewBinder : NSObject

@property (nonatomic, assign, readonly) NSInteger titleLabelTag;
@property (nonatomic, assign, readonly) NSInteger advertiserLabelTag;
@property (nonatomic, assign, readonly) NSInteger bodyLabelTag;
@property (nonatomic, assign, readonly) NSInteger callToActionButtonTag;
@property (nonatomic, assign, readonly) NSInteger iconImageViewTag;
@property (nonatomic, assign, readonly) NSInteger iconContentViewTag
    __attribute__((deprecated("Use iconImageViewTag instead.")));
@property (nonatomic, assign, readonly) NSInteger optionsContentViewTag;
@property (nonatomic, assign, readonly) NSInteger mediaContentViewTag;
@property (nonatomic, assign, readonly) NSInteger starRatingContentViewTag;

- (instancetype)initWithBuilderBlock:(NS_NOESCAPE CLXNativeAdViewBinderBuilderBlock)builderBlock NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
