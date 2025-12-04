import UIKit
import CloudXCore

class RewardedViewController: BaseAdViewController, CLXRewardedDelegate {
    
    private var rewardedAd: CLXRewarded?
    private let settings = UserDefaultsSettings.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Rewarded"
        setupUI()
    }
    
    private func setupUI() {
        // Create a vertical stack for buttons
        let buttonStack = UIStackView()
        buttonStack.axis = .vertical
        buttonStack.spacing = 12
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
        DemoAppLogger.sharedInstance.logMessage("🔄 [Rewarded] loadRewarded called")

        if isLoading || rewardedAd != nil {
            DemoAppLogger.sharedInstance.logMessage("⏳ [Rewarded] Rewarded ad process already started")
            return
        }

        DemoAppLogger.sharedInstance.logMessage("📱 [Rewarded] Starting rewarded ad load process...")
        isLoading = true
        updateStatusUI(state: .loading)

        var placement = placementName
        if !settings.rewardedPlacement.isEmpty {
            placement = settings.rewardedPlacement
        }
        DemoAppLogger.sharedInstance.logMessage("📍 [Rewarded] Using placement: \(placement)")
        
        // Create rewarded with comprehensive logging
        DemoAppLogger.sharedInstance.logMessage("📱 [Rewarded] Calling createRewarded...")
        rewardedAd = CloudXCore.shared.createRewarded(placement: placement)
        rewardedAd?.delegate = self
        
        if let rewardedAd = rewardedAd {
            DemoAppLogger.sharedInstance.logMessage("✅ [Rewarded] Rewarded ad instance created successfully")
            DemoAppLogger.sharedInstance.logMessage("🔄 [Rewarded] Loading rewarded ad instance...")
            rewardedAd.load()
        } else {
            DemoAppLogger.sharedInstance.logMessage("❌ [Rewarded] Failed to create rewarded with placement: \(placement)")
            isLoading = false
            updateStatusUI(state: .noAd)
            showAlert(title: "Error", message: "Failed to create rewarded ad.")
        }
    }
    
    private func resetAdState() {
        rewardedAd = nil
        isLoading = false
    }
    
    @objc private func showRewardedAd() {
        DemoAppLogger.sharedInstance.logMessage("🔄 [Rewarded] showRewardedAd called")
        DemoAppLogger.sharedInstance.logMessage("📊 [Rewarded] isLoading: \(isLoading)")
        DemoAppLogger.sharedInstance.logMessage("📊 [Rewarded] rewardedAd.isReady: \(rewardedAd?.isReady ?? false)")
        
        if isLoading {
            DemoAppLogger.sharedInstance.logMessage("⏳ [Rewarded] Already loading an ad, please wait...")
            showAlert(title: "Info", message: "Rewarded ad is still loading. Please wait.")
            return
        }
        
        // Check if ad is ready to show
        guard let rewardedAd = rewardedAd else {
            showAlert(title: "Error", message: "No rewarded ad loaded. Please load a rewarded ad first.")
            return
        }
        
        if rewardedAd.isReady {
            DemoAppLogger.sharedInstance.logMessage("👀 [Rewarded] Ad ready, showing...")
            rewardedAd.show(from: self)
        } else {
            showAlert(title: "Error", message: "Rewarded ad is not ready. Please try loading again.")
        }
    }
    
    // MARK: - CLXRewardedDelegate
    
    func didLoad(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("✅ Rewarded didLoadAd", ad: ad)
        isLoading = false
        updateStatusUI(state: .ready)
    }
    
    func didFailToLoadAd(error: CLXError) {
        DemoAppLogger.sharedInstance.logMessage("❌ Rewarded failed to load - Error: \(error.localizedDescription)")
        isLoading = false
        updateStatusUI(state: .noAd)
        
        DispatchQueue.main.async { [weak self] in
            let errorMessage = error.detailedDemoDescription
            self?.showAlert(title: "Rewarded Ad Load Failed", message: errorMessage)
            self?.rewardedAd = nil
        }
    }
    
    func didDisplay(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👀 Rewarded didDisplayAd", ad: ad)
    }
    
    func didFailToDisplay(_ ad: CLXAd, error: CLXError) {
        DemoAppLogger.sharedInstance.logAdEvent("❌ Rewarded didFailToDisplayAd", ad: ad)
        updateStatusUI(state: .noAd)
        
        DispatchQueue.main.async { [weak self] in
            self?.rewardedAd = nil
            let errorMessage = error.detailedDemoDescription
            self?.showAlert(title: "Rewarded Ad Show Failed", message: errorMessage)
        }
    }
    
    func didHide(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("🔚 Rewarded didHideAd", ad: ad)
        rewardedAd = nil
        updateStatusUI(state: .noAd)
    }
    
    func didClick(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👆 Rewarded didClickAd", ad: ad)
    }
    
    func didRecordImpression(for ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👁️ Rewarded didRecordImpression", ad: ad)
    }
    
    func didPayRevenue(for ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("💰 Rewarded didPayRevenue", ad: ad)
    }
    
    func userRewarded(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("🎁 Rewarded userRewarded", ad: ad)
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(title: "Reward Earned! 🎉", message: "User has successfully earned a reward!")
        }
    }
}
