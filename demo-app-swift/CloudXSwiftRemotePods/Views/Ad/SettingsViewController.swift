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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Settings"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 5 // SDK, Placement, Privacy, Logging, QA Tools
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2 // SDK Settings
        case 1: return 4 // Placement Settings
        case 2: return 5 // Privacy: Consent, US Privacy, GPP String, GPP SID, User Targeting
        case 3: return 4 // Logging: Enable, Emojis, Timestamps, Level
        case 4: return 1 // QA Tools: Print Bid Response
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "SDK Settings"
        case 1: return "Placement Settings"
        case 2: return "Privacy"
        case 3: return "Logging Controls 🪵"
        case 4: return "🔍 QA Tools"
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 3 {
            return "V=Verbose (all logs), D=Debug (dev logs), I=Info (key events), W=Warn (issues), E=Error (failures only). Toggle emojis to test plain text mode for log aggregation systems."
        }
        if section == 4 {
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
            if indexPath.row == 0 {
                cell.textLabel?.text = "App Key"
                textField.text = settings.appKey
            } else {
                cell.textLabel?.text = "Init URL"
                textField.text = settings.SDKinitURL
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
        case 2: // Privacy
            switch indexPath.row {
            case 0: 
                cell.textLabel?.text = "Consent String"
                textField.text = settings.consentString
            case 1: 
                cell.textLabel?.text = "US Privacy String"
                textField.text = settings.usPrivacyString
            case 2:
                cell.textLabel?.text = "GPP String"
                textField.text = settings.gppString
                textField.placeholder = "IABGPP_HDR_GppString"
            case 3:
                cell.textLabel?.text = "GPP SID"
                textField.text = settings.gppSid
                textField.placeholder = "e.g., 2_7_8"
            case 4:
                cell.textLabel?.text = "User Targeting"
                let toggle = UISwitch()
                toggle.isOn = settings.userTargeting
                toggle.addTarget(self, action: #selector(userTargetingSwitchChanged(_:)), for: .valueChanged)
                cell.accessoryView = toggle
                textField.removeFromSuperview()
            default: break
            }
        case 3: // Logging
            textField.removeFromSuperview() // We'll use switches for all logging controls
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Logging Enabled"
                let toggle = UISwitch()
                // Read from UserDefaults, default is YES (enabled)
                toggle.isOn = !UserDefaults.standard.bool(forKey: "LoggingDisabled")
                toggle.tag = 300
                toggle.addTarget(self, action: #selector(loggingToggleChanged(_:)), for: .valueChanged)
                cell.accessoryView = toggle
            case 1:
                cell.textLabel?.text = "Emojis Enabled"
                let toggle = UISwitch()
                // Default is YES, store override in UserDefaults
                toggle.isOn = !UserDefaults.standard.bool(forKey: "LoggingEmojisDisabled")
                toggle.tag = 301
                toggle.addTarget(self, action: #selector(loggingToggleChanged(_:)), for: .valueChanged)
                cell.accessoryView = toggle
            case 2:
                cell.textLabel?.text = "Timestamps Enabled"
                let toggle = UISwitch()
                // Default is NO, store override in UserDefaults
                toggle.isOn = UserDefaults.standard.bool(forKey: "LoggingTimestampsEnabled")
                toggle.tag = 302
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
        case 4: // QA Tools
            textField.removeFromSuperview()
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Print Full Bid Response"
                let toggle = UISwitch()
                toggle.isOn = settings.printBidResponse
                toggle.tag = 400
                toggle.addTarget(self, action: #selector(printBidResponseToggleChanged(_:)), for: .valueChanged)
                cell.accessoryView = toggle
            default: break
            }
        default: break
        }
        return cell
    }
    
    @objc private func loggingToggleChanged(_ sender: UISwitch) {
        if sender.tag == 300 {
            // Logging Enabled/Disabled (using CLXLogLevelNone to disable)
            CloudXCore.setMinLogLevel(sender.isOn ? .verbose : .none)
            UserDefaults.standard.set(!sender.isOn, forKey: "LoggingDisabled")
            UserDefaults.standard.synchronize()
            print("🪵 Logging \(sender.isOn ? "ENABLED" : "DISABLED")")
        } else if sender.tag == 301 {
            // Emojis Enabled/Disabled
            CloudXCore.setLoggingEmojisEnabled(sender.isOn)
            UserDefaults.standard.set(!sender.isOn, forKey: "LoggingEmojisDisabled")
            UserDefaults.standard.synchronize()
            print("🪵 Emojis \(sender.isOn ? "ENABLED" : "DISABLED")")
        } else if sender.tag == 302 {
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
    
    @objc private func userTargetingSwitchChanged(_ sender: UISwitch) {
        settings.userTargeting = sender.isOn
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
        else if tag == 10 { settings.bannerPlacement = textField.text ?? "" }
        else if tag == 11 { settings.mrecPlacement = textField.text ?? "" }
        else if tag == 12 { settings.interstitialPlacement = textField.text ?? "" }
        else if tag == 13 { settings.rewardedPlacement = textField.text ?? "" }
        else if tag == 20 { settings.consentString = textField.text ?? "" }
        else if tag == 21 { settings.usPrivacyString = textField.text ?? "" }
        else if tag == 22 { 
            settings.gppString = textField.text ?? ""
            // Also write to IAB standard UserDefaults key
            if let gppString = textField.text, !gppString.isEmpty {
                UserDefaults.standard.set(gppString, forKey: "IABGPP_HDR_GppString")
            } else {
                UserDefaults.standard.removeObject(forKey: "IABGPP_HDR_GppString")
            }
            UserDefaults.standard.synchronize()
            print("🔐 GPP String set: \(textField.text ?? "(cleared)")")
        }
        else if tag == 23 { 
            settings.gppSid = textField.text ?? ""
            // Also write to IAB standard UserDefaults key
            if let gppSid = textField.text, !gppSid.isEmpty {
                UserDefaults.standard.set(gppSid, forKey: "IABGPP_GppSID")
            } else {
                UserDefaults.standard.removeObject(forKey: "IABGPP_GppSID")
            }
            UserDefaults.standard.synchronize()
            print("🔐 GPP SID set: \(textField.text ?? "(cleared)")")
        }
    }
}