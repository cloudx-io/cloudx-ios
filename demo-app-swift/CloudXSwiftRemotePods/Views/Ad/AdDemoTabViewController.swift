import UIKit

class AdDemoTabViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create view controllers
        let initVC = InitViewController()
        initVC.tabBarItem = UITabBarItem(title: "Init", image: UIImage(systemName: "power"), tag: 0)
        
        let initInternalVC = InitInternalViewController()
        initInternalVC.tabBarItem = UITabBarItem(title: "Init Internal", image: UIImage(systemName: "gear"), tag: 9)
        
        let bannerVC = BannerViewController()
        bannerVC.tabBarItem = UITabBarItem(title: "Banner", image: UIImage(systemName: "rectangle"), tag: 1)
        
        let interstitialVC = InterstitialViewController()
        interstitialVC.tabBarItem = UITabBarItem(title: "Interstitial", image: UIImage(systemName: "square"), tag: 2)
        
        let rewardedVC = RewardedViewController()
        rewardedVC.tabBarItem = UITabBarItem(title: "Rewarded", image: UIImage(systemName: "star"), tag: 3)
        
        let mrecVC = MRECViewController()
        mrecVC.tabBarItem = UITabBarItem(title: "MREC", image: UIImage(systemName: "rectangle.3.group"), tag: 4)
        
        let nativeVC = NativeViewController()
        nativeVC.tabBarItem = UITabBarItem(title: "Native", image: UIImage(systemName: "doc"), tag: 5)
        
        let nativeBannerVC = NativeBannerViewController()
        nativeBannerVC.tabBarItem = UITabBarItem(title: "Native Banner", image: UIImage(systemName: "doc.badge.plus"), tag: 6)
        
        let rewardedInterstitialVC = RewardedInterstitialViewController()
        rewardedInterstitialVC.tabBarItem = UITabBarItem(title: "Reward Inter", image: UIImage(systemName: "star.square"), tag: 7)
        
        let privacyVC = PrivacyViewController()
        privacyVC.tabBarItem = UITabBarItem(title: "Privacy", image: UIImage(systemName: "hand.raised"), tag: 8)
        
        let settingsVC = SettingsViewController()
        settingsVC.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "star"), tag: 9)
        
        // Set view controllers - InitInternalVC moved to end so it appears in "More" section
        self.viewControllers = [
            UINavigationController(rootViewController: initVC),
            UINavigationController(rootViewController: bannerVC),
            UINavigationController(rootViewController: interstitialVC),
            UINavigationController(rootViewController: rewardedVC),
            UINavigationController(rootViewController: mrecVC),
            UINavigationController(rootViewController: nativeVC),
            UINavigationController(rootViewController: nativeBannerVC),
            UINavigationController(rootViewController: rewardedInterstitialVC),
            UINavigationController(rootViewController: privacyVC),
            UINavigationController(rootViewController: initInternalVC),
            UINavigationController(rootViewController: settingsVC)
        ]
    }
}