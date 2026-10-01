import UIKit
import AppTrackingTransparency

class AdDemoTabViewController: UITabBarController {

    /// Selects the tab at the given index, handling the "More" tab if needed.
    func selectTab(at index: Int) {
        if index < (viewControllers?.count ?? 0) {
            selectedIndex = index
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Request App Tracking Transparency permission
        requestAppTrackingTransparencyPermission()

        // Create view controllers
        let initInternalVC = InitInternalViewController()
        initInternalVC.tabBarItem = UITabBarItem(title: "Init", image: UIImage(systemName: "power"), tag: 0)
        
        let bannerVC = BannerViewController()
        bannerVC.tabBarItem = UITabBarItem(title: "Banner", image: UIImage(systemName: "rectangle"), tag: 1)
        
        let interstitialVC = InterstitialViewController()
        interstitialVC.tabBarItem = UITabBarItem(title: "Interstitial", image: UIImage(systemName: "square"), tag: 2)
        
        let rewardedVC = RewardedViewController()
        rewardedVC.tabBarItem = UITabBarItem(title: "Rewarded", image: UIImage(systemName: "star"), tag: 3)

        let appOpenVC = AppOpenViewController()
        appOpenVC.tabBarItem = UITabBarItem(title: "App Open", image: UIImage(systemName: "app"), tag: 8)
        
        let mrecVC = MRECViewController()
        mrecVC.tabBarItem = UITabBarItem(title: "MREC", image: UIImage(systemName: "rectangle.3.group"), tag: 4)

        let nativeVC = NativeMenuViewController()
        nativeVC.tabBarItem = UITabBarItem(title: "Native", image: UIImage(systemName: "doc.richtext"), tag: 5)

        let keyValueVC = KeyValueDemoViewController()
        keyValueVC.tabBarItem = UITabBarItem(title: "Key-Values", image: UIImage(systemName: "key.fill"), tag: 6)
        
        let settingsVC = SettingsViewController()
        settingsVC.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape"), tag: 7)
        
        // Set view controllers - Additional VCs appear in "More" section
        self.viewControllers = [
            UINavigationController(rootViewController: initInternalVC),
            UINavigationController(rootViewController: bannerVC),
            UINavigationController(rootViewController: interstitialVC),
            UINavigationController(rootViewController: rewardedVC),
            UINavigationController(rootViewController: appOpenVC),
            UINavigationController(rootViewController: mrecVC),
            UINavigationController(rootViewController: nativeVC),
            UINavigationController(rootViewController: keyValueVC),
            UINavigationController(rootViewController: settingsVC)
        ]
    }

    private func requestAppTrackingTransparencyPermission() {
        // iOS 14+ ATT compliance
        if #available(iOS 14, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    switch status {
                    case .authorized:
                        DemoAppLogger.sharedInstance.logMessage("App Tracking authorized")
                    case .denied:
                        DemoAppLogger.sharedInstance.logMessage("App Tracking denied")
                    case .notDetermined:
                        DemoAppLogger.sharedInstance.logMessage("App Tracking not determined")
                    case .restricted:
                        DemoAppLogger.sharedInstance.logMessage("App Tracking restricted")
                    @unknown default:
                        break
                    }
                }
            }
        }
    }
}
