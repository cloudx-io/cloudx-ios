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
        if !cloudX.isInitialised {
            showAlert(title: "Error", message: "SDK not initialized. Please initialize SDK first.")
            return
        }
        
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
        if !cloudX.isInitialised {
            return
        }

        if isLoading || interstitialAd != nil {
            return
        }

        isLoading = true
        updateStatusUI(state: AdState.loading)

        // Get placement from config manager (with settings override if provided)
        let originalPlacementName = CLXDemoConfigManager.sharedManager.currentConfig.interstitialPlacement
        var placement = originalPlacementName
        if !settings.interstitialPlacement.isEmpty {
            placement = settings.interstitialPlacement
        }
        
        interstitialAd = cloudX.createInterstitial(withPlacement: placement, delegate: self)
        
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
        // Don't auto-create - wait for user to press Load Interstitial button
    }
    
    // Remove the old createInterstitialAd and polling methods - they're replaced by loadInterstitial
    
    @objc private func showInterstitialAd() {
        if !cloudX.isInitialised {
            showAlert(title: "Error", message: "SDK not initialized. Please initialize SDK first.")
            return
        }
        
        guard let interstitialAd = interstitialAd else {
            showAlert(title: "Error", message: "No interstitial loaded. Please load an interstitial first.")
            return
        }
        
        if isLoading {
            showAlert(title: "Info", message: "Interstitial is still loading. Please wait.")
            return
        }
        
        if interstitialAd.isReady {
            interstitialAd.show(from: self)
        } else {
            showAlert(title: "Error", message: "Interstitial is not ready. Please try loading again.")
        }
    }
    
    private func resetAdState() {
        interstitialAd = nil
        isLoading = false
        showAdWhenLoaded = false
        updateStatusUI(state: AdState.noAd)
    }
}

extension InterstitialViewController: CLXInterstitialDelegate {
    func didLoad(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("✅ Interstitial didLoadWithAd", ad: ad)
        isLoading = false
        updateStatusUI(state: AdState.ready)
        // Don't auto-show - wait for user to press Show Interstitial button
    }
    
    func failToLoad(with ad: CLXAd, error: Error) {
        DemoAppLogger.sharedInstance.logAdEvent("❌ Interstitial failToLoadWithAd", ad: ad)
        isLoading = false
        updateStatusUI(state: AdState.noAd)
        
        DispatchQueue.main.async { [weak self] in
            let errorMessage = error.localizedDescription
            self?.showAlert(title: "Interstitial Ad Error", message: errorMessage)
            self?.interstitialAd = nil
        }
    }
    
    func didShow(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👀 Interstitial didShowWithAd", ad: ad)
    }
    
    func failToShow(with ad: CLXAd, error: Error) {
        DemoAppLogger.sharedInstance.logAdEvent("❌ Interstitial failToShowWithAd", ad: ad)
        updateStatusUI(state: AdState.noAd)
        
        DispatchQueue.main.async { [weak self] in
            self?.interstitialAd = nil
            let errorMessage = error.localizedDescription
            self?.showAlert(title: "Interstitial Ad Error", message: errorMessage)
        }
    }
    
    func didHide(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("🔚 Interstitial didHideWithAd", ad: ad)
        
        showAdWhenLoaded = false
        interstitialAd = nil
        
        // Don't auto-load - user must press Load Interstitial button
        updateStatusUI(state: AdState.noAd)
    }
    
    func didClick(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👆 Interstitial didClickWithAd", ad: ad)
    }
    
    func impression(on ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👁️ Interstitial impressionOn", ad: ad)
    }
    
    func revenuePaid(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("💰 Interstitial revenuePaid", ad: ad)
    }
    
    func closedByUserAction(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logMessage("✋ Interstitial closedByUserActionWithAd - Ad: \(ad)")
        showAdWhenLoaded = false
        interstitialAd = nil
        // Create new ad instance for next time
        loadInterstitial()
        updateStatusUI(state: AdState.noAd)
    }
} 
