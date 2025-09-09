//
//  InitMetrics.h
//  CloudXCore
//
//  Created by Bryan Boyko on 6/20/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXInitMetrics : NSObject

@property (nonatomic, copy, readonly) NSString *appKey;
@property (nonatomic, strong, readonly) NSDate *startedAt;
@property (nonatomic, strong, nullable) NSDate *endedAt;
@property (nonatomic, assign) BOOL success;
@property (nonatomic, copy, nullable) NSString *sessionId;

- (instancetype)initWithAppKey:(NSString *)appKey;
- (void)finishWithSessionId:(nullable NSString *)sessionId;

@end

NS_ASSUME_NONNULL_END 