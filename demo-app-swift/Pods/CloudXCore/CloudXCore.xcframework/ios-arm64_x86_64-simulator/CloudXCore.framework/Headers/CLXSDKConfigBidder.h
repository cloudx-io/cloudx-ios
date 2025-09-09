//
// SDKConfigBidder.h
// CloudXCore
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SDKConfigKnownAdapterName) {
    SDKConfigKnownAdapterNameDemo = 0,
    SDKConfigKnownAdapterNameAdManager,
    SDKConfigKnownAdapterNameMeta,
    SDKConfigKnownAdapterNameMintegral,
    SDKConfigKnownAdapterNameCloudX
};

@protocol CLXBidderConfig <NSObject>
- (NSDictionary<NSString *, NSString *> *)getInitData;
@property (nonatomic, readonly) NSString *networkName;
@end

@interface CLXSDKConfigBidder : NSObject <CLXBidderConfig>

@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *bidderInitData;
@property (nonatomic, strong) NSString *networkName;

- (instancetype)initWithBidderInitData:(NSDictionary<NSString *, NSString *> *)bidderInitData
                    networkName:(NSString *)networkName;

- (NSString *)networkNameMapped;

@end

NS_ASSUME_NONNULL_END 