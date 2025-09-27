import UIKit
import CloudXCore

extension Notification.Name {
    static let sdkInitialized = Notification.Name("cloudXSDKInitialized")
}

class InitViewController: BaseAdViewController {
    
    private var isSDKInitialized: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Swift Demo"
        setupCenteredButton(title: "Initialize SDK", action: #selector(initializeSDK))
        
        // Check if SDK is already initialized
        isSDKInitialized = CloudXCore.shared.isInitialised
        updateStatusUI(state: isSDKInitialized ? .ready : .noAd)
    }
    
    // Override to prevent show logs button from appearing in InitViewController
    override func setupShowLogsButton() {
        // Do nothing - no show logs button for InitViewController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        // Update UI if SDK is already initialized
        if isSDKInitialized {
            updateStatusUI(state: .ready)
        }
    }
    
    // Override to provide SDK-specific status messages instead of ad-related ones
    override func updateStatusUI(state: AdState) {
        DispatchQueue.main.async {
            let text: String
            let color: UIColor
            
            switch state {
            case .noAd:
                text = "SDK Not Initialized"
                color = .systemRed
            case .loading:
                text = "SDK Initializing..."
                color = .systemYellow
            case .ready:
                text = "SDK Initialized"
                color = .systemGreen
            }
            
            self.statusLabel.text = text
            self.statusLabel.textColor = color
            self.statusIndicator.backgroundColor = color
        }
    }
    
    @objc private func initializeSDK() {
        if isSDKInitialized {
            showAlert(title: "SDK Already Initialized", message: "The SDK is already initialized.")
            return
        }
        
        updateStatusUI(state: .loading)
        
        let config = CLXDemoConfigManager.sharedManager.currentConfig
        
        CloudXCore.shared.initSDK(withAppKey: config.appKey, hashedUserID: config.hashedUserId) { [weak self] success, error in
            guard let self = self else { return }
            
            if success {
                DemoAppLogger.sharedInstance.logMessage("SDK initialized successfully")
                self.isSDKInitialized = true
                self.updateStatusUI(state: .ready)
                NotificationCenter.default.post(name: .sdkInitialized, object: nil)
            } else {
                let errorMessage = error?.localizedDescription ?? "Unknown error occurred"
                self.showAlert(title: "SDK Init Failed", message: errorMessage)
                self.updateStatusUI(state: .noAd)
            }
        }
    }
} 
