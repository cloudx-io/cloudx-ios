import UIKit
import CloudXCore

class BannerViewController: BaseAdViewController {
    private var bannerAd: CLXBannerAdView?
    private var autoRefreshButton: UIButton!
    private var autoRefreshEnabled = true
    private let settings = UserDefaultsSettings.shared
    
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
        
        // SDK now guarantees non-nil return from create methods
        guard let bannerAd = bannerAd else { return }
        
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
        
        var adUnitId = CLXDemoConfigManager.sharedManager.currentConfig.bannerAdUnitId
        if !settings.bannerAdUnitId.isEmpty {
            adUnitId = settings.bannerAdUnitId
        }
        bannerAd = cloudX.createBanner(adUnitId: adUnitId)
        bannerAd?.delegate = self
        bannerAd?.revenueDelegate = self
        bannerAd?.placement = "demo_banner"
        bannerAd?.customData = "screen:home,position:bottom"
        
        // Add banner to view hierarchy immediately
        addBannerToViewHierarchy()
    }
    
    private func addBannerToViewHierarchy() {
        guard let bannerAd = bannerAd, bannerAd.superview == nil else {
            return
        }
        
        // Add banner to view hierarchy
        bannerAd.translatesAutoresizingMaskIntoConstraints = false
        bannerAd.backgroundColor = .red // DEBUG: Make banner container visible
        
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
    
    func didFailToLoadAd(_ adUnitId: String, error: CLXError) {
        DemoAppLogger.sharedInstance.logMessage("❌ Banner failed to load (\(adUnitId)) - Error: \(error.localizedDescription)")
        isLoading = false
        updateStatusUI(state: .noAd)
        bannerAd = nil
        
        DispatchQueue.main.async { [weak self] in
            let errorMessage = (error as NSError).detailedDemoDescription
            self?.showAlert(title: "Banner Ad Load Failed", message: errorMessage)
        }
    }
    
    func didClick(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👆 Banner didClickAd", ad: ad)
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
