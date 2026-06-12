#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdNetworkInitializer.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMintegralInitializer : CLXAdNetworkInitializer

@property (nonatomic, copy, readonly) NSString *sdkVersion;
@property (nonatomic, copy, readonly) NSString *network;

+ (NSString *)sdkVersion;

- (void)initializeWithConfig:(nullable CLXBidderConfig *)config
                    testMode:(BOOL)testMode
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
