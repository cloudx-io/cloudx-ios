/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXNativeAdImage;

CLX_PUBLIC
@interface CLXNativeAdBuilder : NSObject

@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *advertiser;
@property (nonatomic, copy, nullable) NSString *body;
@property (nonatomic, copy, nullable) NSString *callToAction;
@property (nonatomic, strong, nullable) CLXNativeAdImage *icon;
@property (nonatomic, strong, nullable) CLXNativeAdImage *mainImage;
@property (nonatomic, strong, nullable) UIView *iconView;
@property (nonatomic, strong, nullable) UIView *mediaView;
@property (nonatomic, strong, nullable) UIView *optionsView;
@property (nonatomic, assign) CGFloat mediaContentAspectRatio;
@property (nonatomic, strong, nullable) NSNumber *starRating;
@property (nonatomic, assign) BOOL isVideoContent;
@property (nonatomic, assign) NSTimeInterval videoDuration;

@end

NS_ASSUME_NONNULL_END
