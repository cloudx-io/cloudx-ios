#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AdState) {
    AdStateNoAd,
    AdStateLoading,
    AdStateReady
};

typedef NS_OPTIONS(NSUInteger, AdCallbackEvent) {
    AdCallbackEventNone             = 0,
    AdCallbackEventLoaded           = 1 << 0,
    AdCallbackEventRevenueReceived  = 1 << 1,
    AdCallbackEventClicked          = 1 << 2,
    AdCallbackEventDisplayed        = 1 << 3,
    AdCallbackEventHidden           = 1 << 4,
    AdCallbackEventRewarded         = 1 << 5,
};

@protocol AdStateManaging <NSObject>
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) AdCallbackEvent receivedCallbacks;
- (void)updateStatusUIWithState:(AdState)state;
@optional
- (nullable UIView *)adViewForClickTesting;
@end

@interface BaseAdViewController : UIViewController <AdStateManaging>

@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIView *statusIndicator;
@property (nonatomic, strong) UIStackView *statusStack;
@property (nonatomic, strong) UIButton *sdkDebuggerButton;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) AdCallbackEvent receivedCallbacks;

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)initializeSDK;
- (void)initializeSDKWithCompletion:(void (^)(BOOL success, NSError *error))completion;
- (void)setupCenteredButtonWithTitle:(NSString *)title action:(SEL)action;
- (void)showLogsModal;

@end

NS_ASSUME_NONNULL_END 
