#import "AdDemoTabViewController.h"
#import "InitInternalViewController.h"
#import "BannerViewController.h"
#import "InterstitialViewController.h"
#import "RewardedViewController.h"
#import "MRECViewController.h"
#import "SettingsViewController.h"
#import "KeyValueDemoViewController.h"

@implementation AdDemoTabViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create view controllers
    InitInternalViewController *initInternalVC = [[InitInternalViewController alloc] init];
    initInternalVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Init" image:[UIImage systemImageNamed:@"power"] tag:0];
    
    BannerViewController *bannerVC = [[BannerViewController alloc] init];
    bannerVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Banner" image:[UIImage systemImageNamed:@"rectangle"] tag:1];
    
    InterstitialViewController *interstitialVC = [[InterstitialViewController alloc] init];
    interstitialVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Interstitial" image:[UIImage systemImageNamed:@"square"] tag:2];
    
    RewardedViewController *rewardedVC = [[RewardedViewController alloc] init];
    rewardedVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Rewarded" image:[UIImage systemImageNamed:@"star"] tag:3];
    
    MRECViewController *mrecVC = [[MRECViewController alloc] init];
    mrecVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"MREC" image:[UIImage systemImageNamed:@"rectangle.3.group"] tag:4];
    
    KeyValueDemoViewController *keyValueVC = [[KeyValueDemoViewController alloc] init];
    keyValueVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Key-Values" image:[UIImage systemImageNamed:@"key.fill"] tag:5];
    
    SettingsViewController *settinsVC = [[SettingsViewController alloc] init];
    settinsVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Settings" image:[UIImage systemImageNamed:@"gearshape"] tag:6];

    
    // Set view controllers
    self.viewControllers = @[
        [[UINavigationController alloc] initWithRootViewController:initInternalVC],
        [[UINavigationController alloc] initWithRootViewController:bannerVC],
        [[UINavigationController alloc] initWithRootViewController:interstitialVC],
        [[UINavigationController alloc] initWithRootViewController:rewardedVC],
        [[UINavigationController alloc] initWithRootViewController:mrecVC],
        [[UINavigationController alloc] initWithRootViewController:keyValueVC],
        [[UINavigationController alloc] initWithRootViewController:settinsVC]
    ];
}

- (void)selectTabIndex:(NSUInteger)index {
    if (index < self.viewControllers.count) {
        self.selectedIndex = index;
    }
}

@end 
