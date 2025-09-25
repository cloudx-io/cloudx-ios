import UIKit
import CloudXCore

class NativeViewController: BaseAdViewController, CLXNativeDelegate {
    
    private var nativeAd: CLXNativeAdView?
    private var adContainerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Native"
        
        // Create a vertical stack container for button and ad
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 24
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)
        
        // Load Native button
        let loadButton = UIButton(type: .system)
        loadButton.setTitle("Load Native", for: .normal)
        loadButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        loadButton.backgroundColor = .systemGreen
        loadButton.setTitleColor(.white, for: .normal)
        loadButton.layer.cornerRadius = 8
        loadButton.translatesAutoresizingMaskIntoConstraints = false
        loadButton.addTarget(self, action: #selector(loadNativeAd), for: .touchUpInside)
        mainStack.addArrangedSubview(loadButton)
        loadButton.widthAnchor.constraint(equalToConstant: 200).isActive = true
        loadButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        // Show Native button
        let showButton = UIButton(type: .system)
        showButton.setTitle("Show Native", for: .normal)
        showButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        showButton.backgroundColor = .systemBlue
        showButton.setTitleColor(.white, for: .normal)
        showButton.layer.cornerRadius = 8
        showButton.translatesAutoresizingMaskIntoConstraints = false
        showButton.addTarget(self, action: #selector(showNativeAd), for: .touchUpInside)
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
        adContainerView.heightAnchor.constraint(equalToConstant: 250).isActive = true
        
        // Center the stack view vertically in the parent view
        NSLayoutConstraint.activate([
            mainStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainStack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // No auto-loading - user must press Load Native button
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetAdState()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        // Ensure cleanup even if viewWillDisappear wasn't called
        resetAdState()
    }
    
    private var placementName: String {
        return CLXDemoConfigManager.sharedManager.currentConfig.nativePlacement
    }
    
    @objc private func loadNativeAd() {
        if !CloudXCore.shared.isInitialised {
            showAlert(title: "Error", message: "SDK not initialized. Please initialize SDK first.")
            return
        }
        
        if isLoading {
            showAlert(title: "Info", message: "Native ad is already loading.")
            return
        }
        
        if nativeAd != nil {
            showAlert(title: "Info", message: "Native ad already loaded. Use Show Native to display it.")
            return
        }
        
        loadNative()
    }
    
    private func loadNative() {
        if !CloudXCore.shared.isInitialised {
            return
        }

        if isLoading || nativeAd != nil {
            return
        }

        isLoading = true
        updateStatusUI(state: .loading)

        let placement = placementName
        nativeAd = CloudXCore.shared.createNativeAd(withPlacement: placement,
                                                   viewController: self,
                                                   delegate: self)
        
        if let nativeAd = nativeAd {
            nativeAd.load()
        } else {
            isLoading = false
            updateStatusUI(state: .noAd)
            showAlert(title: "Error", message: "Failed to create native ad.")
        }
    }
    
    @objc private func showNativeAd() {
        if !CloudXCore.shared.isInitialised {
            showAlert(title: "Error", message: "SDK not initialized. Please initialize SDK first.")
            return
        }
        
        guard let nativeAd = nativeAd else {
            showAlert(title: "Error", message: "No native ad loaded. Please load a native ad first.")
            return
        }
        
        if isLoading {
            showAlert(title: "Info", message: "Native ad is still loading. Please wait.")
            return
        }
        
        if !nativeAd.isReady {
            showAlert(title: "Error", message: "Native ad is not ready. Please try loading again.")
            return
        }
        
        // Remove any existing ad view
        adContainerView.subviews.forEach { $0.removeFromSuperview() }
        
        // Add the native ad view to the container
        nativeAd.frame = adContainerView.bounds
        adContainerView.addSubview(nativeAd)
    }
    
    private func resetAdState() {
        if let nativeAd = nativeAd {
            // CRITICAL: Properly destroy the native ad to stop background processing
            nativeAd.destroy()
            nativeAd.removeFromSuperview()
            self.nativeAd = nil
        }
    }
    
    // MARK: - CLXNativeDelegate
    
    func didLoad(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("✅ Native didLoadWithAd", ad: ad)
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            self?.updateStatusUI(state: .ready)
        }
        
        // Don't auto-show - user must press Show Native button
    }
    
    func failToLoad(with ad: CLXAd, error: Error) {
        DemoAppLogger.sharedInstance.logAdEvent("❌ Native failToLoadWithAd", ad: ad)
        
        DispatchQueue.main.async { [weak self] in
            self?.nativeAd = nil
            let errorMessage = error.localizedDescription
            self?.showAlert(title: "Native Ad Error", message: errorMessage)
        }
    }
    
    func didShow(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👀 Native didShowWithAd", ad: ad)
    }
    
    func failToShow(with ad: CLXAd, error: Error) {
        DemoAppLogger.sharedInstance.logAdEvent("❌ Native failToShowWithAd", ad: ad)
        
        DispatchQueue.main.async { [weak self] in
            self?.nativeAd = nil
            let errorMessage = error.localizedDescription
            self?.showAlert(title: "Native Ad Error", message: errorMessage)
        }
    }
    
    func didHide(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("🔚 Native didHideWithAd", ad: ad)
        nativeAd = nil
    }
    
    func didClick(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👆 Native didClickWithAd", ad: ad)
    }
    
    func impression(on ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👁️ Native impressionOn", ad: ad)
    }
    
    func revenuePaid(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("💰 Native revenuePaid", ad: ad)
    }
    
    func closedByUserAction(with ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("✋ Native closedByUserActionWithAd", ad: ad)
        nativeAd = nil
    }
}