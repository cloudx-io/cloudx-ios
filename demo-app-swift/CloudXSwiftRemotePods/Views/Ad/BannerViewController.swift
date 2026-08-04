import UIKit
import CloudXCore

class BannerViewController: BaseAdViewController {
    private var bannerAd: CLXBannerAdView?
    private var deferredBannerAd: CLXBannerAdView?
    private var autoRefreshButton: UIButton!
    private var loadDeferredButton: UIButton!
    private var autoRefreshEnabled = true
    private var isDeferredLoad = false
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
        
        // Load Banner button — standard flow: add to view hierarchy, then load
        let loadButton = UIButton(type: .system)
        loadButton.setTitle("Load Banner", for: .normal)
        loadButton.addTarget(self, action: #selector(loadBannerAd), for: .touchUpInside)
        loadButton.backgroundColor = .systemGreen
        loadButton.setTitleColor(.white, for: .normal)
        loadButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        loadButton.layer.cornerRadius = 8
        loadButton.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.addArrangedSubview(loadButton)
        
        // Load (Deferred) button — loads without adding to hierarchy, then shows on tap
        loadDeferredButton = UIButton(type: .system)
        loadDeferredButton.setTitle("Load (Deferred)", for: .normal)
        loadDeferredButton.addTarget(self, action: #selector(loadBannerDeferred), for: .touchUpInside)
        loadDeferredButton.backgroundColor = .systemBlue
        loadDeferredButton.setTitleColor(.white, for: .normal)
        loadDeferredButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        loadDeferredButton.layer.cornerRadius = 8
        loadDeferredButton.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.addArrangedSubview(loadDeferredButton)
        
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
            loadDeferredButton.widthAnchor.constraint(equalToConstant: 200),
            loadDeferredButton.heightAnchor.constraint(equalToConstant: 44),
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
        receivedCallbacks = []
        resetDeferredButtonState()
        if isLoading {
            showAlert(title: "Info", message: "Banner is already loading.")
            return
        }
        
        resetAdState()
        createAndAddBannerToView()
        
        guard let bannerAd = bannerAd else { return }
        
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
        
        addBannerToViewHierarchy()
    }
    
    @objc private func loadBannerDeferred() {
        receivedCallbacks = []
        if isLoading {
            showAlert(title: "Info", message: "Banner is already loading.")
            return
        }
        
        bannerAd?.removeFromSuperview()
        bannerAd?.destroy()
        bannerAd = nil
        deferredBannerAd?.removeFromSuperview()
        deferredBannerAd?.destroy()
        deferredBannerAd = nil
        isDeferredLoad = true
        
        var adUnitId = CLXDemoConfigManager.sharedManager.currentConfig.bannerAdUnitId
        if !settings.bannerAdUnitId.isEmpty {
            adUnitId = settings.bannerAdUnitId
        }
        deferredBannerAd = cloudX.createBanner(adUnitId: adUnitId)
        deferredBannerAd?.delegate = self
        deferredBannerAd?.revenueDelegate = self
        deferredBannerAd?.placement = "demo_banner"
        deferredBannerAd?.customData = "screen:home,position:bottom"
        
        isLoading = true
        updateStatusUI(state: .loading)
        deferredBannerAd?.load()
    }
    
    @objc private func showDeferredBanner() {
        guard isDeferredLoad, let deferred = deferredBannerAd else { return }
        isDeferredLoad = false
        bannerAd = deferred
        deferredBannerAd = nil
        addBannerToViewHierarchy()
        resetDeferredButtonState()
    }
    
    private func resetDeferredButtonState() {
        isDeferredLoad = false
        loadDeferredButton.setTitle("Load (Deferred)", for: .normal)
        loadDeferredButton.backgroundColor = .systemBlue
        loadDeferredButton.removeTarget(self, action: #selector(showDeferredBanner), for: .touchUpInside)
        loadDeferredButton.addTarget(self, action: #selector(loadBannerDeferred), for: .touchUpInside)
    }
    
    private func addBannerToViewHierarchy() {
        guard let bannerAd = bannerAd, bannerAd.superview == nil else {
            return
        }
        
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
        deferredBannerAd?.removeFromSuperview()
        deferredBannerAd?.destroy()
        deferredBannerAd = nil
        isLoading = false
        receivedCallbacks = []
        resetDeferredButtonState()
        updateStatusUI(state: .noAd)
    }

    // MARK: - QA Negative Path

    /// QA-only: abandons the banner WITHOUT calling `destroy()`.
    ///
    /// Reproduces the publisher mistake this scenario exists to catch.
    /// `removeFromSuperview` + nil drops every strong owner so the SDK's ad view
    /// deallocs; omitting `destroy()` is deliberate, since destroying would
    /// exercise the normal teardown path and prove nothing. Reachable only
    /// through the deep-link router — do NOT copy this as integration practice.
    @objc private func abandonBannerAd() {
        bannerAd?.removeFromSuperview()
        bannerAd = nil
        isLoading = false
        receivedCallbacks = []
        updateStatusUI(state: .noAd)
    }

    override func adViewForClickTesting() -> UIView? { bannerAd ?? deferredBannerAd }
}

extension BannerViewController: CLXBannerDelegate, CLXAdRevenueDelegate {
    func didLoad(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("✅ Banner didLoadAd", ad: ad)
        isLoading = false
        updateStatusUI(state: .ready)
        
        if isDeferredLoad {
            loadDeferredButton.setTitle("Show Banner", for: .normal)
            loadDeferredButton.backgroundColor = .systemOrange
            loadDeferredButton.removeTarget(self, action: #selector(loadBannerDeferred), for: .touchUpInside)
            loadDeferredButton.addTarget(self, action: #selector(showDeferredBanner), for: .touchUpInside)
        }
    }
    
    func didFailToLoadAd(_ adUnitId: String, error: CLXError) {
        DemoAppLogger.sharedInstance.logMessage("❌ Banner failed to load (\(adUnitId)) - Error: \(error.localizedDescription)")
        
        // Delegate may fire on a background queue (CFNetwork); all UIKit calls must be on main.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            self.updateStatusUI(state: .noAd)
            self.bannerAd?.removeFromSuperview()
            self.bannerAd?.destroy()
            self.bannerAd = nil
            self.deferredBannerAd?.destroy()
            self.deferredBannerAd = nil
            self.resetDeferredButtonState()
            
            let errorMessage = (error as NSError).detailedDemoDescription
            self.showAlert(title: "Banner Ad Load Failed", message: errorMessage)
        }
    }
    
    func didClick(_ ad: CLXAd) {
        receivedCallbacks.insert(.clicked)
        DemoAppLogger.sharedInstance.logAdEvent("👆 Banner didClickAd", ad: ad)
    }
    
    func didPayRevenue(for ad: CLXAd) {
        receivedCallbacks.insert(.revenueReceived)
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
