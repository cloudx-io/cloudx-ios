import UIKit
import CloudXCore

class InitInternalViewController: BaseAdViewController {
    
    private var isSDKInitialized: Bool = false
    private var buttonStackView: UIStackView!
    private var devButton: UIButton!
    private var stagingButton: UIButton!
    private var prodButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Internal Init"
        setupEnvironmentButtons()
        
        // Check if SDK is already initialized
        isSDKInitialized = CloudXCore.shared.isInitialised
        updateStatusUIWithCurrentEnvironment()
    }
    
    // Override to prevent show logs button from appearing in InitInternalViewController
    override func setupShowLogsButton() {
        // Do nothing - no show logs button for InitInternalViewController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        // Update UI if SDK is already initialized
        if isSDKInitialized {
            updateStatusUIWithCurrentEnvironment()
        }
    }
    
    private func setupEnvironmentButtons() {
        // Create buttons
        devButton = createButton(withTitle: "Init Dev", 
                                action: #selector(initializeWithDevEnvironment),
                                environment: .dev)
        
        stagingButton = createButton(withTitle: "Init Staging", 
                                   action: #selector(initializeWithStagingEnvironment),
                                   environment: .staging)
        
        prodButton = createButton(withTitle: "Init Production", 
                                action: #selector(initializeWithProductionEnvironment),
                                environment: .production)
        
        // Create stack view for buttons - Staging at top, Dev in middle, Production at bottom
        buttonStackView = UIStackView(arrangedSubviews: [stagingButton, devButton, prodButton])
        buttonStackView.axis = .vertical
        buttonStackView.spacing = 16
        buttonStackView.alignment = .fill
        buttonStackView.distribution = .fillEqually
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(buttonStackView)
        
        // Add constraints - match InitViewController button dimensions (200px wide, 44px tall)
        NSLayoutConstraint.activate([
            buttonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stagingButton.widthAnchor.constraint(equalToConstant: 200),
            stagingButton.heightAnchor.constraint(equalToConstant: 44),
            devButton.widthAnchor.constraint(equalToConstant: 200),
            devButton.heightAnchor.constraint(equalToConstant: 44),
            prodButton.widthAnchor.constraint(equalToConstant: 200),
            prodButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func createButton(withTitle title: String, action: Selector, environment: CLXDemoEnvironment) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        
        // Style the button
        button.backgroundColor = color(for: environment)
        button.tintColor = .white
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        
        return button
    }
    
    private func color(for environment: CLXDemoEnvironment) -> UIColor {
        switch environment {
        case .dev:
            return .systemBlue
        case .staging:
            // Light blue - not too bright or light
            return UIColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 1.0)
        case .production:
            // Green - not too bright or light
            return UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
        }
    }
    
    // Override to provide environment-specific status messages
    private func updateStatusUIWithCurrentEnvironment() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let configManager = CLXDemoConfigManager.sharedManager
            let environmentName = configManager.environmentName(configManager.currentEnvironment)
            
            let text: String
            let color: UIColor
            
            if self.isSDKInitialized {
                text = "SDK Initialized (\(environmentName))"
                color = .systemGreen
            } else {
                text = "SDK Not Initialized (\(environmentName))"
                color = .systemRed
            }
            
            self.statusLabel.text = text
            self.statusLabel.textColor = color
            self.statusIndicator.backgroundColor = color
        }
    }
    
    override func updateStatusUI(state: AdState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let configManager = CLXDemoConfigManager.sharedManager
            let environmentName = configManager.environmentName(configManager.currentEnvironment)
            
            let text: String
            let color: UIColor
            
            switch state {
            case .noAd:
                text = "SDK Not Initialized (\(environmentName))"
                color = .systemRed
            case .loading:
                text = "SDK Initializing (\(environmentName))..."
                color = .systemYellow
            case .ready:
                text = "SDK Initialized (\(environmentName))"
                color = .systemGreen
            }
            
            self.statusLabel.text = text
            self.statusLabel.textColor = color
            self.statusIndicator.backgroundColor = color
        }
    }
    
    @objc private func initializeWithDevEnvironment() {
        initializeWithEnvironment(.dev)
    }
    
    @objc private func initializeWithStagingEnvironment() {
        initializeWithEnvironment(.staging)
    }
    
    @objc private func initializeWithProductionEnvironment() {
        initializeWithEnvironment(.production)
    }
    
    private func initializeWithEnvironment(_ environment: CLXDemoEnvironment) {
        if isSDKInitialized {
            let configManager = CLXDemoConfigManager.sharedManager
            let environmentName = configManager.environmentName(environment)
            showAlert(title: "SDK Already Initialized", 
                     message: "The SDK is already initialized. Current environment: \(configManager.environmentName(configManager.currentEnvironment))")
            return
        }
        
        // Set the environment in config manager
        let configManager = CLXDemoConfigManager.sharedManager
        configManager.setEnvironment(environment)
        
        let config = configManager.currentConfig
        let environmentName = configManager.environmentName(environment)
        
        updateStatusUI(state: .loading)
        
        // Clear DI container to force fresh services with new environment
        CLXDIContainer.shared().reset()
        
        // Set environment in our centralized config FIRST (before any SDK calls)
        let environmentKey: String
        switch environment {
        case .dev:
            environmentKey = "dev"
        case .staging:
            environmentKey = "staging"
        case .production:
            // Production doesn't need environment override - it's the default for non-DEBUG
            environmentKey = "production"
        }
        
        // Set the debug environment in our centralized config
        if environment != .production {
            CLXURLProvider.setEnvironment(environmentKey)
        }
        
        // Also set the old key for backward compatibility with demo app config
        UserDefaults.standard.set(environmentKey, forKey: "CLXDemoEnvironment")
        UserDefaults.standard.synchronize()
        
        DemoAppLogger.sharedInstance.logMessage("Initializing SDK with \(environmentName) environment")
        
        // Use standard CloudXCore initialization which will now use our environment override
        CloudXCore.shared.initSDK(withAppKey: config.appKey, 
                                 hashedUserID: config.hashedUserId) { [weak self] success, error in
            // Clear old environment override after initialization (success or failure)
            UserDefaults.standard.removeObject(forKey: "CLXDemoEnvironment")
            UserDefaults.standard.synchronize()
            
            // Note: We keep the CLXDebugEnvironment setting in our centralized config
            // so it persists for subsequent SDK operations
            
            if success {
                DemoAppLogger.sharedInstance.logMessage("✅ SDK initialized successfully with \(environmentName) environment")
                self?.isSDKInitialized = true
                self?.updateStatusUI(state: .ready)
                NotificationCenter.default.post(name: NSNotification.Name("cloudXSDKInitialized"), object: nil)
            } else {
                let errorMessage = error?.localizedDescription ?? "Unknown error occurred"
                DemoAppLogger.sharedInstance.logMessage("❌ SDK init failed: \(errorMessage)")
                self?.updateStatusUI(state: .noAd)
                self?.showAlert(title: "SDK Init Failed", message: errorMessage)
            }
        }
    }
}