import UIKit
import CloudXCore

class RewardedViewController: BaseAdViewController, CLXRewardedDelegate {
    
    private var rewardedAd: CLXRewardedInterstitial?
    private let settings = UserDefaultsSettings.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Rewarded"
        
        // Create a vertical stack for buttons
        let buttonStack = UIStackView()
        buttonStack.axis = .vertical
        buttonStack.spacing = 16
        buttonStack.alignment = .center
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)
        
        // Load Rewarded button
        let loadButton = UIButton(type: .system)
        loadButton.setTitle("Load Rewarded", for: .normal)
        loadButton.addTarget(self, action: #selector(loadRewardedAd), for: .touchUpInside)
        loadButton.backgroundColor = .systemGreen
        loadButton.setTitleColor(.white, for: .normal)
        loadButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        loadButton.layer.cornerRadius = 8
        loadButton.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.addArrangedSubview(loadButton)
        
        // Show Rewarded button
        let showButton = UIButton(type: .system)
        showButton.setTitle("Show Rewarded", for: .normal)
        showButton.addTarget(self, action: #selector(showRewardedAd), for: .touchUpInside)
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
            loadButton.widthAnchor.constraint(equalToConstant: 200),
            loadButton.heightAnchor.constraint(equalToConstant: 44),
            showButton.widthAnchor.constraint(equalToConstant: 200),
            showButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // No auto-loading - user must press Load Rewarded button
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetAdState()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private var placementName: String {
        return CLXDemoConfigManager.sharedManager.currentConfig.rewardedPlacement
    }
    
    @objc private func loadRewardedAd() {
        if !CloudXCore.shared.isInitialised {
            showAlert(title: "Error", message: "SDK not initialized. Please initialize SDK first.")
            return
        }
        
        if isLoading {
            showAlert(title: "Info", message: "Rewarded ad is already loading.")
            return
        }
        
        if rewardedAd != nil {
            showAlert(title: "Info", message: "Rewarded ad already loaded. Use Show Rewarded to display it.")
            return
        }
        
        loadRewarded()
    }
    
    private func loadRewarded() {
        print("[RewardedViewController] loadRewarded called")
        if !CloudXCore.shared.isInitialised {
            print("[RewardedViewController] SDK not initialized")
            return
        }

        if isLoading || rewardedAd != nil {
            print("[RewardedViewController] Rewarded ad process already started")
            return
        }

        print("[RewardedViewController] Starting rewarded ad load process...")
        isLoading = true
        updateStatusUI(state: .loading)

        var placement = placementName
        if !settings.rewardedPlacement.isEmpty {
            placement = settings.rewardedPlacement
        }
        print("[RewardedViewController] Using placement: \(placement)")
        
        // Log SDK configuration details
        print("[RewardedViewController] SDK initialization status: \(CloudXCore.shared.isInitialised)")
        
        // Create rewarded with comprehensive logging
        print("[RewardedViewController] Calling createRewardedWithPlacement: \(placement)")
        rewardedAd = CloudXCore.shared.createRewarded(withPlacement: placement, delegate: self)
        
        if let rewardedAd = rewardedAd {
            print("[RewardedViewController] ✅ Rewarded ad instance created successfully: \(rewardedAd)")
            print("[RewardedViewController] Loading rewarded ad instance...")
            rewardedAd.load()
        } else {
            print("[RewardedViewController] ❌ Failed to create rewarded with placement: \(placement)")
            isLoading = false
            updateStatusUI(state: .noAd)
            showAlert(title: "Error", message: "Failed to create rewarded ad.")
        }
    }
    
    private func resetAdState() {
        rewardedAd = nil
        isLoading = false
    }
    
    private func createRewardedAd() {
        guard rewardedAd == nil else { return }
        let placement = placementName
        print("[RewardedViewController] Creating new Rewarded ad instance with placement: \(placement)")
        rewardedAd = CloudXCore.shared.createRewarded(withPlacement: placement, delegate: self)
        if let rewardedAd = rewardedAd {
            print("✅ Rewarded ad instance created successfully: \(rewardedAd)")
            startPollingReadyState()
        } else {
            print("❌ Failed to create rewarded ad instance for placement: \(placement)")
        }
    }
    
    private func startPollingReadyState() {
        // Poll every 0.5 seconds to check if the ad is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            guard let rewardedAd = self.rewardedAd else {
                print("❌ No rewarded ad instance available for polling")
                return
            }
            
            print("🔍 Checking ad ready state...")
            if rewardedAd.isReady {
                print("✅ Ad is now ready from queue")
                self.isLoading = false
                self.updateStatusUI(state: .ready)
                // Do NOT show the ad here!
                return
            } else {
                print("⏳ Ad not ready yet, continuing to poll...")
                self.isLoading = true
                self.updateStatusUI(state: .loading)
                self.startPollingReadyState()
            }
        }
    }
    
    @objc private func showRewardedAd() {
        print("🔄 [RewardedViewController] showRewardedAd called")
        print("📊 [RewardedViewController] Current state:")
        print("📊 [RewardedViewController] - isLoading: \(isLoading)")
        print("📊 [RewardedViewController] - rewardedAd: \(String(describing: rewardedAd))")
        print("📊 [RewardedViewController] - rewardedAd.isReady: \(rewardedAd?.isReady ?? false)")
        
        if isLoading {
            print("⏳ [RewardedViewController] Already loading an ad, please wait...")
            return
        }
        
        // If ad is ready, show it immediately
        if let rewardedAd = rewardedAd, rewardedAd.isReady {
            print("👀 [RewardedViewController] Ad ready, showing immediately...")
            print("📊 [RewardedViewController] Calling showFromViewController on: \(rewardedAd)")
            rewardedAd.show(from: self)
            return
        }
        
        // If no ad instance or not ready, create a new one
        if rewardedAd == nil {
            print("📱 [RewardedViewController] No ad instance found, creating new one...")
            createRewardedAd()
        }
        
        guard let rewardedAd = rewardedAd else {
            print("❌ [RewardedViewController] Failed to create Rewarded ad instance")
            showAlert(title: "Error", message: "Failed to create Rewarded ad.")
            return
        }
        
        // If we have an ad but it's not ready, start loading
        if !rewardedAd.isReady {
            print("📱 [RewardedViewController] Ad not ready, starting load...")
            isLoading = true
            rewardedAd.load()
        }
    }
    
    // MARK: - CLXRewardedDelegate
    
    func didLoad(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("✅ Rewarded didLoadWithAd", ad: ad)
        isLoading = false
        updateStatusUI(state: .ready)
        // Do NOT show the ad here!
    }
    
    func failToLoad(with ad: CLXAd, error: Error) {
        DemoAppLogger.sharedInstance.logMessage("❌ Rewarded failToLoadWithAd - Error: \(error.localizedDescription)")
        isLoading = false
        updateStatusUI(state: .noAd)
        
        DispatchQueue.main.async { [weak self] in
            let errorMessage = error.localizedDescription
            self?.showAlert(title: "Rewarded Ad Error", message: errorMessage)
            self?.rewardedAd = nil
        }
    }
    
    func didShow(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logMessage("👀 Rewarded didShowWithAd - Ad: \(ad)")
    }
    
    func failToShow(with ad: CLXAd, error: Error) {
        DemoAppLogger.sharedInstance.logMessage("❌ Rewarded failToShowWithAd - Error: \(error.localizedDescription)")
        updateStatusUI(state: .noAd)
        
        DispatchQueue.main.async { [weak self] in
            self?.rewardedAd = nil
            let errorMessage = error.localizedDescription
            self?.showAlert(title: "Rewarded Ad Error", message: errorMessage)
        }
    }
    
    func didHide(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logMessage("🔚 Rewarded didHideWithAd - Ad: \(ad)")
        rewardedAd = nil
        // Create new ad instance for next time
        createRewardedAd()
        updateStatusUI(state: .noAd)
    }
    
    func didClick(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logMessage("👆 Rewarded didClickWithAd - Ad: \(ad)")
    }
    
    func impression(on ad: CLXAd) {
        DemoAppLogger.sharedInstance.logMessage("👁️ Rewarded impressionOn - Ad: \(ad)")
    }
    
    func revenuePaid(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("💰 Rewarded revenuePaid", ad: ad)
    }
    
    func closedByUserAction(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logMessage("✋ Rewarded closedByUserActionWithAd - Ad: \(ad)")
        rewardedAd = nil
        // Create new ad instance for next time
        createRewardedAd()
        updateStatusUI(state: .noAd)
    }
    
    func userRewarded(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logMessage("🎁 Rewarded userRewarded - Ad: \(ad)")
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(title: "Reward", message: "User has earned a reward!")
        }
    }
    
    func rewardedVideoStarted(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logMessage("▶️ Rewarded rewardedVideoStarted - Ad: \(ad)")
    }
    
    func rewardedVideoCompleted(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logMessage("✅ Rewarded rewardedVideoCompleted - Ad: \(ad)")
    }
}