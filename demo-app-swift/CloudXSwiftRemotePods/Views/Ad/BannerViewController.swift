import UIKit
import CloudXCore

class BannerViewController: BaseAdViewController {
    private var bannerAd: CLXBannerAdView?
    private var isSDKInitialized = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCenteredButton(title: "Show Banner", action: #selector(showBannerAd))
        setupNotifications()
        
        // Check if SDK is already initialized
        isSDKInitialized = cloudX.isInitialised
        updateStatusUI(state: .noAd)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create ad if SDK is already initialized
        if isSDKInitialized && bannerAd == nil {
            createBannerAd()
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
        createBannerAd()
    }
    
    private func createBannerAd() {
        guard bannerAd == nil else { return }
        print("📱 Creating new banner ad instance...")
        
        // Create banner ad with verified placement
        bannerAd = cloudX.createBanner(withPlacement: "banner11239747913482", 
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
    
    func closedByUserAction(with ad: CLXAd) {
        print("✋ Banner closed by user action")
        bannerAd = nil
    }
} 
