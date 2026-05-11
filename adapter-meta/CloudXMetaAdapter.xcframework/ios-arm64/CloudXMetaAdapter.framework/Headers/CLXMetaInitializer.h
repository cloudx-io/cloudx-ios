//
//  CLXMetaInitializer.h
//  CloudXMetaAdapter
//

#import <CloudXCore/CloudXCore.h>

@interface CLXMetaInitializer : CLXAdNetworkInitializer

@property (nonatomic, copy, readonly) NSString *sdkVersion;
@property (nonatomic, copy, readonly) NSString *network;

+ (BOOL)isInitialized;
+ (NSString *)sdkVersion;

- (void)initializeWithConfig:(nullable CLXBidderConfig *)config 
                    testMode:(BOOL)testMode
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end 
