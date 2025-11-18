//
//  CLXMetaInitializer.h
//  CloudXMetaAdapter
//
//  Created by CLX on 2024-02-14.
//
#import <CloudXCore/CloudXCore.h>

@class CLXSettings;

@interface CLXMetaInitializer : NSObject <CLXAdNetworkInitializer>

@property (nonatomic, strong, readonly) NSString *sdkVersion;
@property (nonatomic, strong, readonly) NSString *network;

+ (BOOL)isInitialized;
+ (instancetype)createInstance;
+ (NSString *)sdkVersion;

- (void)initializeWithConfig:(nullable CLXBidderConfig *)config 
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end 
