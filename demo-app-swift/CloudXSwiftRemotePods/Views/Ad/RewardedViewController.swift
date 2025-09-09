import UIKit
import CloudXCore

class RewardedViewController: BaseAdViewController {
    private var rewardedAd: CLXRewardedInterstitial?
    private var isSDKInitialized = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCenteredButton(title: "Show Rewarded", action: #selector(showRewardedAd))
        setupNotifications()
        
        // Check if SDK is already initialized
        isSDKInitialized = cloudX.isInitialised
        updateStatusUI(state: AdState.noAd)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create ad if SDK is already initialized
        if isSDKInitialized && rewardedAd == nil {
            createRewardedAd()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetAdState()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private enum AdState {
        case noAd
        case loading
        case ready
        
        var text: String {
            switch self {
            case .noAd: return "No Ad Loaded"
            case .loading: return "Loading Ad..."
            case .ready: return "Ad Ready"
            }
        }
        
        var color: UIColor {
            switch self {
            case .noAd: return .systemRed
            case .loading: return .systemYellow
            case .ready: return .systemGreen
            }
        }
    }
    
    private func updateStatusUI(state: AdState) {
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.text = state.text
            self?.statusLabel.textColor = state.color
            self?.statusIndicator.backgroundColor = state.color
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSDKInitialized),
            name: .sdkInitialized,
            object: nil
        )
    }
    
    @objc private func handleSDKInitialized() {
        isSDKInitialized = true
        createRewardedAd()
    }
    
    private func createRewardedAd() {
        guard rewardedAd == nil else { return }
        print("📱 Creating new Rewarded ad instance...")
        
        // Ensure SDK is initialized
        guard cloudX.isInitialised else {
            print("❌ SDK not initialized yet")
            showAlert(title: "Error", message: "SDK not initialized yet. Please wait.")
            return
        }
        
        // Ensure UI operations happen on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Create rewarded ad with verified placement
            self.rewardedAd = self.cloudX.createRewarded(withPlacement: "rewarded1", delegate: self)
            
            if self.rewardedAd == nil {
                print("❌ Failed to create Rewarded ad instance")
                self.showAlert(title: "Error", message: "Failed to create Rewarded ad instance")
            } else {
                print("✅ Rewarded ad instance created successfully")
                // Start polling the ready state
                self.startPollingReadyState()
            }
        }
    }
    
    private func startPollingReadyState() {
        // Poll every 0.5 seconds to check if the ad is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self,
                  let ad = self.rewardedAd else { return }
            
            if ad.isReady() {
                print("✅ Ad is now ready from queue")
                self.updateStatusUI(state: AdState.ready)
            } else {
                print("⏳ Ad not ready yet, continuing to poll...")
                self.updateStatusUI(state: AdState.loading)
                self.startPollingReadyState()
            }
        }
    }
    
    @objc private func showRewardedAd() {
        print("🔄 Starting Rewarded ad load process...")
        
        guard isSDKInitialized else {
            showAlert(title: "Error", message: "SDK not initialized. Please initialize SDK first.")
            return
        }
        
        guard !isLoading else {
            print("⏳ Already loading an ad, please wait...")
            return
        }
        
        // Create a new Rewarded ad instance if needed
        if rewardedAd == nil {
            createRewardedAd()
        }
        
        guard let rewarded = rewardedAd else {
            showAlert(title: "Error", message: "Failed to create Rewarded ad.")
            return
        }
        
        // If ad is ready, show it immediately
        if rewarded.isReady() {
            print("👀 Ad ready, showing immediately...")
            rewarded.show(from: self)
            return
        }
        
        isLoading = true
        updateStatusUI(state: AdState.loading)
        print("📱 Loading Rewarded ad...")
        rewarded.load()
    }
    
    private func resetAdState() {
        rewardedAd = nil
        isLoading = false
        updateStatusUI(state: AdState.noAd)
    }
}

extension RewardedViewController: CLXRewardedDelegate {
    func didLoad(with ad: CLXAd) {
        print("✅ Rewarded ad loaded successfully")
        isLoading = false
        updateStatusUI(state: AdState.ready)
        
        guard let rewarded = ad as? CLXRewardedInterstitial else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            print("👀 Showing Rewarded ad...")
            rewarded.show(from: self)
        }
    }
    
    func failToLoad(with ad: CLXAd, error: Error) {
        print("❌ Failed to load Rewarded Ad: \(error)")
        isLoading = false
        updateStatusUI(state: AdState.noAd)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Check if the error is about no ads being available
            let errorMessage = error.localizedDescription
            if errorMessage.contains("queue") {
                self.showAlert(title: "No Ads Available", 
                             message: "Please wait a moment and try again. New ads are being loaded.")
            } else {
                self.showAlert(title: "Ad Load Error", message: errorMessage)
            }
            
            self.rewardedAd = nil
            // Create new ad instance for next time
            self.createRewardedAd()
        }
    }
    
    func didShow(with ad: CLXAd) {
        print("👀 Rewarded ad did show")
    }
    
    func failToShow(with ad: CLXAd, error: Error) {
        print("❌ Rewarded ad fail to show: \(error)")
        updateStatusUI(state: AdState.noAd)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.rewardedAd = nil
            self.showAlert(title: "Ad Show Error", message: error.localizedDescription)
            // Create new ad instance for next time
            self.createRewardedAd()
        }
    }
    
    func didHide(with ad: CLXAd) {
        print("🔚 Rewarded ad did hide")
        rewardedAd = nil
        // Create new ad instance for next time
        createRewardedAd()
        updateStatusUI(state: AdState.noAd)
    }
    
    func didClick(with ad: CLXAd) {
        print("👆 Rewarded ad did click")
    }
    
    func impression(on ad: CLXAd) {
        print("👁️ Rewarded ad impression recorded")
    }
    
    func closedByUserAction(with ad: CLXAd) {
        print("✋ Rewarded ad closed by user action")
        rewardedAd = nil
        // Create new ad instance for next time
        createRewardedAd()
        updateStatusUI(state: AdState.noAd)
    }
    
    // Rewarded-specific callbacks
    func userRewarded(_ ad: CLXAd) {
        print("🎁 User earned reward!")
        // Handle reward here
        showRewardDialog()
    }
    
    func rewardedVideoStarted(_ ad: CLXAd) {
        print("▶️ Rewarded video started")
    }
    
    func rewardedVideoCompleted(_ ad: CLXAd) {
        print("✅ Rewarded video completed")
    }
    
    private func showRewardDialog() {
        let alert = UIAlertController(title: "Reward Earned!",
                                    message: "You earned a reward!",
                                    preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
} 
