import UIKit
import CloudXCore

class MRECViewController: BaseAdViewController, CLXBannerDelegate {
    
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
        
        // Load MREC button
        let loadButton = UIButton(type: .system)
        loadButton.setTitle("Load MREC", for: .normal)
        loadButton.addTarget(self, action: #selector(loadMRECAd), for: .touchUpInside)
        loadButton.backgroundColor = .systemGreen
        loadButton.setTitleColor(.white, for: .normal)
        loadButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        loadButton.layer.cornerRadius = 8
        loadButton.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.addArrangedSubview(loadButton)
        
        // Show button removed - MREC is auto-added to view on push
        
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
            
            // Auto-refresh button positioned above status label
            autoRefreshButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            autoRefreshButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            autoRefreshButton.widthAnchor.constraint(equalToConstant: 200),
            autoRefreshButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Auto-create and add MREC to view hierarchy immediately
        createAndAddMRECToView()
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
        if !CloudXCore.shared.isInitialised {
            showAlert(title: "Error", message: "SDK not initialized. Please initialize SDK first.")
            return
        }
        
        if isLoading {
            showAlert(title: "Info", message: "MREC is already loading.")
            return
        }
        
        if mrecAd == nil {
            createAndAddMRECToView()
        }
        
        guard let mrecAd = mrecAd else {
            return // Failed to create
        }
        
        // Start loading
        isLoading = true
        updateStatusUI(state: .loading)
        mrecAd.load()
    }
    
    private func createAndAddMRECToView() {
        guard mrecAd == nil else { return }
        
        var placement = placementName
        if !settings.mrecPlacement.isEmpty {
            placement = settings.mrecPlacement
        }
        mrecAd = CloudXCore.shared.createMREC(withPlacement: placement, viewController: self, delegate: self)
        
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
    
    private func createMRECAd() {
        // Legacy method - now just calls the new method
        createAndAddMRECToView()
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
    
    private var placementName: String {
        return CLXDemoConfigManager.sharedManager.currentConfig.mrecPlacement
    }
    
    private func loadMREC() {
        if !CloudXCore.shared.isInitialised {
            return
        }

        if isLoading || mrecAd != nil {
            return
        }

        isLoading = true
        updateStatusUI(state: .loading)

        let placement = placementName
        mrecAd = CloudXCore.shared.createMREC(withPlacement: placement,
                                            viewController: self,
                                            delegate: self)
        
        if let mrecAd = mrecAd {
            mrecAd.load()
        } else {
            isLoading = false
            updateStatusUI(state: .noAd)
            showAlert(title: "Error", message: "Failed to create MREC.")
        }
    }
    
    // MARK: - CLXBannerDelegate
    
    func didLoad(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("✅ MREC didLoadWithAd", ad: ad)
        isLoading = false
        updateStatusUI(state: .ready)
        
        // Don't auto-show - user must press Show MREC button
    }
    
    func failToLoad(with ad: CLXAd, error: Error) {
        DemoAppLogger.sharedInstance.logAdEvent("❌ MREC failToLoadWithAd", ad: ad)
        isLoading = false
        
        DispatchQueue.main.async { [weak self] in
            let errorMessage = error.localizedDescription
            self?.showAlert(title: "MREC Error", message: errorMessage)
        }
    }
    
    func didShow(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👀 MREC didShowWithAd", ad: ad)
    }
    
    func failToShow(with ad: CLXAd, error: Error) {
        DemoAppLogger.sharedInstance.logAdEvent("❌ MREC failToShowWithAd", ad: ad)
        
        DispatchQueue.main.async { [weak self] in
            let errorMessage = error.localizedDescription
            self?.showAlert(title: "MREC Error", message: errorMessage)
        }
    }
    
    func didHide(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("🔚 MREC didHideWithAd", ad: ad)
        mrecAd = nil
    }
    
    func didClick(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👆 MREC didClickWithAd", ad: ad)
    }
    
    func impression(on ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👁️ MREC impressionOn", ad: ad)
    }
    
    func revenuePaid(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("💰 MREC revenuePaid", ad: ad)
    }
    
    func closedByUserAction(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("✋ MREC closedByUserActionWithAd", ad: ad)
        mrecAd = nil
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
        DemoAppLogger.sharedInstance.logAdEvent("🔍 MREC didCollapseAd", ad: ad)
        
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(title: "MREC Collapsed!", 
                           message: "MREC ad collapsed from full screen.")
        }
    }
}