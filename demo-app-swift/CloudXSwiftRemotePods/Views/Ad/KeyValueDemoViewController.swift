//
//  KeyValueDemoViewController.swift
//  CloudXSwiftRemotePods
//
//  Created by CloudX on 2025-01-09.
//

import UIKit
import CloudXCore

class KeyValueDemoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // UI Components
    private var scrollView: UIScrollView!
    private var mainStackView: UIStackView!
    
    // Add Key-Value Section
    private var addKVSection: UIView!
    private var kvTypeSegment: UISegmentedControl!
    private var keyTextField: UITextField!
    private var valueTextField: UITextField!
    private var addButton: UIButton!
    
    // Current Key-Values Section
    private var currentKVSection: UIView!
    private var kvTableView: UITableView!
    private var clearAllButton: UIButton!
    
    // Info Section
    private var infoSection: UIView!
    private var infoLabel: UILabel!
    
    // Data
    private var displayedUserKVs: [String: String] = [:]
    private var displayedAppKVs: [String: String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Key-Value Pairs"
        view.backgroundColor = .systemBackground
        
        setupScrollView()
        setupAddKVSection()
        setupCurrentKVSection()
        setupInfoSection()
        refreshDisplayedData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshDisplayedData()
    }
    
    private func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.spacing = 20
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            mainStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            mainStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            mainStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            mainStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }
    
    private func setupAddKVSection() {
        addKVSection = createSection(title: "Add Key-Value Pair")
        
        // Type selector
        kvTypeSegment = UISegmentedControl(items: ["User-Level", "App-Level"])
        kvTypeSegment.selectedSegmentIndex = 0
        
        // Key input
        let keyLabel = UILabel()
        keyLabel.text = "Key:"
        keyLabel.font = .systemFont(ofSize: 14, weight: .medium)
        
        keyTextField = UITextField()
        keyTextField.placeholder = "e.g., age, interest, app_version"
        keyTextField.borderStyle = .roundedRect
        keyTextField.autocapitalizationType = .none
        keyTextField.autocorrectionType = .no
        
        // Value input
        let valueLabel = UILabel()
        valueLabel.text = "Value:"
        valueLabel.font = .systemFont(ofSize: 14, weight: .medium)
        
        valueTextField = UITextField()
        valueTextField.placeholder = "e.g., 25, gaming, 1.2.3"
        valueTextField.borderStyle = .roundedRect
        valueTextField.autocapitalizationType = .none
        valueTextField.autocorrectionType = .no
        
        // Add button
        addButton = UIButton(type: .system)
        addButton.setTitle("Add Key-Value Pair", for: .normal)
        addButton.backgroundColor = .systemBlue
        addButton.setTitleColor(.white, for: .normal)
        addButton.layer.cornerRadius = 8
        addButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        addButton.addTarget(self, action: #selector(addKeyValuePair), for: .touchUpInside)
        
        // Stack in section
        let contentStack = UIStackView(arrangedSubviews: [
            kvTypeSegment, keyLabel, keyTextField, valueLabel, valueTextField, addButton
        ])
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addKVSection.addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: addKVSection.topAnchor, constant: 50),
            contentStack.leadingAnchor.constraint(equalTo: addKVSection.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: addKVSection.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: addKVSection.bottomAnchor, constant: -16),
            addButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        mainStackView.addArrangedSubview(addKVSection)
    }
    
    private func setupCurrentKVSection() {
        currentKVSection = createSection(title: "Current Key-Value Pairs")
        
        // Table view
        kvTableView = UITableView(frame: .zero, style: .plain)
        kvTableView.delegate = self
        kvTableView.dataSource = self
        kvTableView.translatesAutoresizingMaskIntoConstraints = false
        kvTableView.layer.cornerRadius = 8
        kvTableView.layer.borderWidth = 1
        kvTableView.layer.borderColor = UIColor.separator.cgColor
        kvTableView.register(UITableViewCell.self, forCellReuseIdentifier: "KVCell")
        
        // Clear all button
        clearAllButton = UIButton(type: .system)
        clearAllButton.setTitle("Clear All Key-Value Pairs", for: .normal)
        clearAllButton.backgroundColor = .systemRed
        clearAllButton.setTitleColor(.white, for: .normal)
        clearAllButton.layer.cornerRadius = 8
        clearAllButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        clearAllButton.addTarget(self, action: #selector(clearAllKeyValues), for: .touchUpInside)
        
        let contentStack = UIStackView(arrangedSubviews: [kvTableView, clearAllButton])
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        currentKVSection.addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: currentKVSection.topAnchor, constant: 50),
            contentStack.leadingAnchor.constraint(equalTo: currentKVSection.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: currentKVSection.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: currentKVSection.bottomAnchor, constant: -16),
            kvTableView.heightAnchor.constraint(equalToConstant: 200),
            clearAllButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        mainStackView.addArrangedSubview(currentKVSection)
    }
    
    private func setupInfoSection() {
        infoSection = createSection(title: "Info")
        
        infoLabel = UILabel()
        infoLabel.numberOfLines = 0
        infoLabel.font = .systemFont(ofSize: 13)
        infoLabel.textColor = .secondaryLabel
        infoLabel.text = """
        📌 Key-value pairs are injected into bid requests at server-configured paths.
        
        👤 User-Level: User-specific targeting (e.g., age, interests)
           • Respects privacy regulations (GDPR/CCPA)
           • Cleared when privacy requires removing PII
        
        📱 App-Level: App-specific targeting (e.g., app version, build)
           • Not affected by privacy regulations
           • Always included in bid requests
        
        💡 The server controls where these values appear in the bid request via the keyValuePaths configuration.
        """
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoSection.addSubview(infoLabel)
        
        // Add sample data button
        let sampleButton = UIButton(type: .system)
        sampleButton.setTitle("Load Sample Key-Values (for testing)", for: .normal)
        sampleButton.backgroundColor = .systemGreen
        sampleButton.setTitleColor(.white, for: .normal)
        sampleButton.layer.cornerRadius = 8
        sampleButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        sampleButton.addTarget(self, action: #selector(loadSampleKeyValues), for: .touchUpInside)
        sampleButton.translatesAutoresizingMaskIntoConstraints = false
        infoSection.addSubview(sampleButton)
        
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: infoSection.topAnchor, constant: 50),
            infoLabel.leadingAnchor.constraint(equalTo: infoSection.leadingAnchor, constant: 16),
            infoLabel.trailingAnchor.constraint(equalTo: infoSection.trailingAnchor, constant: -16),
            
            sampleButton.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 16),
            sampleButton.leadingAnchor.constraint(equalTo: infoSection.leadingAnchor, constant: 16),
            sampleButton.trailingAnchor.constraint(equalTo: infoSection.trailingAnchor, constant: -16),
            sampleButton.heightAnchor.constraint(equalToConstant: 44),
            sampleButton.bottomAnchor.constraint(equalTo: infoSection.bottomAnchor, constant: -16)
        ])
        
        mainStackView.addArrangedSubview(infoSection)
    }
    
    private func createSection(title: String) -> UIView {
        let section = UIView()
        section.backgroundColor = .secondarySystemBackground
        section.layer.cornerRadius = 12
        section.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        section.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: section.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: section.leadingAnchor, constant: 16)
        ])
        
        return section
    }
    
    // MARK: - Actions
    
    @objc private func addKeyValuePair() {
        let key = keyTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let value = valueTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        guard !key.isEmpty, !value.isEmpty else {
            showAlert(title: "Error", message: "Both key and value are required")
            return
        }
        
        let isUserLevel = kvTypeSegment.selectedSegmentIndex == 0
        
        if isUserLevel {
            CloudXCore.shared.setUserKeyValue(key, value: value)
            displayedUserKVs[key] = value
            DemoAppLogger.sharedInstance.logMessage("✅ Added user key-value: \(key) = \(value)")
        } else {
            CloudXCore.shared.setAppKeyValue(key, value: value)
            displayedAppKVs[key] = value
            DemoAppLogger.sharedInstance.logMessage("✅ Added app key-value: \(key) = \(value)")
        }
        
        // Clear inputs
        keyTextField.text = ""
        valueTextField.text = ""
        keyTextField.resignFirstResponder()
        valueTextField.resignFirstResponder()
        
        // Refresh table
        kvTableView.reloadData()
        
        showAlert(title: "Success", 
                 message: "Added \(isUserLevel ? "user-level" : "app-level") key-value pair: \(key) = \(value)")
    }
    
    @objc private func clearAllKeyValues() {
        let alert = UIAlertController(title: "Clear All?",
                                     message: "This will remove all user and app-level key-value pairs.",
                                     preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Clear All", style: .destructive) { [weak self] _ in
            CloudXCore.shared.clearAllKeyValues()
            self?.displayedUserKVs.removeAll()
            self?.displayedAppKVs.removeAll()
            self?.kvTableView.reloadData()
            DemoAppLogger.sharedInstance.logMessage("🧹 Cleared all key-value pairs")
        })
        
        present(alert, animated: true, completion: nil)
    }
    
    private func refreshDisplayedData() {
        // Get current state from CLXKeyValueState
        let state = CLXKeyValueState.shared()
        displayedUserKVs = (state.userKeyValues as? [String: String]) ?? [:]
        displayedAppKVs = (state.appKeyValues as? [String: String]) ?? [:]
        kvTableView.reloadData()
    }
    
    @objc private func loadSampleKeyValues() {
        DemoAppLogger.sharedInstance.logMessage("🧪 Loading HIGH-ROI targeting key-values...")
        
        // 💡 PRO TIP:
        // These key-values represent the "Golden List" of high-value signals that mobile ad bidders pay a premium for.
        // By passing these signals as First-Party Data, you help bidders identify high-quality users (e.g., payers,
        // frequent users, heavy ad watchers) without violating privacy rules.
        //
        // The values below create a "Whale" profile (high-spending, highly engaged user) to demonstrate
        // how to structure these signals for maximum CPM lift.
        
        // ============================================
        // 1. MONETIZATION & SPEND (The "Whale" Signals)
        // ============================================
        
        // #1 Signal. Immediate price floor increase for known spenders.
        CloudXCore.shared.setUserKeyValue("payer_status", value: "whale")
        
        // Bidders prefer hard number buckets over abstract segments.
        CloudXCore.shared.setUserKeyValue("iap_total_bucket", value: "50-100")
        
        // Recent payers are significantly more likely to convert again.
        CloudXCore.shared.setUserKeyValue("recency_purchase", value: "0-7d")
        
        // Identifies high-quality recurring revenue users.
        CloudXCore.shared.setUserKeyValue("subscription_status", value: "active")
        
        // Forward-looking predictive metric (gold for bidders).
        CloudXCore.shared.setUserKeyValue("predicted_ltv", value: "high")
        
        // ============================================
        // 2. ENGAGEMENT & RETENTION
        // ============================================
        
        // Advertisers bid differently for new users vs. loyal veterans.
        CloudXCore.shared.setUserKeyValue("user_tenure", value: "d30")
        
        // Critical for predicting ad fatigue and engagement quality.
        CloudXCore.shared.setUserKeyValue("session_frequency", value: "daily")
        
        // Proof of deep engagement; correlates with viewability.
        CloudXCore.shared.setUserKeyValue("level_achieved", value: "42")
        
        // Composite score (e.g., sessions/day + duration).
        CloudXCore.shared.setUserKeyValue("engagement_score", value: "high")
        
        // Users on old versions often monetize poorly or have bugs.
        CloudXCore.shared.setUserKeyValue("app_version_age", value: "latest")
        
        // Gamified progression status for VIP management.
        CloudXCore.shared.setUserKeyValue("loyalty_tier", value: "gold")
        
        // ============================================
        // 3. AD CONSUMPTION HABITS
        // ============================================
        
        // User watches high volume (10+) of rewarded videos/day.
        CloudXCore.shared.setUserKeyValue("ad_whale", value: "true")
        
        // Propensity to click/engage with rewarded video units.
        CloudXCore.shared.setUserKeyValue("reward_affinity", value: "high")
        
        // Helps with frequency capping and inventory pricing logic.
        CloudXCore.shared.setUserKeyValue("ads_today_bucket", value: "6-15")
        
        // User has history of installing apps from interstitial ads.
        CloudXCore.shared.setUserKeyValue("interstitial_clicker", value: "true")
        
        // Impressions shown later in a session often perform differently.
        CloudXCore.shared.setUserKeyValue("session_depth", value: "5")
        
        // ============================================
        // 4. USER CONTEXT & DEMOGRAPHICS (Privacy-Safe)
        // ============================================
        
        // Never use exact age. Brackets are standard and safe.
        CloudXCore.shared.setUserKeyValue("age_bracket", value: "25-34")
        
        // Only if voluntarily provided by user.
        CloudXCore.shared.setUserKeyValue("gender_declared", value: "n/a")
        
        // Contextual interests based on app usage patterns.
        CloudXCore.shared.setUserKeyValue("interests", value: "strategy,rpg,tech")
        
        // Proxy for disposable income (e.g., iPhone 16 Pro vs iPhone 8).
        CloudXCore.shared.setUserKeyValue("device_tier", value: "high_end")
        
        // Heavy video ads prefer Wifi/5G connections.
        CloudXCore.shared.setUserKeyValue("connection_type", value: "wifi")
        
        // Critical for age-gated ad categories (alcohol, gambling).
        CloudXCore.shared.setUserKeyValue("age_verified", value: "true")
        
        // ============================================
        // 5. ACQUISITION & SOCIAL
        // ============================================
        
        // Paid users often have higher LTV than organic users.
        CloudXCore.shared.setUserKeyValue("install_source", value: "paid_fb")
        
        // Verified real human signal (anti-fraud).
        CloudXCore.shared.setUserKeyValue("social_login", value: "true")
        
        // Re-engagement potential signal for advertisers.
        CloudXCore.shared.setUserKeyValue("push_opt_in", value: "true")
        
        // User plays your other games (portfolio value).
        CloudXCore.shared.setUserKeyValue("cross_promo_user", value: "true")
        
        // ============================================
        // APP-LEVEL KEY-VALUES (never cleared)
        // ============================================
        CloudXCore.shared.setAppKeyValue("app_version", value: "1.2.3")
        CloudXCore.shared.setAppKeyValue("build_type", value: "debug")
        CloudXCore.shared.setAppKeyValue("platform", value: "ios")
        CloudXCore.shared.setAppKeyValue("app_category", value: "IAB9-5")
        
        DemoAppLogger.sharedInstance.logMessage("✅ HIGH-ROI targeting key-values loaded:")
        DemoAppLogger.sharedInstance.logMessage("")
        DemoAppLogger.sharedInstance.logMessage("🔥 MONETIZATION (Whale Signals):")
        DemoAppLogger.sharedInstance.logMessage("   payer_status=whale, iap=50-100, LTV=high")
        DemoAppLogger.sharedInstance.logMessage("")
        DemoAppLogger.sharedInstance.logMessage("💪 ENGAGEMENT:")
        DemoAppLogger.sharedInstance.logMessage("   tenure=d30, level=42, loyalty=gold")
        DemoAppLogger.sharedInstance.logMessage("")
        DemoAppLogger.sharedInstance.logMessage("📺 AD HABITS:")
        DemoAppLogger.sharedInstance.logMessage("   ad_whale=true, reward_affinity=high")
        DemoAppLogger.sharedInstance.logMessage("")
        DemoAppLogger.sharedInstance.logMessage("🧪 TEST: Load a banner ad and check bid request for user.ext.data")
        
        refreshDisplayedData()
        
        showAlert(title: "HIGH-ROI Targeting Loaded",
                 message: """
                 26 targeting key-values loaded:
                 
                 🔥 Monetization: payer, iap, LTV
                 💪 Engagement: tenure, level, loyalty
                 📺 Ad Habits: ad_whale, reward_affinity
                 👤 Demographics: age_bracket, device_tier
                 
                 Load a banner ad to see them in the bid request!
                 """
        )
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return displayedUserKVs.isEmpty ? 1 : displayedUserKVs.count
        } else {
            return displayedAppKVs.isEmpty ? 1 : displayedAppKVs.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "User-Level (Privacy-Aware)"
        } else {
            return "App-Level"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "KVCell", for: indexPath)
        
        let kvDict = indexPath.section == 0 ? displayedUserKVs : displayedAppKVs
        let sortedKeys = kvDict.keys.sorted()
        
        if sortedKeys.isEmpty {
            cell.textLabel?.text = "No key-value pairs"
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.font = .italicSystemFont(ofSize: 14)
            cell.selectionStyle = .none
        } else {
            let key = sortedKeys[indexPath.row]
            let value = kvDict[key] ?? ""
            cell.textLabel?.text = "\(key) = \(value)"
            cell.textLabel?.textColor = .label
            cell.textLabel?.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
            cell.selectionStyle = .default
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let kvDict = indexPath.section == 0 ? displayedUserKVs : displayedAppKVs
        guard !kvDict.isEmpty else { return }
        
        let sortedKeys = kvDict.keys.sorted()
        let key = sortedKeys[indexPath.row]
        let value = kvDict[key] ?? ""
        
        let alert = UIAlertController(title: "Key-Value Details",
                                     message: "Key: \(key)\nValue: \(value)\n\nType: \(indexPath.section == 0 ? "User-Level" : "App-Level")",
                                     preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let kvDict = indexPath.section == 0 ? displayedUserKVs : displayedAppKVs
        return !kvDict.isEmpty
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            var kvDict = indexPath.section == 0 ? displayedUserKVs : displayedAppKVs
            let sortedKeys = kvDict.keys.sorted()
            let key = sortedKeys[indexPath.row]
            
            // Remove from display
            kvDict.removeValue(forKey: key)
            
            // Note: We can't remove individual keys from CLXKeyValueState, only clear all
            // So we clear and re-add all remaining keys
            CloudXCore.shared.clearAllKeyValues()
            for (k, v) in displayedUserKVs {
                if k != key || indexPath.section != 0 {
                    CloudXCore.shared.setUserKeyValue(k, value: v)
                }
            }
            for (k, v) in displayedAppKVs {
                if k != key || indexPath.section != 1 {
                    CloudXCore.shared.setAppKeyValue(k, value: v)
                }
            }
            
            // Update display
            if indexPath.section == 0 {
                displayedUserKVs.removeValue(forKey: key)
            } else {
                displayedAppKVs.removeValue(forKey: key)
            }
            
            tableView.reloadData()
            DemoAppLogger.sharedInstance.logMessage("🗑️ Removed key: \(key)")
        }
    }
    
    // MARK: - Helpers
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

