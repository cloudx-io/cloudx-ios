import UIKit
import CloudXCore

protocol AdStateManaging {
    var isLoading: Bool { get set }
    func updateStatusUI(state: AdState)
}

enum AdState {
    case noAd
    case loading
    case ready
    
    var text: String {
        switch self {
        case .noAd: return "No Ad Loaded"
        case .loading: return "Loading Ad..."
        case .ready: return "Ad Ready"
        }
    }
    
    var color: UIColor {
        switch self {
        case .noAd: return .systemRed
        case .loading: return .systemYellow
        case .ready: return .systemGreen
        }
    }
}

class BaseAdViewController: UIViewController, AdStateManaging {
    var cloudX: CloudXCore { CloudXCore.shared }
    var isLoading = false
    
    var appKey: String? {
        return CLXDemoConfigManager.sharedManager.currentConfig.appKey
    }
    
    let statusLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let statusIndicator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 6
        view.clipsToBounds = true
        return view
    }()
    
    let statusStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupStatusUI()
        setupShowLogsButton()
        updateStatusUI(state: .noAd)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Clear logs when switching between different ad formats (tabs)
        let currentAdFormat = String(describing: type(of: self))
        
        if let lastFormat = BaseAdViewController.lastAdFormat, lastFormat != currentAdFormat {
            // Switching between different ad formats - clear logs for clean slate
            DemoAppLogger.sharedInstance.clearLogs()
            DemoAppLogger.sharedInstance.logMessage("[\(currentAdFormat)] Switched from \(lastFormat) - logs cleared")
        }
        // No log for same format - keep it clean
        
        // Remember current ad format for next time (session only)
        BaseAdViewController.lastAdFormat = currentAdFormat
    }
    
    // Static variable to track last ad format across all instances
    private static var lastAdFormat: String?
    
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    func initializeSDK() async {
        guard let appKey = appKey, !appKey.isEmpty else {
            showAlert(title: "Error", message: "API key is missing.")
            return
        }

        let config = CLXDemoConfigManager.sharedManager.currentConfig
        UserDefaults.standard.set(config.baseURL, forKey: "CloudXInitURL")
        
        // Set hashed user ID before initialization if provided
        if !config.hashedUserId.isEmpty {
            cloudX.setHashedUserID(config.hashedUserId)
        }

        // Determine test mode based on build configuration
        #if targetEnvironment(simulator)
        let testMode = true
        #elseif DEBUG
        let testMode = true
        #else
        let testMode = false
        #endif
        
        return await withCheckedContinuation { continuation in
            cloudX.initializeSDK(appKey: appKey, testMode: testMode) { success, error in
                if success {
                    print("✅ SDK Initialized (testMode: \(testMode))")
                    NotificationCenter.default.post(name: .sdkInitialized, object: nil)
                } else {
                    print("❌ SDK Init Failed: \(error?.localizedDescription ?? "Unknown error")")
                    self.showAlert(title: "SDK Init Failed", message: error?.localizedDescription ?? "Unknown error")
                }
                continuation.resume()
            }
        }
    }
    
    func updateStatusUI(state: AdState) {
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.text = state.text
            self?.statusLabel.textColor = state.color
            self?.statusIndicator.backgroundColor = state.color
        }
    }
    
    private func setupStatusUI() {
        // Setup status indicator stack
        statusStack.addArrangedSubview(statusIndicator)
        statusStack.addArrangedSubview(statusLabel)
        
        view.addSubview(statusStack)
        
        NSLayoutConstraint.activate([
            statusStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            statusIndicator.widthAnchor.constraint(equalToConstant: 12),
            statusIndicator.heightAnchor.constraint(equalToConstant: 12)
        ])
    }
    
    func setupCenteredButton(title: String, action: Selector) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        button.addTarget(self, action: action, for: .touchUpInside)
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 200),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private lazy var sdkDebuggerButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.layer.cornerRadius = 6
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(toggleSDKDebugger), for: .touchUpInside)
        return button
    }()
    
    func setupShowLogsButton() {
        // App Logs button (shows demo app logs)
        let showLogsButton = UIButton(type: .system)
        showLogsButton.setTitle("App Logs", for: .normal)
        showLogsButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        showLogsButton.backgroundColor = UIColor.systemOrange
        showLogsButton.setTitleColor(UIColor.white, for: .normal)
        showLogsButton.layer.cornerRadius = 6
        showLogsButton.translatesAutoresizingMaskIntoConstraints = false
        
        showLogsButton.addTarget(self, action: #selector(showLogsModal), for: .touchUpInside)
        
        view.addSubview(showLogsButton)
        view.addSubview(sdkDebuggerButton)
        
        updateSDKDebuggerButtonTitle()
        
        NSLayoutConstraint.activate([
            showLogsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            showLogsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            showLogsButton.widthAnchor.constraint(equalToConstant: 100),
            showLogsButton.heightAnchor.constraint(equalToConstant: 32),
            
            sdkDebuggerButton.topAnchor.constraint(equalTo: showLogsButton.bottomAnchor, constant: 8),
            sdkDebuggerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sdkDebuggerButton.widthAnchor.constraint(equalToConstant: 100),
            sdkDebuggerButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    private func updateSDKDebuggerButtonTitle() {
        let isEnabled = CloudXCore.isVisualDebuggingEnabled()
        if isEnabled {
            sdkDebuggerButton.setTitle("Debugger ✓", for: .normal)
            sdkDebuggerButton.backgroundColor = .systemGreen
        } else {
            sdkDebuggerButton.setTitle("Debugger", for: .normal)
            sdkDebuggerButton.backgroundColor = .systemPurple
        }
        sdkDebuggerButton.setTitleColor(.white, for: .normal)
    }
    
    @objc private func toggleSDKDebugger() {
        let currentState = CloudXCore.isVisualDebuggingEnabled()
        CloudXCore.setVisualDebuggingEnabled(!currentState)
        updateSDKDebuggerButtonTitle()
    }
    
    @objc private func showLogsModal() {
        let logsModal = LogsModalViewController(title: "Demo App Logs")
        present(logsModal, animated: true)
    }
} 
