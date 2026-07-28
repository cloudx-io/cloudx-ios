//
//  CLXRevenuePlatform.h
//  CloudXCore
//
//  Mediation platform identifier for publisher-reported impression revenue.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Mediation platform that reported an impression's revenue, passed to
 * -[CloudXCore reportRevenueData:] via CLXRevenueData.
 *
 * Modeled as an open string enum (mirrors CLXAdNetwork) so additional
 * platforms can be added without breaking the API.
 */
typedef NSString *CLXRevenuePlatform NS_STRING_ENUM;

/** AdMob (Google Mobile Ads). */
CLX_PUBLIC FOUNDATION_EXPORT CLXRevenuePlatform const CLXRevenuePlatformAdMob;

/** InMobi mediation. */
CLX_PUBLIC FOUNDATION_EXPORT CLXRevenuePlatform const CLXRevenuePlatformInMobi;

/** TopOn mediation. */
CLX_PUBLIC FOUNDATION_EXPORT CLXRevenuePlatform const CLXRevenuePlatformTopOn;

/**
 * @brief Creates a platform for any mediation SDK without a dedicated constant.
 * @param name Platform name sent to CloudX services. Surrounding whitespace is removed while
 * casing is preserved.
 * @return A custom revenue platform name.
 */
CLX_PUBLIC FOUNDATION_EXPORT CLXRevenuePlatform CLXRevenuePlatformCustom(NSString *name)
    NS_SWIFT_NAME(CLXRevenuePlatform.custom(_:));

NS_ASSUME_NONNULL_END
