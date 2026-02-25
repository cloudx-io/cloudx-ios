import UIKit
import CloudXCore

class MRECViewController: BaseAdViewController, CLXBannerDelegate, CLXAdRevenueDelegate {
    
    private var mrecAd: CLXBannerAdView?
    private var autoRefreshButton: UIButton!
    private var autoRefreshEnabled = true // Default to enabled
    private let settings = UserDefaultsSettings.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "MREC"
        
        // Create a vertical stack for buttons
        let buttonStack = UIStackView()
        buttonStack.axis = .vertical
        buttonStack.spacing = 16
        buttonStack.alignment = .center
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)
        
        // Load MREC button (new API — no viewController)
        let loadButton = UIButton(type: .system)
        loadButton.setTitle("Load MREC (New API)", for: .normal)
        loadButton.addTarget(self, action: #selector(loadMRECAd), for: .touchUpInside)
        loadButton.backgroundColor = .systemGreen
        loadButton.setTitleColor(.white, for: .normal)
        loadButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        loadButton.layer.cornerRadius = 8
        loadButton.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.addArrangedSubview(loadButton)
        
        // Load MREC button (deprecated API — passes viewController)
        let loadDeprecatedButton = UIButton(type: .system)
        loadDeprecatedButton.setTitle("Load MREC (Deprecated)", for: .normal)
        loadDeprecatedButton.addTarget(self, action: #selector(loadMRECAdDeprecated), for: .touchUpInside)
        loadDeprecatedButton.backgroundColor = .systemOrange
        loadDeprecatedButton.setTitleColor(.white, for: .normal)
        loadDeprecatedButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        loadDeprecatedButton.layer.cornerRadius = 8
        loadDeprecatedButton.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.addArrangedSubview(loadDeprecatedButton)
        
        // Auto-refresh toggle button (positioned separately above status label)
        autoRefreshButton = UIButton(type: .system)
        autoRefreshButton.setTitle("Stop Auto-Refresh", for: .normal)
        autoRefreshButton.addTarget(self, action: #selector(toggleAutoRefresh), for: .touchUpInside)
        autoRefreshButton.backgroundColor = .systemPurple
        autoRefreshButton.setTitleColor(.white, for: .normal)
        autoRefreshButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        autoRefreshButton.layer.cornerRadius = 8
        autoRefreshButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(autoRefreshButton)
        
        // Button constraints
        NSLayoutConstraint.activate([
            buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            loadButton.widthAnchor.constraint(equalToConstant: 200),
            loadButton.heightAnchor.constraint(equalToConstant: 44),
            loadDeprecatedButton.widthAnchor.constraint(equalToConstant: 200),
            loadDeprecatedButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Auto-refresh button positioned above status label
            autoRefreshButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            autoRefreshButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            autoRefreshButton.widthAnchor.constraint(equalToConstant: 200),
            autoRefreshButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Don't auto-create MREC - wait for user to load
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Update status based on current ad state
        if mrecAd != nil && !isLoading {
            updateStatusUI(state: .ready)
        } else if isLoading {
            updateStatusUI(state: .loading)
        } else {
            updateStatusUI(state: .noAd)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetAdState()
    }
    
    deinit {
        // Ensure cleanup even if viewWillDisappear wasn't called
        resetAdState()
    }
    
    @objc private func loadMRECAd() {
        if isLoading {
            showAlert(title: "Info", message: "MREC is already loading.")
            return
        }
        
        resetAdState()
        createAndAddMRECToView()
        
        guard let mrecAd = mrecAd else { return }
        
        isLoading = true
        updateStatusUI(state: .loading)
        mrecAd.load()
    }
    
    private func createAndAddMRECToView() {
        guard mrecAd == nil else { return }
        
        var adUnitId = self.adUnitId
        if !settings.mrecAdUnitId.isEmpty {
            adUnitId = settings.mrecAdUnitId
        }
        mrecAd = CloudXCore.shared.createMREC(adUnitId: adUnitId)
        mrecAd?.delegate = self
        mrecAd?.revenueDelegate = self

        guard let mrecAd = mrecAd else {
            showAlert(title: "Error", message: "Failed to create MREC.")
            return
        }
        
        // Add MREC to view hierarchy immediately
        mrecAd.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mrecAd)
        
        NSLayoutConstraint.activate([
            mrecAd.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mrecAd.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 210),
            mrecAd.widthAnchor.constraint(equalToConstant: 300),
            mrecAd.heightAnchor.constraint(equalToConstant: 250)
        ])
    }
    
    @objc private func loadMRECAdDeprecated() {
        if isLoading {
            showAlert(title: "Info", message: "MREC is already loading.")
            return
        }
        
        resetAdState()
        createAndAddMRECToViewDeprecated()
        
        guard let mrecAd = mrecAd else { return }
        
        isLoading = true
        updateStatusUI(state: .loading)
        mrecAd.load()
    }
    
    private func createAndAddMRECToViewDeprecated() {
        var adUnitId = self.adUnitId
        if !settings.mrecAdUnitId.isEmpty {
            adUnitId = settings.mrecAdUnitId
        }
        mrecAd = CloudXCore.shared.createMREC(adUnitId: adUnitId, viewController: self)
        mrecAd?.delegate = self
        mrecAd?.revenueDelegate = self
        
        guard let mrecAd = mrecAd else {
            showAlert(title: "Error", message: "Failed to create MREC (deprecated API).")
            return
        }
        
        mrecAd.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mrecAd)
        
        NSLayoutConstraint.activate([
            mrecAd.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mrecAd.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 210),
            mrecAd.widthAnchor.constraint(equalToConstant: 300),
            mrecAd.heightAnchor.constraint(equalToConstant: 250)
        ])
    }
    
    // showMRECAd method removed - MREC is auto-added to view on push
    
    private func resetAdState() {
        if let mrecAd = mrecAd {
            // CRITICAL: Properly destroy the MREC to stop auto-refresh timers and background processing
            mrecAd.destroy()
            mrecAd.removeFromSuperview()
            self.mrecAd = nil
        }
        isLoading = false
    }
    
    @objc private func toggleAutoRefresh() {
        guard let mrecAd = mrecAd else {
            return
        }
        
        autoRefreshEnabled = !autoRefreshEnabled
        
        if autoRefreshEnabled {
            mrecAd.startAutoRefresh()
            autoRefreshButton.setTitle("Stop Auto-Refresh", for: .normal)
            autoRefreshButton.backgroundColor = .systemRed
        } else {
            mrecAd.stopAutoRefresh()
            autoRefreshButton.setTitle("Start Auto-Refresh", for: .normal)
            autoRefreshButton.backgroundColor = .systemGreen
        }
    }
    
    private var adUnitId: String {
        return CLXDemoConfigManager.sharedManager.currentConfig.mrecAdUnitId
    }
    
    private func loadMREC() {

        if isLoading || mrecAd != nil {
            return
        }

        isLoading = true
        updateStatusUI(state: .loading)

        let adUnitId = self.adUnitId
        mrecAd = CloudXCore.shared.createMREC(adUnitId: adUnitId)
        mrecAd?.delegate = self
        
        if let mrecAd = mrecAd {
            mrecAd.load()
        } else {
            isLoading = false
            updateStatusUI(state: .noAd)
            showAlert(title: "Error", message: "Failed to create MREC.")
        }
    }
    
    // MARK: - CLXBannerDelegate
    
    func didLoad(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("✅ MREC didLoadAd", ad: ad)
        isLoading = false
        updateStatusUI(state: .ready)
        
        // Don't auto-show - user must press Show MREC button
    }
    
    func didFailToLoadAd(_ adUnitId: String, error: CLXError) {
        // No ad object exists on failure, so use logMessage instead of logAdEvent
        DemoAppLogger.sharedInstance.logMessage("❌ MREC failed to load for ad unit '\(adUnitId)' - Error: \(error.localizedDescription)")
        isLoading = false
        updateStatusUI(state: .noAd)
        
        DispatchQueue.main.async { [weak self] in
            let errorMessage = error.localizedDescription
            self?.showAlert(title: "MREC Error", message: errorMessage)
        }
    }
    
    func didClick(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👆 MREC didClickAd", ad: ad)
    }
    
    func didPayRevenue(for ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("💰 MREC didPayRevenue", ad: ad)
    }
    
    // Banner-specific delegate methods (MREC is a banner type)
    func didExpand(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("🔍 MREC didExpandAd", ad: ad)
        
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(title: "MREC Expanded!", 
                           message: "MREC ad expanded to full screen.")
        }
    }
    
    func didCollapse(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("🔽 MREC didCollapseAd", ad: ad)
        
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(title: "MREC Collapsed!", 
                           message: "MREC ad collapsed back to normal size.")
        }
    }
}