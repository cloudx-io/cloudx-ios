import UIKit
import CloudXCore

class NativeViewController: BaseAdViewController {
    private var nativeAd: CLXNativeAdView?
    private var isSDKInitialized = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCenteredButton(title: "Show Native", action: #selector(showNativeAd))
        setupNotifications()
        
        // Check if SDK is already initialized
        isSDKInitialized = cloudX.isInitialised
        updateStatusUI(state: .noAd)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create ad if SDK is already initialized
        if isSDKInitialized && nativeAd == nil {
            createNativeAd()
        }
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
        createNativeAd()
    }
    
    private func createNativeAd() {
        guard nativeAd == nil else { return }
        print("📱 Creating new Native ad instance...")
        
        // Create native ad with verified placement
        let placementName = "native1"
        nativeAd = cloudX.createNativeAd(withPlacement: placementName, viewController: self, delegate: self)
        
        if nativeAd == nil {
            print("❌ Failed to create Native ad instance")
            showAlert(title: "Error", message: "Failed to create Native ad instance")
        } else {
            print("✅ Native ad instance created successfully")
        }
    }
    
    @objc private func showNativeAd() {
        print("🔄 Starting native ad load process...")
        
        guard isSDKInitialized else {
            showAlert(title: "Error", message: "SDK not initialized. Please initialize SDK first.")
            return
        }
        
        guard !isLoading else {
            print("⏳ Already loading an ad, please wait...")
            return
        }
        
        guard let native = nativeAd else {
            showAlert(title: "Error", message: "Failed to create native ad.")
            return
        }
        
        // Add to view hierarchy
        native.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(native)
        NSLayoutConstraint.activate([
            native.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            native.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            native.widthAnchor.constraint(equalToConstant: 300),
            native.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        isLoading = true
        updateStatusUI(state: .loading)
        print("📱 Loading native ad...")
        native.load()
    }
    
    private func resetAdState() {
        nativeAd?.removeFromSuperview()
        nativeAd = nil
        isLoading = false
        updateStatusUI(state: .noAd)
    }
}

extension NativeViewController: CLXNativeDelegate {
    func didLoad(with ad: CLXAd) {
        print("✅ Native ad loaded successfully")
        isLoading = false
        updateStatusUI(state: .ready)
    }
    
    func failToLoad(with ad: CLXAd, error: Error) {
        print("❌ Failed to load Native Ad: \(error)")
        isLoading = false
        updateStatusUI(state: .noAd)
        nativeAd = nil
        
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(title: "Ad Load Error", message: error.localizedDescription)
        }
    }
    
    func didShow(with ad: CLXAd) {
        print("👀 Native ad did show")
    }
    
    func failToShow(with ad: CLXAd, error: Error) {
        print("❌ Native ad fail to show: \(error)")
        nativeAd = nil
        
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(title: "Ad Show Error", message: error.localizedDescription)
        }
    }
    
    func didHide(with ad: CLXAd) {
        print("🔚 Native ad did hide")
        nativeAd = nil
    }
    
    func didClick(with ad: CLXAd) {
        print("👆 Native ad did click")
    }
    
    func impression(on ad: CLXAd) {
        print("👁️ Native ad impression recorded")
    }
    
    func closedByUserAction(with ad: CLXAd) {
        print("✋ Native ad closed by user action")
        nativeAd = nil
    }
} 
