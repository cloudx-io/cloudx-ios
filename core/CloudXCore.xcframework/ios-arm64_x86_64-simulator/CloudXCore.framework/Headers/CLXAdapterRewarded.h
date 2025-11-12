//
//  CloudXAdapterRewarded.h
//  CloudXCore
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXAdapterRewardedDelegate;

/// Protocol for rewarded adapters.
@protocol CLXAdapterRewarded <NSObject>

/// Delegate for the adapter, used to notify about ad events.
@property (nonatomic, weak) id<CLXAdapterRewardedDelegate> delegate;

/// SDK version of the adapter.
@property (nonatomic, strong, readonly) NSString *sdkVersion;

/// Network name of the adapter. F.e. "AdMob", "Facebook", etc.
@property (nonatomic, strong, readonly) NSString *network;

/// Ad id from bid response.
@property (nonatomic, strong, readonly) NSString *bidID;

/// Whether the ad is ready to be shown.
@property (nonatomic, assign, readonly) BOOL isReady;

/// Loads the rewarded adapter.
- (void)load;

/// Shows the rewarded adapter.
/// - Parameter viewController: view controller where the interstitial will be displayed
- (void)showFromViewController:(UIViewController *)viewController;

@end

/// Delegate for the rewarded adapter.
@protocol CLXAdapterRewardedDelegate <NSObject>

/// Called when the adapter has loaded the rewarded.
/// - Parameter rewarded: the rewarded that was loaded
- (void)didLoadWithRewarded:(id<CLXAdapterRewarded>)rewarded;

/// Called when the adapter failed to load the rewarded.
/// - Parameter rewarded: the rewarded that failed to load
/// - Parameter error: the error that caused the failure
- (void)didFailToLoadWithRewarded:(id<CLXAdapterRewarded>)rewarded error:(NSError *)error;

/// Called when the adapter has shown the rewarded.
/// - Parameter rewarded: the rewarded that was shown
- (void)didShowWithRewarded:(id<CLXAdapterRewarded>)rewarded;

/// Called when the adapter has tracked impression.
/// - Parameter rewarded: the rewarded that was shown
- (void)impressionWithRewarded:(id<CLXAdapterRewarded>)rewarded;

/// Called when the adapter has closed the rewarded.
/// - Parameter rewarded: the rewarded that was closed
- (void)didCloseWithRewarded:(id<CLXAdapterRewarded>)rewarded;

/// Called when the adapter has failed to show the rewarded.
/// - Parameter rewarded: the rewarded that failed to show
/// - Parameter error: error that caused the failure
- (void)didFailToShowWithRewarded:(id<CLXAdapterRewarded>)rewarded error:(NSError *)error;

/// Called when the adapter has clicked the rewarded.
/// - Parameter rewarded: the rewarded that was clicked
- (void)clickWithRewarded:(id<CLXAdapterRewarded>)rewarded;

/// Called when the adapter has expired the rewarded.
/// - Parameter rewarded: the rewarded that was expired
- (void)expiredWithRewarded:(id<CLXAdapterRewarded>)rewarded;

/// Called when the adapter has rewarded the user.
/// - Parameter rewarded: the rewarded that was rewarded
- (void)userRewardWithRewarded:(id<CLXAdapterRewarded>)rewarded;

@end

NS_ASSUME_NONNULL_END 