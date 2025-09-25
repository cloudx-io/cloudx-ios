import UIKit
import CloudXCore

class InterstitialViewController: BaseAdViewController {
    private var interstitialAd: CLXInterstitial?
    private var isSDKInitialized = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCenteredButton(title: "Show Interstitial", action: #selector(showInterstitialAd))
        setupNotifications()
        
        // Check if SDK is already initialized
        isSDKInitialized = cloudX.isInitialised
        updateStatusUI(state: AdState.noAd)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create ad if SDK is already initialized
        if isSDKInitialized && interstitialAd == nil {
            createInterstitialAd()
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
        createInterstitialAd()
    }
    
    private func createInterstitialAd() {
        guard interstitialAd == nil else { return }
        print("📱 Creating new Interstitial ad instance...")
        
        // Ensure SDK is initialized
        guard cloudX.isInitialised else {
            print("❌ SDK not initialized yet")
            showAlert(title: "Error", message: "SDK not initialized yet. Please wait.")
            return
        }
        
        // Ensure UI operations happen on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Create interstitial ad with verified placement
            self.interstitialAd = self.cloudX.createInterstitial(withPlacement: "interstitial1", delegate: self)
            
            if self.interstitialAd == nil {
                print("❌ Failed to create Interstitial ad instance")
                self.showAlert(title: "Error", message: "Failed to create Interstitial ad instance")
            } else {
                print("✅ Interstitial ad instance created successfully")
                // Start polling the ready state
                self.startPollingReadyState()
            }
        }
    }
    
    private func startPollingReadyState() {
        // Poll every 0.5 seconds to check if the ad is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self,
                  let ad = self.interstitialAd else { return }
            
            if ad.isReady {
                print("✅ Ad is now ready from queue")
                self.updateStatusUI(state: AdState.ready)
            } else {
                print("⏳ Ad not ready yet, continuing to poll...")
                self.updateStatusUI(state: AdState.loading)
                self.startPollingReadyState()
            }
        }
    }
    
    @objc private func showInterstitialAd() {
        print("🔄 Starting Interstitial ad load process...")
        
        guard isSDKInitialized else {
            showAlert(title: "Error", message: "SDK not initialized. Please initialize SDK first.")
            return
        }
        
        guard !isLoading else {
            print("⏳ Already loading an ad, please wait...")
            return
        }
        
        // Create a new Interstitial ad instance if needed
        if interstitialAd == nil {
            createInterstitialAd()
        }
        
        guard let interstitial = interstitialAd else {
            showAlert(title: "Error", message: "Failed to create Interstitial ad.")
            return
        }
        
        // If ad is ready, show it immediately
        if interstitial.isReady {
            print("👀 Ad ready, showing immediately...")
            interstitial.show(from: self)
            return
        }
        
        isLoading = true
        updateStatusUI(state: AdState.loading)
        print("📱 Loading Interstitial ad...")
        interstitial.load()
    }
    
    private func resetAdState() {
        interstitialAd = nil
        isLoading = false
        updateStatusUI(state: AdState.noAd)
    }
}

extension InterstitialViewController: CLXInterstitialDelegate {
    func didLoad(with ad: CLXAd) {
        print("✅ Interstitial ad loaded successfully")
        isLoading = false
        updateStatusUI(state: AdState.ready)
        
        guard let interstitial = ad as? CLXInterstitial else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            print("👀 Showing Interstitial ad...")
            interstitial.show(from: self)
        }
    }
    
    func failToLoad(with ad: CLXAd, error: Error) {
        print("❌ Failed to load Interstitial Ad: \(error)")
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
            
            self.interstitialAd = nil
            // Create new ad instance for next time
            self.createInterstitialAd()
        }
    }
    
    func didShow(with ad: CLXAd) {
        print("👀 Interstitial ad did show")
    }
    
    func failToShow(with ad: CLXAd, error: Error) {
        print("❌ Interstitial ad fail to show: \(error)")
        updateStatusUI(state: AdState.noAd)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.interstitialAd = nil
            self.showAlert(title: "Ad Show Error", message: error.localizedDescription)
            // Create new ad instance for next time
            self.createInterstitialAd()
        }
    }
    
    func didHide(with ad: CLXAd) {
        print("🔚 Interstitial ad did hide")
        interstitialAd = nil
        // Create new ad instance for next time
        createInterstitialAd()
        updateStatusUI(state: AdState.noAd)
    }
    
    func didClick(with ad: CLXAd) {
        print("👆 Interstitial ad did click")
    }
    
    func impression(on ad: CLXAd) {
        print("👁️ Interstitial ad impression recorded")
    }
    
    func revenuePaid(_ ad: CLXAd) {
        print("💰 Interstitial ad revenue paid")
    }
    
    func closedByUserAction(with ad: CLXAd) {
        print("✋ Interstitial ad closed by user action")
        interstitialAd = nil
        // Create new ad instance for next time
        createInterstitialAd()
        updateStatusUI(state: AdState.noAd)
    }
} 
