import UIKit
import CloudXCore

extension Notification.Name {
    static let sdkInitialized = Notification.Name("cloudXSDKInitialized")
}

class InitViewController: BaseAdViewController {
    // Uses appKey from BaseAdViewController (CLXDemoConfigManager)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCenteredButton(title: "Initialize SDK", action: #selector(initializeSDK))
        updateStatusUI(state: AdState.noAd)
    }
    
    private func updateStatusUI(isInitialized: Bool) {
        if isInitialized {
            statusLabel.text = "SDK READY"
            statusLabel.textColor = .systemGreen
            statusIndicator.backgroundColor = .systemGreen
        } else {
            statusLabel.text = "SDK not initialized"
            statusLabel.textColor = .systemRed
            statusIndicator.backgroundColor = .systemRed
        }
    }
    
    @objc private func initializeSDK() {
        guard let key = appKey, !key.isEmpty else {
            showAlert(title: "Error", message: "API key is missing.")
            return
        }
        
        UserDefaults.standard.set("https://pro-dev.cloudx.io/sdk", forKey: "CloudXInitURL")
        
        Task {
            do {
                await super.initializeSDK()
                DispatchQueue.main.async {
                    self.updateStatusUI(isInitialized: true)
                }
            } catch {
                print("❌ SDK Init Failed: \(error)")
                showAlert(title: "SDK Init Failed", message: error.localizedDescription)
                DispatchQueue.main.async {
                    self.updateStatusUI(isInitialized: false)
                }
            }
        }
    }
} 
