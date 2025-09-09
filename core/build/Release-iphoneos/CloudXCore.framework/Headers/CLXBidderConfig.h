//
//  CloudXBidderConfig.h
//  CloudXCore
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>

@class CLXSDKConfigResponse;

NS_ASSUME_NONNULL_BEGIN

/// Configuration for the ad network SDK such as app id, ad unit id, etc.
@interface CLXBidderConfig : NSObject

/// Bid network SDK's specific data required for its initializing.
@property (nonatomic, strong, readonly) NSDictionary<NSString *, NSString *> *initializationData;

/// Bid network's name; required for resolving active bid network adapter implementations on CloudX SDK side.
@property (nonatomic, strong, readonly) NSString *networkName;

- (instancetype)initWithInitializationData:(NSDictionary<NSString *, NSString *> *)initializationData
                                 networkName:(NSString *)networkName;

@end

NS_ASSUME_NONNULL_END 