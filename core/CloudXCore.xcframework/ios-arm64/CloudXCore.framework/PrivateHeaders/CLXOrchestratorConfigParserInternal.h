#import <Foundation/Foundation.h>

@class CLXOrchestratorConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface CLXOrchestratorConfigParser : NSObject
- (CLXOrchestratorConfiguration *)parseConfigurationFromResponse:(NSDictionary<NSString *, id> *)response;
@end

NS_ASSUME_NONNULL_END
