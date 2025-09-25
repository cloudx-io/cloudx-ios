import UIKit
import CloudXCore

class NativeBannerViewController: BaseAdViewController, CLXNativeDelegate {
    
    private var nativeBannerAd: CLXNativeAdView?
    private var adContainerView: UIView!
    private let settings = UserDefaultsSettings.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Native Banner"
        
        // Create a vertical stack container for button and ad
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 24
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)
        
        // Load Native Banner button
        let loadButton = UIButton(type: .system)
        loadButton.setTitle("Load Native Banner", for: .normal)
        loadButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        loadButton.backgroundColor = .systemGreen
        loadButton.setTitleColor(.white, for: .normal)
        loadButton.layer.cornerRadius = 8
        loadButton.translatesAutoresizingMaskIntoConstraints = false
        loadButton.addTarget(self, action: #selector(loadNativeBannerAd), for: .touchUpInside)
        mainStack.addArrangedSubview(loadButton)
        loadButton.widthAnchor.constraint(equalToConstant: 200).isActive = true
        loadButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        // Show Native Banner button
        let showButton = UIButton(type: .system)
        showButton.setTitle("Show Native Banner", for: .normal)
        showButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        showButton.backgroundColor = .systemBlue
        showButton.setTitleColor(.white, for: .normal)
        showButton.layer.cornerRadius = 8
        showButton.translatesAutoresizingMaskIntoConstraints = false
        showButton.addTarget(self, action: #selector(showNativeBannerAd), for: .touchUpInside)
        mainStack.addArrangedSubview(showButton)
        showButton.widthAnchor.constraint(equalToConstant: 200).isActive = true
        showButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        // Create container view for the ad
        adContainerView = UIView()
        adContainerView.backgroundColor = .lightGray
        adContainerView.layer.cornerRadius = 8
        adContainerView.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(adContainerView)
        adContainerView.widthAnchor.constraint(equalToConstant: view.frame.size.width - 40).isActive = true
        adContainerView.heightAnchor.constraint(equalToConstant: 100).isActive = true // Native banner is smaller
        
        // Center the stack view vertically in the parent view
        NSLayoutConstraint.activate([
            mainStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainStack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // No auto-loading - user must press Load Native Banner button
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetAdState()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private var placementName: String {
        return CLXDemoConfigManager.sharedManager.currentConfig.nativeBannerPlacement
    }
    
    @objc private func loadNativeBannerAd() {
        if !CloudXCore.shared.isInitialised {
            showAlert(title: "Error", message: "SDK not initialized. Please initialize SDK first.")
            return
        }
        
        if isLoading {
            showAlert(title: "Info", message: "Native banner is already loading.")
            return
        }
        
        if nativeBannerAd != nil {
            showAlert(title: "Info", message: "Native banner already loaded. Use Show Native Banner to display it.")
            return
        }
        
        loadNativeBanner()
    }
    
    private func loadNativeBanner() {
        print("[NativeBannerViewController] LOG: loadNativeBanner called")
        if !CloudXCore.shared.isInitialised {
            print("[NativeBannerViewController] LOG: SDK not initialized, returning.")
            return
        }

        if isLoading || nativeBannerAd != nil {
            print("[NativeBannerViewController] LOG: Ad process already started, returning.")
            return
        }

        print("[NativeBannerViewController] LOG: Starting native banner ad load process...")
        isLoading = true
        updateStatusUI(state: .loading)

        var placement = placementName
        if !settings.nativeMediumPlacement.isEmpty {
            placement = settings.nativeMediumPlacement
        }
        print("[NativeBannerViewController] LOG: Using placement: '\(placement)'")
        
        nativeBannerAd = CloudXCore.shared.createNativeAd(withPlacement: placement,
                                                         viewController: self,
                                                         delegate: self)
        
        if let nativeBannerAd = nativeBannerAd {
            print("[NativeBannerViewController] LOG: ✅ Native banner ad instance created successfully: \(nativeBannerAd)")
            print("[NativeBannerViewController] LOG: Loading native banner ad instance...")
            nativeBannerAd.load()
        } else {
            print("[NativeBannerViewController] LOG: ❌ Failed to create native banner with placement: '\(placement)'")
            isLoading = false
            updateStatusUI(state: .noAd)
            showAlert(title: "Error", message: "Failed to create native banner ad.")
        }
    }
    
    @objc private func showNativeBannerAd() {
        print("[NativeBannerViewController] LOG: showNativeBannerAd called.")
        
        if !CloudXCore.shared.isInitialised {
            print("[NativeBannerViewController] LOG: SDK not initialized, showing error")
            showAlert(title: "SDK Not Ready", message: "Please wait for SDK initialization to complete.")
            return
        }
        
        guard let nativeBannerAd = nativeBannerAd else {
            print("[NativeBannerViewController] LOG: No native banner ad instance, loading now...")
            loadNativeBanner()
            return
        }
        
        if !nativeBannerAd.isReady {
            print("[NativeBannerViewController] LOG: Ad not ready, loading now...")
            updateStatusUI(state: .loading)
            nativeBannerAd.load()
            return
        }
        
        print("[NativeBannerViewController] LOG: ✅ Ad is ready. Rendering now.")
        
        // Remove any existing ad view
        adContainerView.subviews.forEach { $0.removeFromSuperview() }
        
        // Add the native banner ad view to the container
        nativeBannerAd.frame = adContainerView.bounds
        adContainerView.addSubview(nativeBannerAd)
    }
    
    private func resetAdState() {
        if let nativeBannerAd = nativeBannerAd {
            // CRITICAL: Properly destroy the native banner ad to stop background processing
            nativeBannerAd.destroy()
            nativeBannerAd.removeFromSuperview()
            self.nativeBannerAd = nil
        }
    }
    
    // MARK: - CLXNativeDelegate
    
    func didLoad(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("✅ NativeBanner didLoadWithAd", ad: ad)
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusUI(state: .ready)
        }
    }
    
    func failToLoad(with ad: CLXAd, error: Error) {
        DemoAppLogger.sharedInstance.logMessage("❌ NativeBanner failToLoadWithAd - Error: \(error.localizedDescription)")
        
        DispatchQueue.main.async { [weak self] in
            self?.nativeBannerAd = nil
            let errorMessage = error.localizedDescription
            self?.showAlert(title: "Native Banner Error", message: errorMessage)
        }
    }
    
    func didShow(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👀 NativeBanner didShowWithAd", ad: ad)
    }
    
    func failToShow(with ad: CLXAd, error: Error) {
        DemoAppLogger.sharedInstance.logMessage("❌ NativeBanner failToShowWithAd - Error: \(error.localizedDescription)")
        
        DispatchQueue.main.async { [weak self] in
            self?.nativeBannerAd = nil
            let errorMessage = error.localizedDescription
            self?.showAlert(title: "Native Banner Error", message: errorMessage)
        }
    }
    
    func didHide(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logMessage("🔚 NativeBanner didHideWithAd - Ad: \(ad)")
        nativeBannerAd = nil
    }
    
    func didClick(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logMessage("👆 NativeBanner didClickWithAd - Ad: \(ad)")
    }
    
    func impression(on ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👁️ NativeBanner impressionOn", ad: ad)
    }
    
    func revenuePaid(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("💰 NativeBanner revenuePaid", ad: ad)
    }
    
    func closedByUserAction(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logMessage("✋ NativeBanner closedByUserActionWithAd - Ad: \(ad)")
        nativeBannerAd = nil
    }
}