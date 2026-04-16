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
- (NSDictionary<NSString *, id> *)getInitData;
@property (nonatomic, readonly) NSString *networkName;
@end

@interface CLXSDKConfigBidder : NSObject <CLXBidderConfig>

@property (nonatomic, strong) NSDictionary<NSString *, id> *bidderInitData;
@property (nonatomic, strong) NSString *networkName;

/**
 * Server-configurable per-adapter initialization timeout in milliseconds.
 * 0 means no timeout (unlimited wait). Parsed from the @c initTimeoutMs JSON field.
 */
@property (nonatomic, assign) NSInteger initTimeoutMs;

- (instancetype)initWithBidderInitData:(NSDictionary<NSString *, id> *)bidderInitData
                    networkName:(NSString *)networkName;

- (NSString *)networkNameMapped;

@end

NS_ASSUME_NONNULL_END 