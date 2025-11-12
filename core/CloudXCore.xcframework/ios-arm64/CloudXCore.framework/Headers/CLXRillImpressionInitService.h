#import <Foundation/Foundation.h>

@class CLXRillImpressionModel;

NS_ASSUME_NONNULL_BEGIN

@interface CLXRillImpressionInitService : NSObject

/**
 * Creates tracking payload using server-driven field resolution
 * @param rillImpressionModel The impression model containing auction data
 * @return The tracking payload string using server-configured fields, or empty string if no config
 */
+ (NSString *)createDataStringWithRillImpressionModel:(CLXRillImpressionModel *)rillImpressionModel;

@end

NS_ASSUME_NONNULL_END 