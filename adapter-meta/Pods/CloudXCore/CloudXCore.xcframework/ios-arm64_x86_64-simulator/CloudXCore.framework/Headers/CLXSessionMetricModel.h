#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXSessionMetricModel : NSManagedObject

@property (nonatomic, copy, nullable) NSString *placementID;
@property (nonatomic, copy, nullable) NSString *type;
@property (nonatomic, assign) double value;
@property (nonatomic, strong, nullable) NSDate *timestamp;

@end

NS_ASSUME_NONNULL_END 