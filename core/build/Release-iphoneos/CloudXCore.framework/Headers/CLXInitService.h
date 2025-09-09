#import <Foundation/Foundation.h>
#import <CloudXCore/CLXSDKConfig.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXInitService <NSObject>

- (void)initSDKWithAppKey:(NSString *)appKey completion:(void (^)(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END 