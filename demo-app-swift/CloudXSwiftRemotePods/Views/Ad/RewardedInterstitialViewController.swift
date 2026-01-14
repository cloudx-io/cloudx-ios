import UIKit
import CloudXCore

class RewardedInterstitialViewController: BaseAdViewController, CLXRewardedDelegate, CLXAdRevenueDelegate {
    
    private var rewardedInterstitialAd: CLXRewarded?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Rewarded Interstitial"
        
        // Create a vertical stack for buttons
        let buttonStack = UIStackView()
        buttonStack.axis = .vertical
        buttonStack.spacing = 16
        buttonStack.alignment = .center
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)
        
        // Load Rewarded Interstitial button
        let loadButton = UIButton(type: .system)
        loadButton.setTitle("Load Rewarded Interstitial", for: .normal)
        loadButton.addTarget(self, action: #selector(loadRewardedInterstitialAd), for: .touchUpInside)
        loadButton.backgroundColor = .systemGreen
        loadButton.setTitleColor(.white, for: .normal)
        loadButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        loadButton.layer.cornerRadius = 8
        loadButton.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.addArrangedSubview(loadButton)
        
        // Show Rewarded Interstitial button
        let showButton = UIButton(type: .system)
        showButton.setTitle("Show Rewarded Interstitial", for: .normal)
        showButton.addTarget(self, action: #selector(showRewardedInterstitialAd), for: .touchUpInside)
        showButton.backgroundColor = .systemBlue
        showButton.setTitleColor(.white, for: .normal)
        showButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        showButton.layer.cornerRadius = 8
        showButton.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.addArrangedSubview(showButton)
        
        // Button constraints
        NSLayoutConstraint.activate([
            buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            loadButton.widthAnchor.constraint(equalToConstant: 250),
            loadButton.heightAnchor.constraint(equalToConstant: 44),
            showButton.widthAnchor.constraint(equalToConstant: 250),
            showButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DemoAppLogger.sharedInstance.logMessage("🔄 [RewardedInterstitial] viewWillAppear")
        loadRewardedInterstitial()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetAdState()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private var placementName: String {
        return CLXDemoConfigManager.sharedManager.currentConfig.rewardedInterstitialPlacement
    }
    
    private func loadRewardedInterstitial() {
        DemoAppLogger.sharedInstance.logMessage("🔄 [RewardedInterstitial] loadRewardedInterstitial called")

        if isLoading || rewardedInterstitialAd != nil {
            DemoAppLogger.sharedInstance.logMessage("⏳ [RewardedInterstitial] Rewarded interstitial ad process already started")
            return
        }

        DemoAppLogger.sharedInstance.logMessage("📱 [RewardedInterstitial] Starting rewarded interstitial ad load process...")
        isLoading = true
        updateStatusUI(state: .loading)

        let placement = placementName
        DemoAppLogger.sharedInstance.logMessage("📍 [RewardedInterstitial] Using placement: \(placement)")
        
        // Create rewarded interstitial with comprehensive logging
        DemoAppLogger.sharedInstance.logMessage("📱 [RewardedInterstitial] Calling createRewarded...")
        rewardedInterstitialAd = CloudXCore.shared.createRewarded(placement: placement)
        rewardedInterstitialAd?.delegate = self
        rewardedInterstitialAd?.revenueDelegate = self
        
        if let rewardedInterstitialAd = rewardedInterstitialAd {
            DemoAppLogger.sharedInstance.logMessage("✅ [RewardedInterstitial] Rewarded interstitial ad instance created successfully")
            DemoAppLogger.sharedInstance.logMessage("🔄 [RewardedInterstitial] Loading rewarded interstitial ad instance...")
            rewardedInterstitialAd.load()
        } else {
            DemoAppLogger.sharedInstance.logMessage("❌ [RewardedInterstitial] Failed to create rewarded interstitial with placement: \(placement)")
            isLoading = false
            updateStatusUI(state: .noAd)
            showAlert(title: "Error", message: "Failed to create rewarded interstitial ad.")
        }
    }
    
    private func resetAdState() {
        rewardedInterstitialAd = nil
        isLoading = false
    }
    
    @objc private func loadRewardedInterstitialAd() {
        loadRewardedInterstitial()
    }
    
    @objc private func showRewardedInterstitialAd() {
        DemoAppLogger.sharedInstance.logMessage("🔄 [RewardedInterstitial] 'Show Rewarded Interstitial' button tapped.")
        
        if let rewardedInterstitialAd = rewardedInterstitialAd, rewardedInterstitialAd.isReady {
            DemoAppLogger.sharedInstance.logMessage("✅ [RewardedInterstitial] Ad is ready. Calling showFromViewController...")
            rewardedInterstitialAd.show(from: self)
        } else {
            DemoAppLogger.sharedInstance.logMessage("⏳ [RewardedInterstitial] Ad not ready. Will attempt to load.")
            if !isLoading && rewardedInterstitialAd != nil {
                DemoAppLogger.sharedInstance.logMessage("🔄 [RewardedInterstitial] Starting new load since not currently loading")
                rewardedInterstitialAd?.load()
            } else if isLoading {
                DemoAppLogger.sharedInstance.logMessage("⏳ [RewardedInterstitial] Already loading, just waiting for completion")
            } else {
                DemoAppLogger.sharedInstance.logMessage("❌ [RewardedInterstitial] No rewarded interstitial instance available, creating new one")
                loadRewardedInterstitial()
            }
            updateStatusUI(state: .loading)
        }
    }
    
    // MARK: - CLXRewardedDelegate
    
    func didLoad(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("✅ RewardedInterstitial didLoadAd", ad: ad)
        isLoading = false
        updateStatusUI(state: .ready)
    }
    
    func didFailToLoadAd(_ placementName: String, error: CLXError) {
        // No ad object exists on failure, so use logMessage instead of logAdEvent
        DemoAppLogger.sharedInstance.logMessage("❌ RewardedInterstitial failed to load for placement '\(placementName)' - Error: \(error.localizedDescription)")
        isLoading = false
        updateStatusUI(state: .noAd)
        
        DispatchQueue.main.async { [weak self] in
            let errorMessage = (error as NSError).detailedDemoDescription
            self?.showAlert(title: "Rewarded Interstitial Load Failed", message: errorMessage)
            self?.rewardedInterstitialAd = nil
        }
    }
    
    func didDisplay(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👀 RewardedInterstitial didDisplayAd", ad: ad)
    }
    
    func didFailToDisplay(_ ad: CLXAd, error: CLXError) {
        DemoAppLogger.sharedInstance.logAdEvent("❌ RewardedInterstitial didFailToDisplayAd", ad: ad)
        updateStatusUI(state: .noAd)
        
        DispatchQueue.main.async { [weak self] in
            self?.rewardedInterstitialAd = nil
            let errorMessage = (error as NSError).detailedDemoDescription
            self?.showAlert(title: "Rewarded Interstitial Show Failed", message: errorMessage)
        }
    }
    
    func didHide(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("🔚 RewardedInterstitial didHideAd", ad: ad)
        rewardedInterstitialAd = nil
        loadRewardedInterstitial()
        updateStatusUI(state: .noAd)
    }
    
    func didClick(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👆 RewardedInterstitial didClickAd", ad: ad)
    }

    func didPayRevenue(for ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("💰 RewardedInterstitial didPayRevenue", ad: ad)
    }
    
    func didRewardUser(for ad: CLXAd, with reward: CLXReward) {
        DemoAppLogger.sharedInstance.logAdEvent("🎁 RewardedInterstitial userRewarded - Reward: \(reward.amount) \(reward.label)", ad: ad)
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(title: "Reward Earned! 🎉", message: "User earned \(reward.amount) \(reward.label) from interstitial!")
        }
    }
}
