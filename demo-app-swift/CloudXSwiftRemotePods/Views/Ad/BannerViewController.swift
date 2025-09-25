import UIKit
import CloudXCore

class BannerViewController: BaseAdViewController {
    private var bannerAd: CLXBannerAdView?
    private var isSDKInitialized = false
    private var autoRefreshButton: UIButton!
    private var autoRefreshEnabled = true
    private let settings = UserDefaultsSettings.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotifications()
        
        // Check if SDK is already initialized
        isSDKInitialized = cloudX.isInitialised
        updateStatusUI(state: .noAd)
    }
    
    private func setupUI() {
        // Create a vertical stack for buttons
        let buttonStack = UIStackView()
        buttonStack.axis = .vertical
        buttonStack.spacing = 16
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
        if !cloudX.isInitialised {
            showAlert(title: "Error", message: "SDK not initialized. Please initialize SDK first.")
            return
        }
        
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
        
        print("📱 Creating new banner ad instance...")
        
        // Create banner ad with placement from config
        let placement = CLXDemoConfigManager.sharedManager.currentConfig.bannerPlacement
        bannerAd = cloudX.createBanner(withPlacement: placement, 
                                      viewController: self, 
                                      delegate: self, 
                                      tmax: nil)
        
        if bannerAd == nil {
            print("❌ Failed to create Banner ad instance")
            showAlert(title: "Error", message: "Failed to create Banner ad instance")
        } else {
            print("✅ Banner ad instance created successfully")
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
        createBannerAd()
    }
    
    private func createBannerAd() {
        guard bannerAd == nil else { return }
        print("📱 Creating new banner ad instance...")
        
        // Create banner ad with placement from config
        let placement = CLXDemoConfigManager.sharedManager.currentConfig.bannerPlacement
        bannerAd = cloudX.createBanner(withPlacement: placement, 
                                      viewController: self, 
                                      delegate: self, 
                                      tmax: nil)
        
        if bannerAd == nil {
            print("❌ Failed to create Banner ad instance")
            showAlert(title: "Error", message: "Failed to create Banner ad instance")
        } else {
            print("✅ Banner ad instance created successfully")
        }
    }
    
    @objc private func showBannerAd() {
        print("🔄 Starting banner ad load process...")
        
        guard isSDKInitialized else {
            showAlert(title: "Error", message: "SDK not initialized. Please initialize SDK first.")
            return
        }
        
        guard !isLoading else {
            print("⏳ Already loading an ad, please wait...")
            return
        }
        
        // Create a new banner ad instance if needed
        if bannerAd == nil {
            createBannerAd()
        }
        
        guard let banner = bannerAd else {
            showAlert(title: "Error", message: "Failed to create banner.")
            return
        }
        
        banner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            banner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            banner.widthAnchor.constraint(equalToConstant: 320),
            banner.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        isLoading = true
        updateStatusUI(state: .loading)
        print("📱 Loading banner ad...")
        banner.load()
    }
    
    private func resetAdState() {
        bannerAd?.removeFromSuperview()
        bannerAd = nil
        isLoading = false
        updateStatusUI(state: .noAd)
    }
}

extension BannerViewController: CLXBannerDelegate {
    func didLoad(with ad: CLXAd) {
        print("✅ Banner loaded successfully")
        isLoading = false
        updateStatusUI(state: .ready)
    }
    
    func failToLoad(with ad: CLXAd, error: Error) {
        print("❌ Failed to load Banner Ad: \(error)")
        isLoading = false
        updateStatusUI(state: .noAd)
        bannerAd = nil
        
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(title: "Ad Load Error", message: error.localizedDescription)
        }
    }
    
    func didShow(with ad: CLXAd) {
        print("👀 Banner did show")
    }
    
    func failToShow(with ad: CLXAd, error: Error) {
        print("❌ Banner fail to show: \(error)")
        bannerAd = nil
        
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(title: "Ad Show Error", message: error.localizedDescription)
        }
    }
    
    func didHide(with ad: CLXAd) {
        print("🔚 Banner did hide")
        bannerAd = nil
    }
    
    func didClick(with ad: CLXAd) {
        print("👆 Banner did click")
    }
    
    func impression(on ad: CLXAd) {
        print("👁️ Banner impression recorded")
    }
    
    func revenuePaid(_ ad: CLXAd) {
        print("💰 Banner revenue paid")
    }
    
    func closedByUserAction(with ad: CLXAd) {
        print("✋ Banner closed by user action")
        bannerAd = nil
    }
} 
