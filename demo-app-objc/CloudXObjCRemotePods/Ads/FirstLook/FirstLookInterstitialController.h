#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** The network that supplied an interstitial in this First Look pass. `None` means no ad. */
typedef NS_ENUM(NSInteger, FirstLookSource) {
    FirstLookSourceNone = -1,
    FirstLookSourceCloudX,
    FirstLookSourceAdMob,
};

/** "CLOUDX" or "ADMOB" for the status text and logs. */
NSString *NSStringFromFirstLookSource(FirstLookSource source);

typedef NS_ENUM(NSInteger, FirstLookEventType) {
    FirstLookEventTypeLoaded,
    FirstLookEventTypeLoadFailed,
    FirstLookEventTypeShown,
    FirstLookEventTypeShowFailed,
    FirstLookEventTypeClosed,
    FirstLookEventTypeClicked,
};

/** An event from either interstitial SDK, with the source attached. `message` is set for the failures. */
@interface FirstLookEvent : NSObject

@property (nonatomic, readonly) FirstLookEventType type;
@property (nonatomic, readonly) FirstLookSource source;
@property (nonatomic, copy, readonly, nullable) NSString *message;

+ (instancetype)eventWithType:(FirstLookEventType)type
                       source:(FirstLookSource)source
                      message:(nullable NSString *)message;

@end

typedef void (^FirstLookEventHandler)(FirstLookEvent *event);

/** A one-use fullscreen ad source. The owning screen releases it through `dispose`. */
@protocol FirstLookInterstitialSource <NSObject>

@property (nonatomic, copy, nullable) FirstLookEventHandler onEvent;
@property (nonatomic, readonly) BOOL isReady;

- (void)load;
- (void)show;
- (void)dispose;

@end

/**
 * Gives CloudX the first load attempt. AdMob loads only after CloudX fails or is unavailable.
 * A new `load` after an ad closes starts a new CloudX-first pass.
 *
 * Pass nil for `cloudX` when CloudX initialization failed, so every load goes straight to AdMob.
 * Both sources report on the main queue, so `onEvent` is called there too.
 */
@interface FirstLookInterstitialController : NSObject

- (instancetype)initWithCloudX:(nullable id<FirstLookInterstitialSource>)cloudX
                         adMob:(id<FirstLookInterstitialSource>)adMob
                       onEvent:(FirstLookEventHandler)onEvent NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/** The source that would show now, or `FirstLookSourceNone`. */
@property (nonatomic, readonly) FirstLookSource readySource;

- (void)load;

/** Returns the selected source, or `FirstLookSourceNone` when the app should continue without an ad. */
- (FirstLookSource)show;

- (void)dispose;

@end

NS_ASSUME_NONNULL_END
