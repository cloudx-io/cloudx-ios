/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CloudXBannerType.h
 * @brief Banner ad type enumeration
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CloudXBannerType is a public enumeration that represents different types of banner ads that can be served.
 * This enumeration can be used to specify the type and size of a banner ad when requesting ads from the CloudX SDK.
 */
typedef NS_ENUM(NSInteger, CLXBannerType) {
    /**
     * This case represents a banner ad with a width of 320 and a height of 50.
     * If the device type is a tablet, the size is adjusted to 728x90.
     */
    CLXBannerTypeW320H50 = 0,
    
    /**
     * This case represents a medium rectangle ad (also known as "medium rectangle") with a size of 300x250.
     */
    CLXBannerTypeMREC = 1
};

/**
 * Category to add size calculation functionality to CloudXBannerType
 */
@interface NSValue (CLXBannerType)

/**
 * Returns the size of the banner ad as a CGSize based on the enumeration case.
 * The size is determined by the device type for the CloudXBannerTypeW320H50 case.
 * @param bannerType The banner type
 * @return The size for the banner type
 */
+ (CGSize)sizeForBannerType:(CLXBannerType)bannerType;

@end

NS_ASSUME_NONNULL_END 