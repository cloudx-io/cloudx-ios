import UIKit
import CloudXCore

class InitInternalViewController: BaseAdViewController {
    
    private var isSDKInitialized: Bool = false
    private var initButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Swift Demo"
        
        setupInitButton()
        
        // SDK initialization state tracked internally
        isSDKInitialized = false
        updateStatusUI(state: .noAd)
    }
    
    // Override to prevent show logs button from appearing in InitInternalViewController
    override func setupShowLogsButton() {
        // Do nothing - no show logs button for InitInternalViewController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupInitButton() {
        // Create init button
        initButton = UIButton(type: .system)
        initButton.setTitle("Init SDK", for: .normal)
        initButton.addTarget(self, action: #selector(initializeSDK), for: .touchUpInside)
        
        // Style the button
        initButton.backgroundColor = .systemBlue
        initButton.tintColor = .white
        initButton.layer.cornerRadius = 8
        initButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        initButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(initButton)
        
        // Add constraints
        NSLayoutConstraint.activate([
            initButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            initButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            initButton.widthAnchor.constraint(equalToConstant: 200),
            initButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func initializeSDK() {
        if isSDKInitialized {
            showAlert(title: "SDK Already Initialized", message: "The SDK is already initialized.")
            return
        }
        
        updateStatusUI(state: .loading)
        initButton.isEnabled = false
        
        let config = CLXDemoConfigManager.sharedManager.currentConfig
        
        DemoAppLogger.sharedInstance.logMessage("Initializing SDK")
        
        // Set hashed user ID before initialization if provided
        if !config.hashedUserId.isEmpty {
            CloudXCore.shared.setHashedUserID(config.hashedUserId)
        }
        
        // Use standard CloudXCore initialization
        CloudXCore.shared.initializeSDK(appKey: config.appKey) { [weak self] success, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if success {
                    DemoAppLogger.sharedInstance.logMessage("✅ SDK initialized successfully")
                    self.isSDKInitialized = true
                    self.updateStatusUI(state: .ready)
                    NotificationCenter.default.post(name: .sdkInitialized, object: nil)
                } else {
                    let errorMessage = error?.localizedDescription ?? "Unknown error occurred"
                    self.showAlert(title: "SDK Init Failed", message: errorMessage)
                    self.updateStatusUI(state: .noAd)
                    self.initButton.isEnabled = true
                    DemoAppLogger.sharedInstance.logMessage("❌ SDK init failed: \(errorMessage)")
                }
            }
        }
    }
}
