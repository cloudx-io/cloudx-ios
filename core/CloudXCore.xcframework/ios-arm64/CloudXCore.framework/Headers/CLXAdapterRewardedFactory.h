//
//  CloudXAdapterRewardedFactory.h
//  CloudXCore
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXAdapterRewarded;
@protocol CLXAdapterRewardedDelegate;

/// Factory for rewarded adapters.
@protocol CLXAdapterRewardedFactory <NSObject>

/// Creates a new instance of CloudXAdapterRewarded with the given parameters.
/// - Parameters:
///   - adId: id of ad from bid response
///   - bidId: bid id from bid response
///   - adm: ad markup with data for rendering
///   - extras: adapters extra info
///   - delegate: delegate for the adapter
/// - Returns: new instance of CloudXAdapterRewarded
- (nullable id<CLXAdapterRewarded>)createWithAdId:(NSString *)adId
                                              bidId:(NSString *)bidId
                                                adm:(NSString *)adm
                                             extras:(NSDictionary<NSString *, NSString *> *)extras
                                           delegate:(id<CLXAdapterRewardedDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 