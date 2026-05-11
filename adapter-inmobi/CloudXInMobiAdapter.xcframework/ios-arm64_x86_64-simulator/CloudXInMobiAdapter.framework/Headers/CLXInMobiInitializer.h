//
//  CLXInMobiInitializer.h
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXInMobiInitializer : CLXAdNetworkInitializer

+ (BOOL)isInitialized;
+ (NSString *)sdkVersion;
+ (NSDictionary<NSString *, NSString *> *)extras;

- (void)initializeWithConfig:(nullable CLXBidderConfig *)config
                    testMode:(BOOL)testMode
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
