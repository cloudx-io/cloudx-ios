import UIKit
import CloudXCore

class AppOpenViewController: BaseAdViewController {
    private var appOpenAd: CLXAppOpen?
    private var showAdWhenLoaded = false
    
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
        
        // Load App Open button
        let loadButton = UIButton(type: .system)
        loadButton.setTitle("Load App Open", for: .normal)
        loadButton.addTarget(self, action: #selector(loadAppOpenAd), for: .touchUpInside)
        loadButton.backgroundColor = .systemGreen
        loadButton.setTitleColor(.white, for: .normal)
        loadButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        loadButton.layer.cornerRadius = 8
        loadButton.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.addArrangedSubview(loadButton)
        
        // Show App Open button
        let showButton = UIButton(type: .system)
        showButton.setTitle("Show App Open", for: .normal)
        showButton.addTarget(self, action: #selector(showAppOpenAd), for: .touchUpInside)
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
        // No auto-loading - user must press Load App Open button
    }
    
    @objc private func loadAppOpenAd() {
        receivedCallbacks = []
        
        if isLoading {
            showAlert(title: "Info", message: "App Open is already loading.")
            return
        }
        
        if appOpenAd != nil {
            showAlert(title: "Info", message: "App Open already loaded. Use Show App Open to display it.")
            return
        }
        
        loadAppOpen()
    }
    
    private func loadAppOpen() {

        if isLoading || appOpenAd != nil {
            return
        }

        isLoading = true
        updateStatusUI(state: AdState.loading)

        // Get ad unit ID from config manager (launch override honored in applyLaunchOverrides)
        let adUnitId = CLXDemoConfigManager.sharedManager.currentConfig.appOpenAdUnitId

        appOpenAd = cloudX.createAppOpen(adUnitId: adUnitId)
        appOpenAd?.delegate = self
        appOpenAd?.revenueDelegate = self
        
        if let appOpenAd = appOpenAd {
            appOpenAd.load()
        } else {
            isLoading = false
            updateStatusUI(state: AdState.noAd)
            showAlert(title: "Error", message: "Failed to create app open.")
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
        // Don't auto-create - wait for user to press Load App Open button
    }
    
    @objc private func showAppOpenAd() {
        
        guard let appOpenAd = appOpenAd else {
            showAlert(title: "Error", message: "No app open loaded. Please load an app open first.")
            return
        }
        
        if isLoading {
            showAlert(title: "Info", message: "App Open is still loading. Please wait.")
            return
        }
        
        if appOpenAd.isReady {
            appOpenAd.show(from: self)
        } else {
            showAlert(title: "Error", message: "App Open is not ready. Please try loading again.")
        }
    }
    
    private func resetAdState() {
        appOpenAd = nil
        isLoading = false
        showAdWhenLoaded = false
        receivedCallbacks = []
        updateStatusUI(state: AdState.noAd)
    }
}

extension AppOpenViewController: CLXAppOpenDelegate, CLXAdRevenueDelegate {
    func didLoad(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("✅ AppOpen didLoadAd", ad: ad)
        isLoading = false
        receivedCallbacks.insert(.loaded)
        updateStatusUI(state: AdState.ready)
        // Don't auto-show - wait for user to press Show App Open button
    }
    
    func didFailToLoadAd(_ adUnitId: String, error: CLXError) {
        // No ad object exists on failure, so use logMessage instead of logAdEvent
        DemoAppLogger.sharedInstance.logMessage("❌ AppOpen failed to load for ad unit '\(adUnitId)' - Error: \(error.localizedDescription)")
        isLoading = false
        updateStatusUI(state: AdState.noAd)
        
        DispatchQueue.main.async { [weak self] in
            let errorMessage = error.localizedDescription
            self?.showAlert(title: "App Open Ad Error", message: errorMessage)
            self?.appOpenAd = nil
        }
    }
    
    func didDisplay(_ ad: CLXAd) {
        receivedCallbacks.insert(.displayed)
        DemoAppLogger.sharedInstance.logAdEvent("👀 AppOpen didDisplayAd", ad: ad)
    }
    
    func didFailToDisplay(_ ad: CLXAd, error: CLXError) {
        DemoAppLogger.sharedInstance.logAdEvent("❌ AppOpen didFailToDisplayAd", ad: ad)
        updateStatusUI(state: AdState.noAd)
        
        DispatchQueue.main.async { [weak self] in
            self?.appOpenAd = nil
            let errorMessage = error.localizedDescription
            self?.showAlert(title: "App Open Ad Error", message: errorMessage)
        }
    }
    
    func didHide(_ ad: CLXAd) {
        receivedCallbacks.insert(.hidden)
        DemoAppLogger.sharedInstance.logAdEvent("🔚 AppOpen didHideAd", ad: ad)
        
        showAdWhenLoaded = false
        appOpenAd = nil
        
        // Don't auto-load - user must press Load App Open button
        updateStatusUI(state: AdState.noAd)
    }
    
    func didClick(_ ad: CLXAd) {
        receivedCallbacks.insert(.clicked)
        DemoAppLogger.sharedInstance.logAdEvent("👆 AppOpen didClickAd", ad: ad)
    }
    
    func didPayRevenue(for ad: CLXAd) {
        receivedCallbacks.insert(.revenueReceived)
        DemoAppLogger.sharedInstance.logAdEvent("💰 AppOpen didPayRevenue", ad: ad)
    }
} 
