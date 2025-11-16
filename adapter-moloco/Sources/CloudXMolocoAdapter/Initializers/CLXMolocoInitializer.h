//
//  CLXMolocoInitializer.h
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#import <CloudXCore/CloudXCore.h>

@class CLXSettings;

@interface CLXMolocoInitializer : NSObject <CLXAdNetworkInitializer>

@property (nonatomic, strong, readonly) NSString *sdkVersion;
@property (nonatomic, strong, readonly) NSString *network;

+ (BOOL)isInitialized;
+ (instancetype)createInstance;
+ (NSString *)sdkVersion;

- (void)initializeWithConfig:(nullable CLXBidderConfig *)config 
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

