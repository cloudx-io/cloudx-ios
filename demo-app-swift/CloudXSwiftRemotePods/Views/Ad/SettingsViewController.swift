//
//  SettingsViewController.swift
//  CloudXSwiftRemotePods
//
//  Created by Xenoss on 15.09.2025.
//

import UIKit
import CloudXCore

class CLXTextField: UITextField {
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(copy(_:)) ||
           action == #selector(paste(_:)) ||
           action == #selector(cut(_:)) {
            return true // explicitly allow
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    override func copy(_ sender: Any?) {
        let pb = UIPasteboard.general
        pb.string = self.text
    }
    
    override func paste(_ sender: Any?) {
        let pb = UIPasteboard.general
        self.text = pb.string
    }
    
    override func cut(_ sender: Any?) {
        let pb = UIPasteboard.general
        pb.string = self.text
        self.text = ""
    }
}

class SettingsViewController: UITableViewController, UITextFieldDelegate {
    
    private let settings = UserDefaultsSettings.shared
    private weak var hashedUserIdTextField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Settings"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4 // SDK, Placement, Logging, QA Tools
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 3 // SDK Settings: App Key, Init URL, Hashed User ID
        case 1: return 4 // Placement Settings
        case 2: return 4 // Logging: Enable, Emojis, Timestamps, Level
        case 3: return 1 // QA Tools: Print Bid Response
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "SDK Settings"
        case 1: return "Placement Settings"
        case 2: return "Logging Controls 🪵"
        case 3: return "🔍 QA Tools"
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 2 {
            return "V=Verbose (all logs), D=Debug (dev logs), I=Info (key events), W=Warn (issues), E=Error (failures only). Toggle emojis to test plain text mode for log aggregation systems."
        }
        if section == 3 {
            return "When enabled, the full bid response JSON from the server is printed to the Xcode console. This is for QA/internal testing only."
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let textField = CLXTextField(frame: CGRect(x: 150, y: 7, width: cell.contentView.bounds.size.width - 160, height: 30))
        textField.delegate = self
        textField.tag = indexPath.section * 10 + indexPath.row
        textField.borderStyle = .roundedRect
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentView.addSubview(textField)

        switch indexPath.section {
        case 0: // SDK
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "App Key"
                textField.text = settings.appKey
            case 1:
                cell.textLabel?.text = "Init URL"
                textField.text = settings.SDKinitURL
            case 2:
                cell.textLabel?.text = "Hashed User ID"
                textField.text = settings.hashedUserId
                
                // Store reference to this text field
                hashedUserIdTextField = textField
                
                // Add a small "Apply" button to the right of the text field
                let applyButton = UIButton(type: .system)
                applyButton.setTitle("Apply", for: .normal)
                applyButton.frame = CGRect(x: 0, y: 0, width: 55, height: 30)
                applyButton.addTarget(self, action: #selector(applyHashedUserId(_:)), for: .touchUpInside)
                cell.accessoryView = applyButton
                
                // Adjust text field frame to make room for the button
                textField.frame = CGRect(x: 150, y: 7, width: cell.contentView.bounds.size.width - 220, height: 30)
            default: break
            }
        case 1: // Placement
            switch indexPath.row {
            case 0: 
                cell.textLabel?.text = "Banner"
                textField.text = settings.bannerPlacement
            case 1: 
                cell.textLabel?.text = "MREC"
                textField.text = settings.mrecPlacement
            case 2: 
                cell.textLabel?.text = "Interstitial"
                textField.text = settings.interstitialPlacement
            case 3:
                cell.textLabel?.text = "Rewarded"
                textField.text = settings.rewardedPlacement
            default: break
            }
        case 2: // Logging
            textField.removeFromSuperview() // We'll use switches for all logging controls
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Logging Enabled"
                let toggle = UISwitch()
                // Read from UserDefaults, default is YES (enabled)
                toggle.isOn = !UserDefaults.standard.bool(forKey: "LoggingDisabled")
                toggle.tag = 200
                toggle.addTarget(self, action: #selector(loggingToggleChanged(_:)), for: .valueChanged)
                cell.accessoryView = toggle
            case 1:
                cell.textLabel?.text = "Emojis Enabled"
                let toggle = UISwitch()
                // Default is YES, store override in UserDefaults
                toggle.isOn = !UserDefaults.standard.bool(forKey: "LoggingEmojisDisabled")
                toggle.tag = 201
                toggle.addTarget(self, action: #selector(loggingToggleChanged(_:)), for: .valueChanged)
                cell.accessoryView = toggle
            case 2:
                cell.textLabel?.text = "Timestamps Enabled"
                let toggle = UISwitch()
                // Default is NO, store override in UserDefaults
                toggle.isOn = UserDefaults.standard.bool(forKey: "LoggingTimestampsEnabled")
                toggle.tag = 202
                toggle.addTarget(self, action: #selector(loggingToggleChanged(_:)), for: .valueChanged)
                cell.accessoryView = toggle
            case 3:
                cell.textLabel?.text = "Log Level"
                let levelControl = UISegmentedControl(items: ["V", "D", "I", "W", "E"])
                let currentLevel = UserDefaults.standard.integer(forKey: "LoggingLevel")
                levelControl.selectedSegmentIndex = currentLevel > 0 ? currentLevel : 2 // Default to Info
                levelControl.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
                levelControl.addTarget(self, action: #selector(logLevelChanged(_:)), for: .valueChanged)
                cell.accessoryView = levelControl
            default: break
            }
        case 3: // QA Tools
            textField.removeFromSuperview()
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Print Full Bid Response"
                let toggle = UISwitch()
                toggle.isOn = settings.printBidResponse
                toggle.tag = 300
                toggle.addTarget(self, action: #selector(printBidResponseToggleChanged(_:)), for: .valueChanged)
                cell.accessoryView = toggle
            default: break
            }
        default: break
        }
        return cell
    }
    
    @objc private func loggingToggleChanged(_ sender: UISwitch) {
        if sender.tag == 200 {
            // Logging Enabled/Disabled (using CLXLogLevelNone to disable)
            CloudXCore.setMinLogLevel(sender.isOn ? .verbose : .none)
            UserDefaults.standard.set(!sender.isOn, forKey: "LoggingDisabled")
            UserDefaults.standard.synchronize()
            print("🪵 Logging \(sender.isOn ? "ENABLED" : "DISABLED")")
        } else if sender.tag == 201 {
            // Emojis Enabled/Disabled
            CloudXCore.setLoggingEmojisEnabled(sender.isOn)
            UserDefaults.standard.set(!sender.isOn, forKey: "LoggingEmojisDisabled")
            UserDefaults.standard.synchronize()
            print("🪵 Emojis \(sender.isOn ? "ENABLED" : "DISABLED")")
        } else if sender.tag == 202 {
            // Timestamps Enabled/Disabled
            CloudXCore.setLoggingTimestampsEnabled(sender.isOn)
            UserDefaults.standard.set(sender.isOn, forKey: "LoggingTimestampsEnabled")
            UserDefaults.standard.synchronize()
            print("🪵 Timestamps \(sender.isOn ? "ENABLED" : "DISABLED")")
        }
    }
    
    @objc private func logLevelChanged(_ sender: UISegmentedControl) {
        // 0=Verbose, 1=Debug, 2=Info, 3=Warn, 4=Error
        CloudXCore.setMinLogLevel(CLXLogLevel(rawValue: sender.selectedSegmentIndex) ?? .info)
        UserDefaults.standard.set(sender.selectedSegmentIndex, forKey: "LoggingLevel")
        let levelNames = ["VERBOSE", "DEBUG", "INFO", "WARN", "ERROR"]
        print("🪵 Log level set to: \(levelNames[sender.selectedSegmentIndex])")
    }
    
    @objc private func applyHashedUserId(_ sender: UIButton) {
        // Get the current text from the stored text field reference
        let hashedUserId = hashedUserIdTextField?.text
        
        // Save it to settings and apply to SDK (allow empty/nil to clear)
        settings.hashedUserId = hashedUserId
        CloudXCore.shared.setHashedUserID(hashedUserId ?? "")
        
        // Dismiss keyboard if it's showing
        hashedUserIdTextField?.resignFirstResponder()
        
        // Show confirmation alert
        let message: String
        if let hashedUserId = hashedUserId, !hashedUserId.isEmpty {
            message = "Hashed User ID updated to:\n\(hashedUserId)"
        } else {
            message = "Hashed User ID cleared"
        }
        
        let alert = UIAlertController(title: "Applied", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - QA Tools
    
    @objc private func printBidResponseToggleChanged(_ sender: UISwitch) {
        settings.printBidResponse = sender.isOn
        
        // Enable swizzling when turned on
        if sender.isOn {
            CLXBidResponseSwizzler.enableSwizzling()
        }
        
        print("🔍 Print Full Bid Response \(sender.isOn ? "ENABLED" : "DISABLED")")
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let tag = textField.tag
        if tag == 0 { settings.appKey = textField.text ?? "" }
        else if tag == 1 { settings.SDKinitURL = textField.text ?? "" }
        else if tag == 2 { settings.hashedUserId = textField.text }
        else if tag == 10 { settings.bannerPlacement = textField.text ?? "" }
        else if tag == 11 { settings.mrecPlacement = textField.text ?? "" }
        else if tag == 12 { settings.interstitialPlacement = textField.text ?? "" }
        else if tag == 13 { settings.rewardedPlacement = textField.text ?? "" }
    }
}