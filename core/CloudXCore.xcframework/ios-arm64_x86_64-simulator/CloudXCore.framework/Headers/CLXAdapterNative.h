//
//  CloudXAdapterNative.h
//  CloudXCore
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXAdapterNativeDelegate;

/// Protocol for native ad adapters. Native ad adapters are responsible for loading and showing native ads.
@protocol CLXAdapterNative <NSObject>

/// Delegate for the adapter, used to notify about ad events.
@property (nonatomic, weak) id<CLXAdapterNativeDelegate> delegate;

/// Flag to indicate if the native loading timed out.
@property (nonatomic, assign) BOOL timeout;

/// View containing the native ad.
@property (nonatomic, strong, readonly, nullable) UIView *nativeView;

/// SDK version of the adapter.
@property (nonatomic, strong, readonly) NSString *sdkVersion;

/// Loads the native ad.
- (void)load;

/// Shows the native ad from the given view controller.
- (void)showFromViewController:(UIViewController *)viewController;

/// Destroys the native ad.
- (void)destroy;

@end

/// Delegate for the native adapter.
@protocol CLXAdapterNativeDelegate <NSObject>

/// Called when the adapter has loaded the native ad.
/// - Parameter native: the native ad that was loaded
- (void)didLoadWithNative:(id<CLXAdapterNative>)native;

/// Called when the adapter failed to load the native ad.
/// - Parameters:
///   - native: native ad that failed to load
///   - error: error that caused the failure
- (void)failToLoadWithNative:(nullable id<CLXAdapterNative>)native error:(nullable NSError *)error;

/// Called when the adapter has shown the native ad.
/// - Parameter native: the native ad that was shown
- (void)didShowWithNative:(id<CLXAdapterNative>)native;

/// Called when the adapter has tracked impression.
/// - Parameter native: the native ad that was shown
- (void)impressionWithNative:(id<CLXAdapterNative>)native;

/// Called when the adapter has tracked click.
/// - Parameter native: native ad that was clicked
- (void)clickWithNative:(id<CLXAdapterNative>)native;

/// Called when the adapter has tracked close click.
/// - Parameter native: native ad that was closed
- (void)closeWithNative:(id<CLXAdapterNative>)native;

@end

NS_ASSUME_NONNULL_END 