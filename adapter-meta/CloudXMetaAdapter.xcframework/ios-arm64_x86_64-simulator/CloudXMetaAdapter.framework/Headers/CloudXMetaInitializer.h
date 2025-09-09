//
//  CloudXMetaInitializer.h
//  CloudXMetaAdapter
//
//  Created by CloudX on 2024-02-14.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CloudXMetaInitializer : NSObject <CloudXAdNetworkInitializer>

@property (nonatomic, copy) NSString *sdkVersion;

- (instancetype)initWithAppID:(NSString *)appID;

- (void)initializeWithConfig:(nullable CloudXBidderConfig *)config
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END 
