#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AdState) {
    AdStateNoAd,
    AdStateLoading,
    AdStateReady
};

@protocol AdStateManaging <NSObject>
@property (nonatomic, assign) BOOL isLoading;
- (void)updateStatusUIWithState:(AdState)state;
@end

@interface BaseAdViewController : UIViewController <AdStateManaging>

@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIView *statusIndicator;
@property (nonatomic, strong) UIStackView *statusStack;
@property (nonatomic, assign) BOOL isLoading;

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)initializeSDK;
- (void)initializeSDKWithCompletion:(void (^)(BOOL success, NSError *error))completion;
- (void)setupCenteredButtonWithTitle:(NSString *)title action:(SEL)action;

@end

NS_ASSUME_NONNULL_END 