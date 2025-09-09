#import <Foundation/Foundation.h>

@class CLXRillImpressionModel;

NS_ASSUME_NONNULL_BEGIN

@interface CLXRillImpressionInitService : NSObject

+ (NSString *)createDataStringWithRillImpressionModel:(CLXRillImpressionModel *)rillImpressionModel;

@end

NS_ASSUME_NONNULL_END 