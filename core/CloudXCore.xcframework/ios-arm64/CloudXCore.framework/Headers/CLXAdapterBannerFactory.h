//
//  CloudXAdapterBannerFactory.h
//  CloudXCore
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXBannerType.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXAdapterBanner;
@protocol CLXAdapterBannerDelegate;

/// Factory for creating banner ad adapters.
@protocol CLXAdapterBannerFactory <NSObject>

/// Creates a new instance of CloudXAdapterBanner with the given parameters.
/// - Parameters:
///   - viewController: viewController where the banner will be displayed
///   - type: type of the banner (mrec, banner, etc.)
///   - adId: id of ad from bid response
///   - bidId: bid id from bid response
///   - adm: ad markup with data for rendering
///   - hasClosedButton: whether the banner has a close button
///   - extras: adapters extra info
///   - delegate: delegate for the adapter
/// - Returns: CloudXAdapterBanner instance
- (nullable id<CLXAdapterBanner>)createWithViewController:(UIViewController *)viewController
                                                        type:(CLXBannerType)type
                                                        adId:(NSString *)adId
                                                       bidId:(NSString *)bidId
                                                         adm:(NSString *)adm
                                             hasClosedButton:(BOOL)hasClosedButton
                                                      extras:(NSDictionary<NSString *, NSString *> *)extras
                                                    delegate:(id<CLXAdapterBannerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 