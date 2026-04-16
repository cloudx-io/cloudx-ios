#import <Foundation/Foundation.h>

@class CLXRillImpressionModel;
@class CLXConfigImpressionModel;

NS_ASSUME_NONNULL_BEGIN

@interface CLXRillImpressionInitService : NSObject

/**
 * Seeds the shared field resolver with session and SDK config from the impression model.
 * Call before building legacy payloads when no winning bid context exists yet.
 */
+ (void)applySessionAndConfigFromImpModel:(CLXConfigImpressionModel *)impModel;

/**
 * Creates tracking payload using server-driven field resolution
 * @param rillImpressionModel The impression model containing auction data
 * @return The tracking payload string using server-configured fields, or empty string if no config
 */
+ (NSString *)createDataStringWithRillImpressionModel:(CLXRillImpressionModel *)rillImpressionModel;

@end

NS_ASSUME_NONNULL_END 