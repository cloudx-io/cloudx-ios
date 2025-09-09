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
    let cloudX = CloudXCore.shared
    var isLoading = false
    
    var appKey: String? {
        return nil // Force subclasses to override
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
        updateStatusUI(state: .noAd)
    }
    
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

        UserDefaults.standard.set("https://pro-dev.cloudx.io/sdk", forKey: "CloudXInitURL")

        return await withCheckedContinuation { continuation in
            // Use a test user ID for demo purposes
            let testUserID = "test-user-123"
            cloudX.initSDK(withAppKey: appKey, hashedUserID: testUserID) { success, error in
                if success {
                    print("✅ SDK Initialized: \(success)")
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
} 