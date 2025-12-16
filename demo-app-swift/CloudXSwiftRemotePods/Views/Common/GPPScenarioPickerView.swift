//
//  GPPScenarioPickerView.swift
//  CloudXSwiftRemotePods
//
//  Created by refactoring for SOLID principles.
//
//  PURPOSE:
//  --------
//  A self-contained, reusable component for testing GPP (Global Privacy Platform) 
//  privacy compliance scenarios. Encapsulates ALL GPP test logic, UI, and SDK 
//  integration to minimize code footprint in parent view controllers.
//
//  DESIGN PRINCIPLES:
//  ------------------
//  ✅ SOLID Principles:
//     - Single Responsibility: Only manages GPP scenario testing
//     - Open/Closed: Add scenarios by editing component, not parent VCs
//     - Liskov Substitution: Works as drop-in UIView subclass
//     - Interface Segregation: Minimal public API (one optional method)
//     - Dependency Inversion: Parent VCs depend on UIView abstraction
//
//  ✅ DRY (Don't Repeat Yourself):
//     - Scenario logic defined once, reusable across all ad type VCs
//     - No duplication of GPP test code in Banner/Interstitial/Rewarded VCs
//
//  ✅ Encapsulation:
//     - Internal state management (current scenario, UI elements)
//     - Private methods handle CloudXCore SDK privacy calls
//     - Self-contained UI creation and presentation
//
//  USAGE:
//  ------
//  Simply instantiate and add to your view hierarchy. No configuration needed!
//
//  Example:
//  ```swift
//  let picker = GPPScenarioPickerView()
//  stackView.addArrangedSubview(picker)
//  ```
//
//  That's it! The component handles:
//  - Creating label and button UI
//  - Presenting action sheet picker
//  - Applying privacy settings to CloudXCore SDK
//  - Logging scenario changes to console
//
//  FEATURES:
//  ---------
//  📋 9 Privacy Test Scenarios:
//     1. None - No privacy settings
//     2. GPP Absent - No GPP string
//     3. CCPA Consent (.QA) - User gave consent
//     4. CCPA Opt-Out (.YA) - User opted out
//     5. Non-US (Germany) - EU privacy (GDPR)
//     6. US Non-California (NY) - US-National GPP
//     7. ⭐️ ATT Denied - iOS tracking disabled (requires Settings config)
//
//  🎯 Privacy Compliance Testing:
//     - CCPA (California Consumer Privacy Act)
//     - GPP (Global Privacy Platform - US-CA, US-National, EU)
//     - ATT (App Tracking Transparency)
//     - Regional variations (US, EU, international)
//
//  🔍 Verification:
//     - Console logging shows selected scenario
//     - CloudXCore SDK automatically applies privacy rules
//     - Bid requests reflect privacy settings (lat/lon removal, etc.)
//
//  INTEGRATION WITH IAB STANDARD STORAGE:
//  ----------------------------------------
//  Writes directly to IAB standard UserDefaults keys (CloudX reads these internally):
//  - IABGPP_HDR_GppString - IAB GPP consent string
//  - IABGPP_GppSID - IAB GPP Section ID (7=US-National, 8=US-CA)
//  - IABTCF_TCString - IAB TCF consent string for GDPR
//  - IABTCF_gdprApplies - IAB flag indicating GDPR applies
//  - IABUSPrivacy_String - IAB US Privacy string for CCPA
//  
//  NOTE: Privacy setter APIs (setCCPAPrivacyString, setIsUserConsent, setIsDoNotSell)
//  were removed from CloudX SDK to align with Android. Both platforms now read privacy
//  data from IAB standard UserDefaults/SharedPreferences. Publishers should use
//  IAB CMP SDKs; this component writes to IAB keys for demo/testing purposes only.

import UIKit
import CloudXCore

/// Enumeration of available privacy test scenarios
enum GPPTestScenario: Int {
    case none = 0                       // No privacy settings
    case gppAbsent                      // No GPP string
    case ccpaConsent                    // CCPA consent (.QA)
    case ccpaOptOut                     // CCPA opt-out (.YA)
    case nonUS                          // EU/Germany (GDPR via GPP)
    case usNonCalifornia                // US non-CA (Oregon, NY, etc)
    case attDenied                      // ATT tracking disabled
    // GDPR/TCF Scenarios
    case gdprFullConsent                // EU TCF: All purposes + vendor consent
    case gdprDenied                     // EU TCF: No purposes consented
    case gdprPurpose1Denied             // EU TCF: Purpose 1 (device access) denied
    case gdprVendorDenied               // EU TCF: Purposes OK but vendor denied
}

/// A self-contained component for GPP privacy compliance testing
///
/// This component encapsulates all GPP (Global Privacy Platform) test scenario
/// logic, UI, and SDK integration. It provides a reusable, drop-in solution for
/// privacy compliance testing across different ad formats (Banner, Interstitial,
/// Rewarded, MREC).
///
/// The component automatically creates its UI (label + button), presents an
/// action sheet picker, and applies selected privacy scenarios to the CloudXCore
/// SDK without requiring any configuration or method calls from the parent.
class GPPScenarioPickerView: UIView {
    
    private var scenarioLabel: UILabel!
    private var scenarioButton: UIButton!
    private var currentScenario: GPPTestScenario = .none
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Create vertical stack
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        // Label
        scenarioLabel = UILabel()
        scenarioLabel.text = "GPP Test Scenario:"
        scenarioLabel.font = .boldSystemFont(ofSize: 14)
        scenarioLabel.textColor = .label
        stackView.addArrangedSubview(scenarioLabel)
        
        // Button
        scenarioButton = UIButton(type: .system)
        scenarioButton.setTitle("None (Tap to Change)", for: .normal)
        scenarioButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        scenarioButton.backgroundColor = .systemBlue
        scenarioButton.setTitleColor(.white, for: .normal)
        scenarioButton.titleLabel?.font = .boldSystemFont(ofSize: 15)
        scenarioButton.layer.cornerRadius = 8
        scenarioButton.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(scenarioButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scenarioButton.widthAnchor.constraint(equalToConstant: 320)
        ])
    }
    
    // MARK: - User Interaction
    
    @objc private func buttonTapped() {
        guard let viewController = findViewController() else { return }
        presentScenarioPicker(from: viewController)
    }
    
    /// Presents the scenario picker and applies the selected scenario
    ///
    /// This method is optional - the component automatically presents the picker
    /// when its button is tapped. Only call this method if you need to present
    /// the picker programmatically from external code.
    ///
    /// - Parameter viewController: The view controller to present the picker from.
    ///                             Must be a valid UIViewController in the view hierarchy.
    func presentScenarioPicker(from viewController: UIViewController) {
        let alert = UIAlertController(title: "Select GPP Test Scenario",
                                     message: "Choose a privacy scenario to test",
                                     preferredStyle: .actionSheet)
        
        // Add scenario actions
        addScenarioAction(to: alert, scenario: .none, title: "None", subtitle: "No privacy settings")
        addScenarioAction(to: alert, scenario: .gppAbsent, title: "GPP Absent", subtitle: "No GPP string")
        addScenarioAction(to: alert, scenario: .ccpaConsent, title: "CCPA Consent (.QA)", subtitle: "User gave consent")
        addScenarioAction(to: alert, scenario: .ccpaOptOut, title: "CCPA Opt-Out (.YA)", subtitle: "User opted out")
        addScenarioAction(to: alert, scenario: .nonUS, title: "Non-US (Germany)", subtitle: "Outside US jurisdiction")
        addScenarioAction(to: alert, scenario: .usNonCalifornia, title: "US Non-California (NY)", subtitle: "US but not CA")
        addScenarioAction(to: alert, scenario: .attDenied, title: "⭐️ ATT Denied", subtitle: "Tracking disabled in iOS Settings")
        
        // GDPR/TCF Scenarios
        addScenarioAction(to: alert, scenario: .gdprFullConsent, title: "🇪🇺 GDPR Full Consent", subtitle: "All purposes + vendor OK")
        addScenarioAction(to: alert, scenario: .gdprDenied, title: "🇪🇺 GDPR Denied", subtitle: "No purposes consented")
        addScenarioAction(to: alert, scenario: .gdprPurpose1Denied, title: "🇪🇺 GDPR Purpose 1 Denied", subtitle: "Device access denied")
        addScenarioAction(to: alert, scenario: .gdprVendorDenied, title: "🇪🇺 GDPR Vendor Denied", subtitle: "Purposes OK, vendor NO")
        
        // Cancel action
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // Present
        viewController.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Scenario Management
    
    private func addScenarioAction(to alert: UIAlertController,
                                   scenario: GPPTestScenario,
                                   title: String,
                                   subtitle: String) {
        let fullTitle = "\(title)\n\(subtitle)"
        let action = UIAlertAction(title: fullTitle, style: .default) { [weak self] _ in
            self?.selectScenario(scenario, withTitle: title)
        }
        
        // Mark current scenario with checkmark (doesn't work on iOS but won't hurt)
        if currentScenario == scenario {
            action.setValue(true, forKey: "checked")
        }
        
        alert.addAction(action)
    }
    
    private func selectScenario(_ scenario: GPPTestScenario, withTitle title: String) {
        currentScenario = scenario
        updateButtonTitle(title)
        applyScenario(scenario)
    }
    
    private func updateButtonTitle(_ scenarioName: String) {
        let buttonTitle = "\(scenarioName) (Tap to Change)"
        scenarioButton.setTitle(buttonTitle, for: .normal)
    }
    
    /// Dynamically determine SID based on actual CloudFront geo location
    /// Real CMPs set SIDs based on what sections are in the GPP string, not geo-location
    /// For demo purposes, we use geo to auto-select the appropriate test scenario
    private func dynamicGPPSid() -> [Int] {
        let geoService = CLXGeoLocationService.shared()
        let isCalifornia = geoService.isCaliforniaUser()
        let isUS = geoService.isUSUser()
        
        if isCalifornia {
            DemoAppLogger.sharedInstance.logMessage("📍 Detected California → Using SID 8 (US-CA)")
            return [8]  // US-California
        } else if isUS {
            DemoAppLogger.sharedInstance.logMessage("📍 Detected US (non-CA) → Using SID 7 (US-National)")
            return [7]  // US-National
        } else {
            // Real CMPs would not set GPP for non-US regions, or would set appropriate EU sections
            // For demo: don't set GPP at all for non-US (return nil marker)
            DemoAppLogger.sharedInstance.logMessage("📍 Detected Non-US → GPP should not be set for this region")
            return [-1]   // Special marker: don't set GPP
        }
    }
    
    private func applyScenario(_ scenario: GPPTestScenario) {
        resetGPPSettings()
        
        switch scenario {
        case .none:
            DemoAppLogger.sharedInstance.logMessage("🧪 GPP Scenario: None (real geo data from CloudFront API)")
            
        case .gppAbsent:
            DemoAppLogger.sharedInstance.logMessage("🧪 GPP Scenario: GPP Absent (real geo data from CloudFront API)")
            
        case .ccpaConsent:
            DemoAppLogger.sharedInstance.logMessage("🧪 GPP Scenario: CCPA Consent (Allow All) - AUTO-DETECTING LOCATION")
            let sidConsent = dynamicGPPSid()
            if sidConsent.first != -1 {
                setIABGPPString("DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA")
                setIABGPPSid(sidConsent)
            } else {
                DemoAppLogger.sharedInstance.logMessage("⚠️ Non-US region: GPP not set (real CMPs wouldn't set US privacy for non-US users)")
            }
            
        case .ccpaOptOut:
            DemoAppLogger.sharedInstance.logMessage("🧪 GPP Scenario: CCPA Opt-Out (Disallow All) - AUTO-DETECTING LOCATION")
            let sidOptOut = dynamicGPPSid()
            if sidOptOut.first != -1 {
                setIABGPPString("DBABrw~BAAVAAAAAABA.QA~BAUAAABA.QA")
                setIABGPPSid(sidOptOut)
                // IAB US Privacy: 1YYN = Version 1, Notice given, OPTED OUT, Not LSPA
                setIABUSPrivacyString("1YYN")
            } else {
                DemoAppLogger.sharedInstance.logMessage("⚠️ Non-US region: GPP not set (real CMPs wouldn't set US privacy for non-US users)")
            }
            
        case .nonUS:
            DemoAppLogger.sharedInstance.logMessage("🧪 GPP Scenario: Non-US (Allow All) - AUTO-DETECTING LOCATION")
            let sidNonUS = dynamicGPPSid()
            if sidNonUS.first != -1 {
                setIABGPPString("DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA")
                setIABGPPSid(sidNonUS)
            } else {
                DemoAppLogger.sharedInstance.logMessage("⚠️ Non-US region detected: GPP not set (simulating real CMP behavior)")
            }
            
        case .usNonCalifornia:
            DemoAppLogger.sharedInstance.logMessage("🧪 GPP Scenario: US Non-California - AUTO-DETECTING LOCATION")
            let sidUSNonCA = dynamicGPPSid()
            if sidUSNonCA.first != -1 {
                setIABGPPString("DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA")
                setIABGPPSid(sidUSNonCA)
            } else {
                DemoAppLogger.sharedInstance.logMessage("⚠️ Non-US region: GPP not set (real CMPs wouldn't set US privacy for non-US users)")
            }
            
        case .attDenied:
            DemoAppLogger.sharedInstance.logMessage("🧪 GPP Scenario: ATT Denied (real geo data from CloudFront API)")
            DemoAppLogger.sharedInstance.logMessage("⚠️ To test: Go to iOS Settings → Privacy & Security → Tracking → Disable for this app")
            DemoAppLogger.sharedInstance.logMessage("⚠️ Then restart the app and select this scenario")
            
        // GDPR/TCF Scenarios - Set IAB TCF UserDefaults keys
        case .gdprFullConsent:
            DemoAppLogger.sharedInstance.logMessage("🧪 GDPR Scenario: Full Consent (All purposes + vendor)")
            setIABTCFGdprApplies(true)
            // TCF string with all purposes enabled and vendor 1510 (CloudX) consented
            setIABTCFString("CQbFSYAQbFSYAEsACBENCFFoAP_gAEPgACiQINJB7C7FbSFCyLZzaLsAMAhHRsAAQoQAAASBAmABQAKQIAQCgkAYFASABAACAAAAICRBIQIECAAAAUAAAAAAAAAEAAAAAAAIIAAAgAEAAAAIAAAKAIAAEAAIAAAAEAAAmAgAAIIACAAAgAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAQNVSD2F2K2kKFkWCmwXYAYBCujYAAhQgAAAkCBMACgAUgQAgFJIAgCIEAAAAAAAAAQEiCQAAQEBAAAIACAAAAAAAIAAAAAAAQQAABAAIAAAAAAAAUAQAAIAAQAAAAIAABEhAAAQQAEAAAAAAAQAAA")
            setIABTCFPurposeConsents("1111111111")  // All 10 purposes granted
            
        case .gdprDenied:
            DemoAppLogger.sharedInstance.logMessage("🧪 GDPR Scenario: Denied (No purposes consented)")
            setIABTCFGdprApplies(true)
            setIABTCFString("CQbFSYAQbFSYAEsACBENCFFgAAAAAEPgACiQAAANVSD2F2K2kKFkWCmwXYAYBCujYAAhQgAAAkCBMACgAUgQAgFJIAgCIEAAAAAAAAAQEiCQAAQEBAAAIACAAAAAAAIAAAAAAAQQAABAAIAAAAAAAAUAQAAIAAQAAAAIAABEhAAAQQAEAAAAAAAQAA")
            setIABTCFPurposeConsents("0000000000")  // All purposes denied
            
        case .gdprPurpose1Denied:
            DemoAppLogger.sharedInstance.logMessage("🧪 GDPR Scenario: Purpose 1 Denied (Device access denied)")
            setIABTCFGdprApplies(true)
            setIABTCFString("CQbFSYAQbFSYAEsACDENCFFgAHAAAEPgACiQACBA1VIPYXYraQoWRYKbBdgBgEK6NgACFCAAACQIEwAKABSBACAUkgCAIgQAAAAAAAABASIJAABAQEAAAgAIAAAAAAAgAAAAAABBAAAEAAgAAAAAAABQBAAAgABAAAAAgAAESEAABBAAQAAAAAABAAA")
            setIABTCFPurposeConsents("0111111111")  // Purpose 1 denied, others granted
            
        case .gdprVendorDenied:
            DemoAppLogger.sharedInstance.logMessage("🧪 GDPR Scenario: Vendor Denied (Purposes OK, CloudX vendor denied)")
            setIABTCFGdprApplies(true)
            setIABTCFString("CQbFSYAQbFSYAEsACDENCFFgAPAAAEPgACiQAFIBA1VIPYXYraQoWRYKbBdgBgEK6NgACFCAAACQIEwAKABSBACAUkgCAIgQAAAAAAAABASIJAABAQEAAAgAIAAAAAAAgAAAAAABBAAAEAAgAAAAAAABQBAAAgABAAAAAgAAESEAABBAAQAAAAAABAAA")
            setIABTCFPurposeConsents("1111111111")  // All purposes granted
        }
    }
    
    // MARK: - IAB TCF UserDefaults Methods
    
    private func setIABTCFGdprApplies(_ applies: Bool) {
        UserDefaults.standard.set(applies ? 1 : 0, forKey: "IABTCF_gdprApplies")
        UserDefaults.standard.synchronize()
    }
    
    private func setIABTCFString(_ tcString: String?) {
        if let tcString = tcString {
            UserDefaults.standard.set(tcString, forKey: "IABTCF_TCString")
        } else {
            UserDefaults.standard.removeObject(forKey: "IABTCF_TCString")
        }
        UserDefaults.standard.synchronize()
    }
    
    private func setIABTCFPurposeConsents(_ purposeConsents: String?) {
        if let purposeConsents = purposeConsents {
            UserDefaults.standard.set(purposeConsents, forKey: "IABTCF_PurposeConsents")
        } else {
            UserDefaults.standard.removeObject(forKey: "IABTCF_PurposeConsents")
        }
        UserDefaults.standard.synchronize()
    }
    
    private func setIABGPPString(_ gppString: String?) {
        if let gppString = gppString {
            UserDefaults.standard.set(gppString, forKey: "IABGPP_HDR_GppString")
        } else {
            UserDefaults.standard.removeObject(forKey: "IABGPP_HDR_GppString")
        }
        UserDefaults.standard.synchronize()
    }
    
    private func setIABGPPSid(_ gppSid: [Int]?) {
        if let gppSid = gppSid, !gppSid.isEmpty {
            // Convert array to underscore-delimited string (IAB standard format)
            let sidString = gppSid.map { String($0) }.joined(separator: "_")
            UserDefaults.standard.set(sidString, forKey: "IABGPP_GppSID")
        } else {
            UserDefaults.standard.removeObject(forKey: "IABGPP_GppSID")
        }
        UserDefaults.standard.synchronize()
    }
    
    private func setIABUSPrivacyString(_ usPrivacyString: String?) {
        if let usPrivacyString = usPrivacyString {
            UserDefaults.standard.set(usPrivacyString, forKey: "IABUSPrivacy_String")
        } else {
            UserDefaults.standard.removeObject(forKey: "IABUSPrivacy_String")
        }
        UserDefaults.standard.synchronize()
    }
    
    private func resetGPPSettings() {
        // Clear IAB GPP UserDefaults directly (CloudX reads from these)
        UserDefaults.standard.removeObject(forKey: "IABGPP_HDR_GppString")
        UserDefaults.standard.removeObject(forKey: "IABGPP_GppSID")
        
        // Clear IAB TCF UserDefaults (GDPR)
        UserDefaults.standard.removeObject(forKey: "IABTCF_TCString")
        UserDefaults.standard.removeObject(forKey: "IABTCF_gdprApplies")
        UserDefaults.standard.removeObject(forKey: "IABTCF_PurposeConsents")
        UserDefaults.standard.removeObject(forKey: "IABTCF_VendorConsents")
        
        // Clear IAB US Privacy (CCPA)
        UserDefaults.standard.removeObject(forKey: "IABUSPrivacy_String")
        
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Helper
    
    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            if let viewController = responder as? UIViewController {
                return viewController
            }
            responder = responder?.next
        }
        return nil
    }
}

