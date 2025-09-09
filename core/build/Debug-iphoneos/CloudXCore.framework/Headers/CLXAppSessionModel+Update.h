#import <CloudXCore/CLXAppSessionModel.h>
#import <CloudXCore/CLXSessionMetricModel.h>
#import <CloudXCore/CLXPerformanceMetricModel.h>
#import <CloudXCore/CLXAppSession.h>
#import <CloudXCore/CLXSessionMetricSpend.h>
#import <CloudXCore/CLXCoreDataManager.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXAppSessionModel (Update)

- (void)updateWithSession:(CLXAppSession *)session;

@end

NS_ASSUME_NONNULL_END 