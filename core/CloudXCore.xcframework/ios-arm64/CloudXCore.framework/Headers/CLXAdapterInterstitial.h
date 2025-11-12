//
//  CloudXAdapterInterstitial.h
//  CloudXCore
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXAdapterInterstitialDelegate;

/// Protocol for interstitial adapters. Interstitial adapters are responsible for loading and showing interstitial ads.
@protocol CLXAdapterInterstitial <NSObject>

/// Delegate for the adapter, used to notify about ad events.
@property (nonatomic, weak) id<CLXAdapterInterstitialDelegate> delegate;

/// SDK version of the adapter.
@property (nonatomic, strong, readonly) NSString *sdkVersion;

/// Network name of the adapter. F.e. "AdMob", "Facebook", etc.
@property (nonatomic, strong, readonly) NSString *network;

/// Ad id from bid response.
@property (nonatomic, strong, readonly) NSString *bidID;

/// Loads the adapter interstitial.
- (void)load;

/// Shows the adapter interstitial.
/// - Parameter viewController: view controller where the interstitial will be displayed
- (void)showFromViewController:(UIViewController *)viewController;

@end

/// Delegate for the interstitial adapter.
@protocol CLXAdapterInterstitialDelegate <NSObject>

/// Called when the adapter has loaded the interstitial.
/// - Parameter interstitial: the interstitial that was loaded
- (void)didLoadWithInterstitial:(id<CLXAdapterInterstitial>)interstitial;

/// Called when the adapter failed to load the interstitial.
/// - Parameters:
///   - interstitial: the interstitial that failed to load
///   - error: the error that caused the failure
- (void)didFailToLoadWithInterstitial:(id<CLXAdapterInterstitial>)interstitial error:(NSError *)error;

/// Called when the adapter has shown the interstitial.
/// - Parameter interstitial: the interstitial that was shown
- (void)didShowWithInterstitial:(id<CLXAdapterInterstitial>)interstitial;

/// Called when the adapter has failed to show the interstitial.
/// - Parameters:
///   - interstitial: the interstitial that failed to show
///   - error: error that caused the failure
- (void)didFailToShowWithInterstitial:(id<CLXAdapterInterstitial>)interstitial error:(NSError *)error;

/// Called when the adapter has tracked impression.
/// - Parameter interstitial: the interstitial that was shown
- (void)impressionWithInterstitial:(id<CLXAdapterInterstitial>)interstitial;

/// Called when the adapter has closed the interstitial.
/// - Parameter interstitial: the interstitial that was closed
- (void)didCloseWithInterstitial:(id<CLXAdapterInterstitial>)interstitial;

/// Called when the adapter has tracked click.
/// - Parameter interstitial: interstitial that was clicked
- (void)clickWithInterstitial:(id<CLXAdapterInterstitial>)interstitial;

/// Called when the adapter has expired the interstitial.
/// - Parameter interstitial: interstitial that was expired
- (void)expiredWithInterstitial:(id<CLXAdapterInterstitial>)interstitial;

@end

NS_ASSUME_NONNULL_END 