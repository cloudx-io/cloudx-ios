//
//  SettingsViewController.swift
//  CloudXSwiftRemotePods
//
//  Created by Xenoss on 15.09.2025.
//

import UIKit

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
        return 3 // SDK, Placement, Privacy
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2 // SDK Settings
        case 1: return 6 // Placement Settings
        case 2: return 3 // Privacy
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "SDK Settings"
        case 1: return "Placement Settings"
        case 2: return "Privacy"
        default: return nil
        }
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
            case 4: 
                cell.textLabel?.text = "Native Small"
                textField.text = settings.nativeSmallPlacement
            case 5: 
                cell.textLabel?.text = "Native Medium"
                textField.text = settings.nativeMediumPlacement
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
                cell.textLabel?.text = "User Targeting"
                let toggle = UISwitch()
                toggle.isOn = settings.userTargeting
                toggle.addTarget(self, action: #selector(userTargetingSwitchChanged(_:)), for: .valueChanged)
                cell.accessoryView = toggle
                textField.removeFromSuperview()
            default: break
            }
        default: break
        }
        return cell
    }
    
    @objc private func userTargetingSwitchChanged(_ sender: UISwitch) {
        settings.userTargeting = sender.isOn
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let tag = textField.tag
        if tag == 0 { settings.appKey = textField.text ?? "" }
        else if tag == 1 { settings.SDKinitURL = textField.text ?? "" }
        else if tag == 10 { settings.bannerPlacement = textField.text ?? "" }
        else if tag == 11 { settings.mrecPlacement = textField.text ?? "" }
        else if tag == 12 { settings.interstitialPlacement = textField.text ?? "" }
        else if tag == 13 { settings.rewardedPlacement = textField.text ?? "" }
        else if tag == 14 { settings.nativeSmallPlacement = textField.text ?? "" }
        else if tag == 15 { settings.nativeMediumPlacement = textField.text ?? "" }
        else if tag == 20 { settings.consentString = textField.text ?? "" }
        else if tag == 21 { settings.usPrivacyString = textField.text ?? "" }
    }
}