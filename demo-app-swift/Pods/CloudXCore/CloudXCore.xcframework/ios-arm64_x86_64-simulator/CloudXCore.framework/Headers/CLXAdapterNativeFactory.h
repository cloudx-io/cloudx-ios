//
//  CloudXAdapterNativeFactory.h
//  CloudXCore
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXNativeTemplate.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXAdapterNative;
@protocol CLXAdapterNativeDelegate;

/// Factory for creating native ad adapters.
@protocol CLXAdapterNativeFactory <NSObject>

/// Creates a new instance of CLXAdapterNative with the given parameters.
/// - Parameters:
///   - viewController: viewController where the native ad will be displayed
///   - type: native template type (small, medium)
///   - adId: id of ad from bid response
///   - bidId: bid id from bid response
///   - adm: ad markup with data for rendering
///   - extras: adapters extra info
///   - delegate: delegate for the adapter
/// - Returns: CLXAdapterNative instance
- (nullable id<CLXAdapterNative>)createWithViewController:(UIViewController *)viewController
                                                       type:(CLXNativeTemplate)type
                                                       adId:(NSString *)adId
                                                      bidId:(NSString *)bidId
                                                        adm:(NSString *)adm
                                                     extras:(NSDictionary<NSString *, NSString *> *)extras
                                                   delegate:(id<CLXAdapterNativeDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 