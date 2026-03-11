//
//  CLXUnityInitializer.h
//  CloudXUnityAdapter
//

#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXUnityInitializer : NSObject <CLXAdNetworkInitializer>

@property (nonatomic, strong, readonly) NSString *sdkVersion;
@property (nonatomic, strong, readonly) NSString *network;

+ (BOOL)isInitialized;
+ (instancetype)createInstance;
+ (NSString *)sdkVersion;

- (void)initializeWithConfig:(nullable CLXBidderConfig *)config
                    testMode:(BOOL)testMode
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
