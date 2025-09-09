import UIKit
import CloudXCore

class MRECViewController: BaseAdViewController {
    private var mrecAd: CLXBannerAdView?
    private var isSDKInitialized = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCenteredButton(title: "Show MREC", action: #selector(showMRECAd))
        setupNotifications()
        
        // Check if SDK is already initialized
        isSDKInitialized = cloudX.isInitialised
        updateStatusUI(state: .noAd)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create ad if SDK is already initialized
        if isSDKInitialized && mrecAd == nil {
            createMRECAd()
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
        createMRECAd()
    }
    
    private func createMRECAd() {
        guard mrecAd == nil else { return }
        print("📱 Creating new MREC ad instance...")
        
        // Create MREC ad with verified placement
        mrecAd = cloudX.createMREC(withPlacement: "mrec1", viewController: self, delegate: self)
        
        if mrecAd == nil {
            print("❌ Failed to create MREC ad instance")
            showAlert(title: "Error", message: "Failed to create MREC ad instance")
        } else {
            print("✅ MREC ad instance created successfully")
        }
    }
    
    @objc private func showMRECAd() {
        print("🔄 Starting MREC ad load process...")
        
        guard isSDKInitialized else {
            showAlert(title: "Error", message: "SDK not initialized. Please initialize SDK first.")
            return
        }
        
        guard !isLoading else {
            print("⏳ Already loading an ad, please wait...")
            return
        }
        
        // Create a new MREC ad instance if needed
        if mrecAd == nil {
            createMRECAd()
        }
        
        guard let mrec = mrecAd else {
            showAlert(title: "Error", message: "Failed to create MREC ad.")
            return
        }
        
        mrec.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mrec)
        NSLayoutConstraint.activate([
            mrec.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mrec.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            mrec.widthAnchor.constraint(equalToConstant: 300),
            mrec.heightAnchor.constraint(equalToConstant: 250)
        ])
        
        isLoading = true
        updateStatusUI(state: .loading)
        print("📱 Loading MREC ad...")
        mrec.load()
    }
    
    private func resetAdState() {
        mrecAd?.removeFromSuperview()
        mrecAd = nil
        isLoading = false
        updateStatusUI(state: .noAd)
    }
}

extension MRECViewController: CLXBannerDelegate {
    func didLoad(with ad: CLXAd) {
        print("✅ MREC ad loaded successfully")
        isLoading = false
        updateStatusUI(state: .ready)
    }
    
    func failToLoad(with ad: CLXAd, error: Error) {
        print("❌ Failed to load MREC Ad: \(error)")
        isLoading = false
        updateStatusUI(state: .noAd)
        mrecAd = nil
        
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(title: "Ad Load Error", message: error.localizedDescription)
        }
    }
    
    func didShow(with ad: CLXAd) {
        print("👀 MREC ad did show")
    }
    
    func failToShow(with ad: CLXAd, error: Error) {
        print("❌ MREC ad fail to show: \(error)")
        mrecAd = nil
        
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(title: "Ad Show Error", message: error.localizedDescription)
        }
    }
    
    func didHide(with ad: CLXAd) {
        print("🔚 MREC ad did hide")
        mrecAd = nil
    }
    
    func didClick(with ad: CLXAd) {
        print("👆 MREC ad did click")
    }
    
    func impression(on ad: CLXAd) {
        print("👁️ MREC ad impression recorded")
    }
    
    func closedByUserAction(with ad: CLXAd) {
        print("✋ MREC ad closed by user action")
        mrecAd = nil
    }
} 
