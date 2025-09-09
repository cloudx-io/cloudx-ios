#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAppSessionModel.h>
#import <CloudXCore/CLXSessionMetric.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXAppSessionMetric <NSObject>
- (void)addSpendWithPlacementID:(NSString *)placementID spend:(double)spend;
- (void)addClickWithPlacementID:(NSString *)placementID;
- (void)addImpressionWithPlacementID:(NSString *)placementID;
- (void)addCloseWithPlacementID:(NSString *)placementID latency:(double)latency;
- (void)adFailedToLoadWithPlacementID:(NSString *)placementID;
- (void)bidLoadedWithPlacementID:(NSString *)placementID latency:(double)latency;
- (void)adLoadedWithPlacementID:(NSString *)placementID latency:(double)latency;
@end

@interface CLXAppSession : NSObject <CLXAppSessionMetric>

@property (nonatomic, copy, readonly) NSString *sessionID;
@property (nonatomic, strong, readonly) NSDate *startDate;
@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, copy, readonly) NSString *appKey;
@property (nonatomic, copy, readonly) NSString *description;
@property (nonatomic, strong, readonly) NSMutableArray<id<CLXSessionMetric>> *metrics;
@property (nonatomic, assign, readonly) double sessionDuration;

- (instancetype)initWithSessionID:(NSString *)sessionID 
                             url:(NSURL *)url 
                           appKey:(NSString *)appKey;

- (instancetype)initWithModel:(CLXAppSessionModel *)model;

@end

NS_ASSUME_NONNULL_END 