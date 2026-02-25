//
//  CloudXAdapterBannerFactory.h
//  CloudXCore
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBannerType.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXAdapterBanner;
@protocol CLXAdapterBannerDelegate;

/// Factory for creating banner ad adapters.
@protocol CLXAdapterBannerFactory <NSObject>

/// Creates a new instance of CloudXAdapterBanner with the given parameters.
/// - Parameters:
///   - type: type of the banner (mrec, banner, etc.)
///   - adId: id of ad from bid response
///   - bidId: bid id from bid response
///   - adm: ad markup with data for rendering
///   - hasClosedButton: whether the banner has a close button
///   - extras: adapters extra info
///   - adUnitName: CloudX ad unit name for error messaging (may be nil for legacy callers)
///   - delegate: delegate for the adapter
/// - Returns: CloudXAdapterBanner instance
- (nullable id<CLXAdapterBanner>)createWithType:(CLXBannerType)type
                                                       adId:(NSString *)adId
                                                      bidId:(NSString *)bidId
                                                        adm:(NSString *)adm
                                            hasClosedButton:(BOOL)hasClosedButton
                                                     extras:(NSDictionary<NSString *, NSString *> *)extras
                                              adUnitName:(nullable NSString *)adUnitName
                                                   delegate:(id<CLXAdapterBannerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END