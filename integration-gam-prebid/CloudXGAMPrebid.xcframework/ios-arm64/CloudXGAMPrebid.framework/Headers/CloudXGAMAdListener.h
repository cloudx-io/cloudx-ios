//
//  CloudXGAMAdListener.h
//  CloudXGAMPrebid
//

#import <Foundation/Foundation.h>

@class CloudXGAMKeyValues;

NS_ASSUME_NONNULL_BEGIN

/**
 * Publisher callbacks for a GAM prebid facade.
 *
 * `onAdReady:` delivers the key-values to attach to the next GAM request.
 */
@protocol CloudXGAMAdListener <NSObject>

/** @brief CloudX filled; attach these key-values to the GAM request. */
- (void)onAdReady:(CloudXGAMKeyValues *)keyValues;

/** @brief CloudX load failed for `placement`. */
- (void)onAdLoadFailed:(NSString *)placement error:(nullable NSError *)error;

@optional

/** @brief CloudX creative displayed via the GAM custom event. */
- (void)onAdDisplayed;

/** @brief CloudX creative hidden. */
- (void)onAdHidden;

/** @brief The publisher tapped the CloudX creative. */
- (void)onAdClicked;

/** @brief The CloudX creative failed to display. */
- (void)onAdDisplayFailed:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END
