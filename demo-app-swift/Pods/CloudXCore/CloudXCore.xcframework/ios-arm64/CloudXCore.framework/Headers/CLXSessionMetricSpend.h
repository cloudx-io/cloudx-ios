//
//  SessionMetricSpend.h
//  CloudXCore
//
//  Created by Bryan Boyko on 5/22/25.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXSessionMetric.h>
#import <CloudXCore/CLXSessionMetricType.h>
#import <CloudXCore/CLXSessionMetricModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXSessionMetricSpend : NSObject <CLXSessionMetric>

@property (nonatomic, copy, readonly) NSString *placementID;
@property (nonatomic, assign, readonly) CLXSessionMetricType type;
@property (nonatomic, assign, readonly) double value;
@property (nonatomic, strong, readonly) NSDate *timestamp;

- (instancetype)initWithPlacementID:(NSString *)placementID
                                                               type:(CLXSessionMetricType)type
                               value:(double)value
                            timestamp:(NSDate *)timestamp;

- (instancetype)initWithMetricModel:(CLXSessionMetricModel *)model;

- (NSString *)typeString;

@end

NS_ASSUME_NONNULL_END 