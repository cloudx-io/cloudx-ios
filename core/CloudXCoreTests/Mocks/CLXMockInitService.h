//
//  CLXMockInitService.h
//  CloudXCoreTests
//
//  Mock implementation of CLXInitService for unit testing
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXInitService.h>
#import <CloudXCore/CLXSDKConfig.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMockInitService : NSObject <CLXInitService>

@property (nonatomic, assign) BOOL shouldSucceed;
@property (nonatomic, strong, nullable) NSError *mockError;
@property (nonatomic, strong, nullable) CLXSDKConfigResponse *mockConfig;
@property (nonatomic, assign) NSTimeInterval mockDelay;

- (instancetype)initWithSuccess:(BOOL)shouldSucceed;
- (instancetype)initWithError:(NSError *)error;
- (instancetype)initWithConfig:(CLXSDKConfigResponse *)config;

@end

NS_ASSUME_NONNULL_END
