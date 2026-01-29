//
//  CLXMetaInitializer.h
//  CloudXMetaAdapter
//

#import <CloudXCore/CloudXCore.h>

@interface CLXMetaInitializer : NSObject <CLXAdNetworkInitializer>

@property (nonatomic, strong, readonly) NSString *sdkVersion;
@property (nonatomic, strong, readonly) NSString *network;

+ (BOOL)isInitialized;
+ (instancetype)createInstance;
+ (NSString *)sdkVersion;

- (void)initializeWithConfig:(nullable CLXBidderConfig *)config 
                    testMode:(BOOL)testMode
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end 
