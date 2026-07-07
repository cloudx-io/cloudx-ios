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

@interface CLXSDKConfigBidder : NSObject

@property (nonatomic, strong) NSDictionary<NSString *, id> *bidderInitData;
@property (nonatomic, strong) NSString *networkName;

/**
 * Server-configurable per-adapter soft initialization deadline in milliseconds.
 * When the deadline elapses, SDK init stops waiting on this adapter but the adapter
 * keeps initializing in the background and joins later auctions once it settles.
 * Parsed from the @c softInitTimeoutMs JSON field; the parser resolves a 5000ms
 * default when the field is absent or non-positive, so this is always a concrete
 * positive deadline by the time initialization reads it.
 */
@property (nonatomic, assign) NSInteger softInitTimeoutMs;

/**
 * The soft init deadline (ms) applied when the server sends no positive value.
 * Single source of truth for the default so the parser and the init loop can't drift.
 */
+ (NSInteger)defaultSoftTimeoutMs;

/**
 * Resolves a raw network name to the mapped name the SDK keys readiness and token
 * sources by. The single source of truth for network-name aliasing, so callers that
 * hold only a name string (e.g. the auction coordinator's readiness check) and callers
 * that hold a bidder instance both resolve through the same logic and can't drift.
 * @param name The raw network name as configured.
 * @return The mapped network name, or @c name unchanged when no alias applies.
 */
+ (NSString *)mappedNetworkNameForName:(NSString *)name;

- (instancetype)initWithBidderInitData:(NSDictionary<NSString *, id> *)bidderInitData
                    networkName:(NSString *)networkName;

- (NSString *)networkNameMapped;

@end

NS_ASSUME_NONNULL_END 
