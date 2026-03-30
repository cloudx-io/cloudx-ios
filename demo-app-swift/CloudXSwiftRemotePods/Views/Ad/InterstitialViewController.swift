import UIKit
import CloudXCore

class InterstitialViewController: BaseAdViewController {
    private var interstitialAd: CLXInterstitial?
    private var showAdWhenLoaded = false
    private let settings = UserDefaultsSettings.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotifications()
        updateStatusUI(state: AdState.noAd)
    }
    
    private func setupUI() {
        // Create a vertical stack for buttons
        let buttonStack = UIStackView()
        buttonStack.axis = .vertical
        buttonStack.spacing = 16
        buttonStack.alignment = .center
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)
        
        // Load Interstitial button
        let loadButton = UIButton(type: .system)
        loadButton.setTitle("Load Interstitial", for: .normal)
        loadButton.addTarget(self, action: #selector(loadInterstitialAd), for: .touchUpInside)
        loadButton.backgroundColor = .systemGreen
        loadButton.setTitleColor(.white, for: .normal)
        loadButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        loadButton.layer.cornerRadius = 8
        loadButton.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.addArrangedSubview(loadButton)
        
        // Show Interstitial button
        let showButton = UIButton(type: .system)
        showButton.setTitle("Show Interstitial", for: .normal)
        showButton.addTarget(self, action: #selector(showInterstitialAd), for: .touchUpInside)
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
        // No auto-loading - user must press Load Interstitial button
    }
    
    @objc private func loadInterstitialAd() {
        receivedCallbacks = []
        if isLoading {
            showAlert(title: "Info", message: "Interstitial is already loading.")
            return
        }
        
        if interstitialAd != nil {
            showAlert(title: "Info", message: "Interstitial already loaded. Use Show Interstitial to display it.")
            return
        }
        
        loadInterstitial()
    }
    
    private func loadInterstitial() {

        if isLoading || interstitialAd != nil {
            return
        }

        isLoading = true
        updateStatusUI(state: AdState.loading)

        // Get adUnitId from config manager (with settings override if provided)
        var adUnitId = CLXDemoConfigManager.sharedManager.currentConfig.interstitialAdUnitId
        if !settings.interstitialAdUnitId.isEmpty {
            adUnitId = settings.interstitialAdUnitId
        }
        
        interstitialAd = cloudX.createInterstitial(adUnitId: adUnitId)
        interstitialAd?.delegate = self
        interstitialAd?.revenueDelegate = self
        
        if let interstitialAd = interstitialAd {
            interstitialAd.load()
        } else {
            isLoading = false
            updateStatusUI(state: AdState.noAd)
            showAlert(title: "Error", message: "Failed to create interstitial.")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Only reset if we're actually leaving the tab — not when a fullscreen ad
        // is presented over us (which also triggers viewWillDisappear).
        if interstitialAd == nil || isLoading {
            resetAdState()
        }
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
        // Don't auto-create - wait for user to press Load Interstitial button
    }
    
    // Remove the old createInterstitialAd and polling methods - they're replaced by loadInterstitial
    
    @objc private func showInterstitialAd() {
        
        guard let interstitialAd = interstitialAd else {
            showAlert(title: "Error", message: "No interstitial loaded. Please load an interstitial first.")
            return
        }
        
        if isLoading {
            showAlert(title: "Info", message: "Interstitial is still loading. Please wait.")
            return
        }
        
        if interstitialAd.isReady {
            interstitialAd.show(from: self, placement: "demo_interstitial", customData: "level:5,coins:100")
        } else {
            showAlert(title: "Error", message: "Interstitial is not ready. Please try loading again.")
        }
    }
    
    private func resetAdState() {
        interstitialAd = nil
        isLoading = false
        showAdWhenLoaded = false
        receivedCallbacks = []
        updateStatusUI(state: AdState.noAd)
    }
}

extension InterstitialViewController: CLXInterstitialDelegate, CLXAdRevenueDelegate {
    func didLoad(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("✅ Interstitial didLoadAd", ad: ad)
        isLoading = false
        updateStatusUI(state: AdState.ready)
        // Don't auto-show - wait for user to press Show Interstitial button
    }
    
    func didFailToLoadAd(_ adUnitId: String, error: CLXError) {
        DemoAppLogger.sharedInstance.logMessage("❌ Interstitial failed to load (\(adUnitId)) - Error: \(error.localizedDescription)")
        isLoading = false
        updateStatusUI(state: AdState.noAd)
        
        DispatchQueue.main.async { [weak self] in
            let errorMessage = (error as NSError).detailedDemoDescription
            self?.showAlert(title: "Interstitial Ad Load Failed", message: errorMessage)
            self?.interstitialAd = nil
        }
    }
    
    func didDisplay(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👀 Interstitial didDisplayAd", ad: ad)
    }
    
    func didFailToDisplay(_ ad: CLXAd, error: CLXError) {
        DemoAppLogger.sharedInstance.logAdEvent("❌ Interstitial didFailToDisplayAd", ad: ad)
        updateStatusUI(state: AdState.noAd)
        
        DispatchQueue.main.async { [weak self] in
            self?.interstitialAd = nil
            let errorMessage = (error as NSError).detailedDemoDescription
            self?.showAlert(title: "Interstitial Ad Show Failed", message: errorMessage)
        }
    }
    
    func didHide(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("🔚 Interstitial didHideAd", ad: ad)
        
        showAdWhenLoaded = false
        interstitialAd = nil
        
        // Don't auto-load - user must press Load Interstitial button
        updateStatusUI(state: AdState.noAd)
    }
    
    func didClick(_ ad: CLXAd) {
        receivedCallbacks.insert(.clicked)
        DemoAppLogger.sharedInstance.logAdEvent("👆 Interstitial didClickAd", ad: ad)
    }
    
    func didPayRevenue(for ad: CLXAd) {
        receivedCallbacks.insert(.revenueReceived)
        DemoAppLogger.sharedInstance.logAdEvent("💰 Interstitial didPayRevenue", ad: ad)
    }
} 
