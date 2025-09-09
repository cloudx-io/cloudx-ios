//
//  SessionMetricPerformance.h
//  CloudXCore
//
//  Created by Bryan Boyko on 5/22/25.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXSessionMetricModel.h>
#import <CloudXCore/CLXSessionMetric.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXSessionMetricPerformance : NSObject <CLXSessionMetric>

@property (nonatomic, copy) NSString *placementID;
@property (nonatomic, assign) NSInteger adLoadCount;
@property (nonatomic, assign) double adLoadLatency;
@property (nonatomic, assign) double bidRequestLatency;
@property (nonatomic, assign) NSInteger bidResponseCount;
@property (nonatomic, assign) NSInteger clickCount;
@property (nonatomic, assign) NSInteger closeCount;
@property (nonatomic, assign) double closeLatency;
@property (nonatomic, assign) NSInteger failToLoadAdCount;
@property (nonatomic, assign) NSInteger impressionCount;

- (instancetype)initWithPlacementID:(NSString *)placementID
                        adLoadCount:(NSInteger)adLoadCount
                     adLoadLatency:(double)adLoadLatency
                 bidRequestLatency:(double)bidRequestLatency
                  bidResponseCount:(NSInteger)bidResponseCount
                        clickCount:(NSInteger)clickCount
                        closeCount:(NSInteger)closeCount
                     closeLatency:(double)closeLatency
                failToLoadAdCount:(NSInteger)failToLoadAdCount
                   impressionCount:(NSInteger)impressionCount;

@end

NS_ASSUME_NONNULL_END 