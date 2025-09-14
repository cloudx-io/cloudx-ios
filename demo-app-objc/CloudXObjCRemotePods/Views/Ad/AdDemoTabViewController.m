#import "AdDemoTabViewController.h"
#import "InitViewController.h"
#import "InitInternalViewController.h"
#import "BannerViewController.h"
#import "InterstitialViewController.h"
#import "RewardedViewController.h"
#import "MRECViewController.h"
#import "NativeViewController.h"
#import "NativeBannerViewController.h"
#import "RewardedInterstitialViewController.h"
#import "PrivacyViewController.h"

@implementation AdDemoTabViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create view controllers
    InitViewController *initVC = [[InitViewController alloc] init];
    initVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Init" image:[UIImage systemImageNamed:@"power"] tag:0];
    
    InitInternalViewController *initInternalVC = [[InitInternalViewController alloc] init];
    initInternalVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Init Internal" image:[UIImage systemImageNamed:@"gear"] tag:9];
    
    BannerViewController *bannerVC = [[BannerViewController alloc] init];
    bannerVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Banner" image:[UIImage systemImageNamed:@"rectangle"] tag:1];
    
    InterstitialViewController *interstitialVC = [[InterstitialViewController alloc] init];
    interstitialVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Interstitial" image:[UIImage systemImageNamed:@"square"] tag:2];
    
    RewardedViewController *rewardedVC = [[RewardedViewController alloc] init];
    rewardedVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Rewarded" image:[UIImage systemImageNamed:@"star"] tag:3];
    
    MRECViewController *mrecVC = [[MRECViewController alloc] init];
    mrecVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"MREC" image:[UIImage systemImageNamed:@"rectangle.3.group"] tag:4];
    
    NativeViewController *nativeVC = [[NativeViewController alloc] init];
    nativeVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Native" image:[UIImage systemImageNamed:@"doc"] tag:5];
    
    NativeBannerViewController *nativeBannerVC = [[NativeBannerViewController alloc] init];
    nativeBannerVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Native Banner" image:[UIImage systemImageNamed:@"doc.badge.plus"] tag:6];
    
    RewardedInterstitialViewController *rewardedInterstitialVC = [[RewardedInterstitialViewController alloc] init];
    rewardedInterstitialVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Reward Inter" image:[UIImage systemImageNamed:@"star.square"] tag:7];
    
    PrivacyViewController *privacyVC = [[PrivacyViewController alloc] init];
    privacyVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Privacy" image:[UIImage systemImageNamed:@"hand.raised"] tag:8];
    
    // Set view controllers - InitInternalVC moved to end so it appears in "More" section
    self.viewControllers = @[
        [[UINavigationController alloc] initWithRootViewController:initVC],
        [[UINavigationController alloc] initWithRootViewController:bannerVC],
        [[UINavigationController alloc] initWithRootViewController:interstitialVC],
        [[UINavigationController alloc] initWithRootViewController:rewardedVC],
        [[UINavigationController alloc] initWithRootViewController:mrecVC],
        [[UINavigationController alloc] initWithRootViewController:nativeVC],
        [[UINavigationController alloc] initWithRootViewController:nativeBannerVC],
        [[UINavigationController alloc] initWithRootViewController:rewardedInterstitialVC],
        [[UINavigationController alloc] initWithRootViewController:privacyVC],
        [[UINavigationController alloc] initWithRootViewController:initInternalVC]
    ];
}

@end 
