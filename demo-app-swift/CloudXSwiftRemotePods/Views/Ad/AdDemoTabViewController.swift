import UIKit

class AdDemoTabViewController: UITabBarController {

    /// Selects the tab at the given index, handling the "More" tab if needed.
    func selectTab(at index: Int) {
        if index < (viewControllers?.count ?? 0) {
            selectedIndex = index
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create view controllers 
        let initInternalVC = InitInternalViewController()
        initInternalVC.tabBarItem = UITabBarItem(title: "Init", image: UIImage(systemName: "power"), tag: 0)
        
        let bannerVC = BannerViewController()
        bannerVC.tabBarItem = UITabBarItem(title: "Banner", image: UIImage(systemName: "rectangle"), tag: 1)
        
        let interstitialVC = InterstitialViewController()
        interstitialVC.tabBarItem = UITabBarItem(title: "Interstitial", image: UIImage(systemName: "square"), tag: 2)
        
        let rewardedVC = RewardedViewController()
        rewardedVC.tabBarItem = UITabBarItem(title: "Rewarded", image: UIImage(systemName: "star"), tag: 3)
        
        let mrecVC = MRECViewController()
        mrecVC.tabBarItem = UITabBarItem(title: "MREC", image: UIImage(systemName: "rectangle.3.group"), tag: 4)
        
        let keyValueVC = KeyValueDemoViewController()
        keyValueVC.tabBarItem = UITabBarItem(title: "Key-Values", image: UIImage(systemName: "key.fill"), tag: 5)
        
        let settingsVC = SettingsViewController()
        settingsVC.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape"), tag: 6)
        
        // Set view controllers - Additional VCs appear in "More" section
        self.viewControllers = [
            UINavigationController(rootViewController: initInternalVC),
            UINavigationController(rootViewController: bannerVC),
            UINavigationController(rootViewController: interstitialVC),
            UINavigationController(rootViewController: rewardedVC),
            UINavigationController(rootViewController: mrecVC),
            UINavigationController(rootViewController: keyValueVC),
            UINavigationController(rootViewController: settingsVC)
        ]
    }
}