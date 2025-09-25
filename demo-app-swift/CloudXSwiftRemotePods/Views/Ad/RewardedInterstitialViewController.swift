import UIKit
import CloudXCore

class RewardedInterstitialViewController: BaseAdViewController, CLXRewardedDelegate {
    
    private var rewardedInterstitialAd: CLXRewardedInterstitial?
    
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
        print("[RewardedInterstitialViewController] viewWillAppear")
        if CloudXCore.shared.isInitialised {
            loadRewardedInterstitial()
        } else {
            print("[RewardedInterstitialViewController] SDK not initialized, rewarded interstitial will be loaded once SDK is initialized.")
        }
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
        print("[RewardedInterstitialViewController] loadRewardedInterstitial called")
        if !CloudXCore.shared.isInitialised {
            print("[RewardedInterstitialViewController] SDK not initialized")
            return
        }

        if isLoading || rewardedInterstitialAd != nil {
            print("[RewardedInterstitialViewController] Rewarded interstitial ad process already started")
            return
        }

        print("[RewardedInterstitialViewController] Starting rewarded interstitial ad load process...")
        isLoading = true
        updateStatusUI(state: .loading)

        let placement = placementName
        print("[RewardedInterstitialViewController] Using placement: \(placement)")
        
        // Create rewarded interstitial with comprehensive logging
        print("[RewardedInterstitialViewController] Calling createRewardedWithPlacement: \(placement)")
        rewardedInterstitialAd = CloudXCore.shared.createRewarded(withPlacement: placement, delegate: self)
        
        if let rewardedInterstitialAd = rewardedInterstitialAd {
            print("[RewardedInterstitialViewController] ✅ Rewarded interstitial ad instance created successfully: \(rewardedInterstitialAd)")
            print("[RewardedInterstitialViewController] Loading rewarded interstitial ad instance...")
            rewardedInterstitialAd.load()
        } else {
            print("[RewardedInterstitialViewController] ❌ Failed to create rewarded interstitial with placement: \(placement)")
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
        print("[RewardedInterstitialViewController] 'Show Rewarded Interstitial' button tapped.")
        
        if let rewardedInterstitialAd = rewardedInterstitialAd, rewardedInterstitialAd.isReady {
            print("✅ Ad is ready. Calling showFromViewController...")
            rewardedInterstitialAd.show(from: self)
        } else {
            print("⏳ Ad not ready. Will attempt to load.")
            if !isLoading && rewardedInterstitialAd != nil {
                print("🔄 Starting new load since not currently loading")
                rewardedInterstitialAd?.load()
            } else if isLoading {
                print("⏳ Already loading, just waiting for completion")
            } else {
                print("❌ No rewarded interstitial instance available, creating new one")
                loadRewardedInterstitial()
            }
            updateStatusUI(state: .loading)
        }
    }
    
    // MARK: - CLXRewardedDelegate
    
    func didLoad(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logMessage("✅ RewardedInterstitial didLoadWithAd - Ad: \(ad)")
        isLoading = false
        updateStatusUI(state: .ready)
    }
    
    func failToLoad(with ad: CLXAd, error: Error) {
        DemoAppLogger.sharedInstance.logMessage("❌ RewardedInterstitial failToLoadWithAd - Error: \(error.localizedDescription)")
        isLoading = false
        updateStatusUI(state: .noAd)
        
        DispatchQueue.main.async { [weak self] in
            let errorMessage = error.localizedDescription
            self?.showAlert(title: "Rewarded Interstitial Error", message: errorMessage)
            self?.rewardedInterstitialAd = nil
            // Don't automatically retry - let user manually retry if needed
            // This prevents the race condition where error shows but ad loads anyway
        }
    }
    
    func didShow(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logMessage("👀 RewardedInterstitial didShowWithAd - Ad: \(ad)")
    }
    
    func failToShow(with ad: CLXAd, error: Error) {
        DemoAppLogger.sharedInstance.logMessage("❌ RewardedInterstitial failToShowWithAd - Error: \(error.localizedDescription)")
        updateStatusUI(state: .noAd)
        
        DispatchQueue.main.async { [weak self] in
            self?.rewardedInterstitialAd = nil
            let errorMessage = error.localizedDescription
            self?.showAlert(title: "Rewarded Interstitial Error", message: errorMessage)
            // Don't automatically retry - let user manually retry if needed
        }
    }
    
    func didHide(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logMessage("🔚 RewardedInterstitial didHideWithAd - Ad: \(ad)")
        rewardedInterstitialAd = nil
        loadRewardedInterstitial()
        updateStatusUI(state: .noAd)
    }
    
    func didClick(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logMessage("👆 RewardedInterstitial didClickWithAd - Ad: \(ad)")
    }
    
    func impression(on ad: CLXAd) {
        DemoAppLogger.sharedInstance.logMessage("👁️ RewardedInterstitial impressionOn - Ad: \(ad)")
    }
    
    func revenuePaid(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logMessage("💰 RewardedInterstitial revenuePaid - Ad: \(ad)")
    }
    
    func closedByUserAction(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logMessage("✋ RewardedInterstitial closedByUserActionWithAd - Ad: \(ad)")
        rewardedInterstitialAd = nil
        loadRewardedInterstitial()
        updateStatusUI(state: .noAd)
    }
    
    func userRewarded(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logMessage("🎁 RewardedInterstitial userRewarded - Ad: \(ad)")
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(title: "Reward", message: "User has earned a reward from interstitial!")
        }
    }
    
    func rewardedVideoStarted(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logMessage("▶️ RewardedInterstitial rewardedVideoStarted - Ad: \(ad)")
    }
    
    func rewardedVideoCompleted(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logMessage("✅ RewardedInterstitial rewardedVideoCompleted - Ad: \(ad)")
    }
}