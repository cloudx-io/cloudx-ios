#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAppSession.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Service for managing app session lifecycle and metrics
 */
@interface CLXAppSessionService : NSObject <CLXAppSessionMetric>

@property (nonatomic, readonly) NSTimeInterval sessionDuration;
@property (nonatomic, readonly) id currentSession;

- (instancetype)initWithSessionID:(NSString *)sessionID 
                           appKey:(NSString *)appKey 
                              url:(NSString *)url;

@end

NS_ASSUME_NONNULL_END 