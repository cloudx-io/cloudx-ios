import UIKit
import CloudXCore

class BannerViewController: BaseAdViewController {
    private var bannerAd: CLXBannerAdView?
    private var autoRefreshButton: UIButton!
    private var autoRefreshEnabled = true
    private let settings = UserDefaultsSettings.shared
    private var gppScenarioPicker: GPPScenarioPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateStatusUI(state: .noAd)
    }
    
    private func setupUI() {
        // Create a vertical stack for buttons
        let buttonStack = UIStackView()
        buttonStack.axis = .vertical
        buttonStack.spacing = 12
        buttonStack.alignment = .center
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)
        
        // GPP Scenario Picker - Encapsulated Test Component
        //
        // PURPOSE: Provides a self-contained UI for selecting and applying GPP privacy test scenarios.
        // This component handles ALL GPP test logic internally, keeping BannerViewController clean.
        //
        // USAGE:
        // 1. Simply instantiate and add to view hierarchy (no configuration needed)
        // 2. Component self-manages: button creation, alert presentation, privacy SDK calls
        // 3. Zero code footprint in parent - follows DRY principle
        //
        // FEATURES:
        // - Privacy test scenarios (CCPA, GPP, ATT, regional variations)
        // - Action sheet picker with full scenario names and descriptions
        // - Automatic CloudXCore privacy SDK integration
        // - Console logging for test verification
        //
        // TESTING COVERAGE:
        // - CCPA Consent/Opt-Out
        // - ATT (iOS App Tracking Transparency) - Must be manually enabled/disabled in iOS Settings
        // - GPP regional (US-CA, US-National, EU)
        //
        gppScenarioPicker = GPPScenarioPickerView()
        gppScenarioPicker.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.addArrangedSubview(gppScenarioPicker)
        
        // Load Banner button
        let loadButton = UIButton(type: .system)
        loadButton.setTitle("Load Banner", for: .normal)
        loadButton.addTarget(self, action: #selector(loadBannerAd), for: .touchUpInside)
        loadButton.backgroundColor = .systemGreen
        loadButton.setTitleColor(.white, for: .normal)
        loadButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        loadButton.layer.cornerRadius = 8
        loadButton.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.addArrangedSubview(loadButton)
        
        // Auto-refresh toggle button
        autoRefreshButton = UIButton(type: .system)
        autoRefreshButton.setTitle("Stop Auto-Refresh", for: .normal)
        autoRefreshButton.addTarget(self, action: #selector(toggleAutoRefresh), for: .touchUpInside)
        autoRefreshButton.backgroundColor = .systemPurple
        autoRefreshButton.setTitleColor(.white, for: .normal)
        autoRefreshButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        autoRefreshButton.layer.cornerRadius = 8
        autoRefreshButton.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.addArrangedSubview(autoRefreshButton)
        
        // Button constraints
        NSLayoutConstraint.activate([
            buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            loadButton.widthAnchor.constraint(equalToConstant: 200),
            loadButton.heightAnchor.constraint(equalToConstant: 44),
            autoRefreshButton.widthAnchor.constraint(equalToConstant: 200),
            autoRefreshButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Auto-create and add banner to view hierarchy immediately
        createAndAddBannerToView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // No auto-loading - user must press Load Banner button
    }
    
    @objc private func loadBannerAd() {
        if isLoading {
            showAlert(title: "Info", message: "Banner is already loading.")
            return
        }
        
        if bannerAd == nil {
            createAndAddBannerToView()
        }
        
        guard let bannerAd = bannerAd else {
            return // Failed to create
        }
        
        // Start loading
        isLoading = true
        updateStatusUI(state: .loading)
        bannerAd.load()
    }
    
    @objc private func toggleAutoRefresh() {
        guard let bannerAd = bannerAd else {
            return
        }
        
        autoRefreshEnabled.toggle()
        
        if autoRefreshEnabled {
            bannerAd.startAutoRefresh()
            autoRefreshButton.setTitle("Stop Auto-Refresh", for: .normal)
            autoRefreshButton.backgroundColor = .systemRed
        } else {
            bannerAd.stopAutoRefresh()
            autoRefreshButton.setTitle("Start Auto-Refresh", for: .normal)
            autoRefreshButton.backgroundColor = .systemGreen
        }
    }
    
    private func createAndAddBannerToView() {
        guard bannerAd == nil else { return }
        
        DemoAppLogger.sharedInstance.logMessage("📱 Creating new banner ad instance...")
        
        // Create banner ad with placement from config
        let placement = CLXDemoConfigManager.sharedManager.currentConfig.bannerPlacement
        bannerAd = cloudX.createBanner(placement: placement, 
                                      viewController: self, 
                                      delegate: self)
        
        if bannerAd == nil {
            DemoAppLogger.sharedInstance.logMessage("❌ Failed to create Banner ad instance")
            showAlert(title: "Error", message: "Failed to create Banner ad instance")
        } else {
            DemoAppLogger.sharedInstance.logMessage("✅ Banner ad instance created successfully")
            bannerAd?.revenueDelegate = self
            // Add banner to view hierarchy immediately
            addBannerToViewHierarchy()
        }
    }
    
    private func addBannerToViewHierarchy() {
        guard let bannerAd = bannerAd, bannerAd.superview == nil else {
            return
        }
        
        // Add banner to view hierarchy
        bannerAd.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(bannerAd)
        
        NSLayoutConstraint.activate([
            bannerAd.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bannerAd.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bannerAd.widthAnchor.constraint(equalToConstant: 320),
            bannerAd.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetAdState()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func resetAdState() {
        bannerAd?.removeFromSuperview()
        bannerAd?.destroy()
        bannerAd = nil
        isLoading = false
        updateStatusUI(state: .noAd)
    }
}

extension BannerViewController: CLXBannerDelegate, CLXAdRevenueDelegate {
    func didLoad(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("✅ Banner didLoadAd", ad: ad)
        isLoading = false
        updateStatusUI(state: .ready)
    }
    
    func didFailToLoadAd(_ placementName: String, error: CLXError) {
        // No ad object exists on failure, so use logMessage instead of logAdEvent
        DemoAppLogger.sharedInstance.logMessage("❌ Banner failed to load for placement '\(placementName)' - Error: \(error.localizedDescription)")
        isLoading = false
        updateStatusUI(state: .noAd)
        bannerAd = nil
        
        DispatchQueue.main.async { [weak self] in
            let errorMessage = (error as NSError).detailedDemoDescription
            self?.showAlert(title: "Banner Ad Load Failed", message: errorMessage)
        }
    }
    
    func didDisplay(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👀 Banner didDisplayAd", ad: ad)
    }
    
    func didFailToDisplay(_ ad: CLXAd, error: CLXError) {
        DemoAppLogger.sharedInstance.logAdEvent("❌ Banner didFailToDisplayAd", ad: ad)
        bannerAd = nil
        
        DispatchQueue.main.async { [weak self] in
            let errorMessage = (error as NSError).detailedDemoDescription
            self?.showAlert(title: "Banner Ad Display Failed", message: errorMessage)
        }
    }
    
    func didHide(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("🔚 Banner didHideAd", ad: ad)
        bannerAd = nil
    }
    
    func didClick(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👆 Banner didClickAd", ad: ad)
    }
    
    func didRecordImpression(for ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👁️ Banner didRecordImpression", ad: ad)
    }
    
    func didPayRevenue(for ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("💰 Banner didPayRevenue", ad: ad)
    }
    
    // Banner-specific delegate methods
    func didExpand(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("🔍 Banner didExpandAd", ad: ad)
        
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(title: "Banner Expanded!", 
                           message: "Banner ad expanded to full screen.")
        }
    }
    
    func didCollapse(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("🔽 Banner didCollapseAd", ad: ad)
        
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(title: "Banner Collapsed!", 
                           message: "Banner ad collapsed back to normal size.")
        }
    }
}
