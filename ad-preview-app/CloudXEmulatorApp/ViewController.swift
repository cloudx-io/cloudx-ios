import UIKit
import CloudXCore

private enum EmulatorConstants {
    static let maxEventCount = 300
    static let duplicateCollapseWindowMs: Int64 = 300
    static let defaultBannerAutoRefreshSeconds: TimeInterval = 10.0
    static let overridePrefix = "emu."
    static let defaultPostInitLoadDelayMs = 3_000
    static let maxPostInitLoadDelayMs = 10_000
    static let firstLoadRetryDelayMs = 1_500
    static let retryableFirstLoadErrorCodes: Set<Int> = [101, 302, 601, 609, 610]
    static let postInitLoadDelayOverrideKey = "post_init_load_delay_ms"

    static let overrideKeys: [String] = [
        "bundle_id",
        "geo_country",
        "geo_lat",
        "geo_lon",
        "device_model",
        "os_version",
        "placement_name",
        EmulatorConstants.postInitLoadDelayOverrideKey,
        "bid_price_overrides"
    ]
}

enum EmulatorDeepLinkParseError: Error, Equatable {
    case invalidRoute
    case missingAppKey
    case missingAdUnitId

    var description: String {
        switch self {
        case .invalidRoute:
            return "deep link must use cloudxemulator://load"
        case .missingAppKey:
            return "missing required app_key"
        case .missingAdUnitId:
            return "missing required ad_unit_id or placement"
        }
    }
}

enum AdFormat: String {
    case banner
    case mrec
    case interstitial
    case rewarded

    static func from(rawValue: String?) -> AdFormat {
        guard let normalized = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
            return .banner
        }

        switch normalized {
        case "banner":
            return .banner
        case "mrec":
            return .mrec
        case "interstitial":
            return .interstitial
        case "rewarded":
            return .rewarded
        default:
            return .banner
        }
    }

    var isInline: Bool {
        self == .banner || self == .mrec
    }

    var isFullscreen: Bool {
        self == .interstitial || self == .rewarded
    }
}

enum EmulatorEnvironment: String {
    case production = "prod"
    case staging = "staging"
    case development = "dev"

    static func from(rawValue: String?) -> EmulatorEnvironment {
        let normalized = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? "prod"
        switch normalized {
        case "prod", "production":
            return .production
        case "stage", "staging":
            return .staging
        case "dev", "development":
            return .development
        default:
            return .production
        }
    }

    var urlProviderEnvironment: String {
        switch self {
        case .production:
            return "production"
        case .staging:
            return "staging"
        case .development:
            return "dev"
        }
    }
}

struct DeepLinkLoadRequest: Equatable {
    let appKey: String
    let adUnitId: String
    let format: AdFormat
    let env: EmulatorEnvironment
    let overrides: [String: String]

    var normalizedPayload: [String: String] {
        var payload: [String: String] = [
            "app_key": appKey,
            "placement": adUnitId,
            "ad_unit_id": adUnitId,
            "format": format.rawValue,
            "env": env.rawValue
        ]
        for (key, value) in overrides {
            payload[key] = value
        }
        return payload
    }
}

final class DeepLinkParser {

    func parse(_ url: URL) -> Result<DeepLinkLoadRequest, EmulatorDeepLinkParseError> {
        guard url.scheme?.lowercased() == "cloudxemulator", url.host?.lowercased() == "load" else {
            return .failure(.invalidRoute)
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return .failure(.invalidRoute)
        }

        let appKey = queryValue(named: "app_key", in: components)?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let appKey, !appKey.isEmpty else {
            return .failure(.missingAppKey)
        }

        let adUnit = queryValue(named: "ad_unit_id", in: components)
        let placement = queryValue(named: "placement", in: components)
        let resolvedAdUnit = (adUnit?.isEmpty == false ? adUnit : placement)?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let resolvedAdUnit, !resolvedAdUnit.isEmpty else {
            return .failure(.missingAdUnitId)
        }

        let format = AdFormat.from(rawValue: queryValue(named: "format", in: components) ?? "banner")
        let env = EmulatorEnvironment.from(rawValue: queryValue(named: "env", in: components) ?? "prod")

        var overrides: [String: String] = [:]
        for key in EmulatorConstants.overrideKeys {
            if let value = queryValue(named: key, in: components) {
                overrides[key] = value
            }
        }

        let request = DeepLinkLoadRequest(
            appKey: appKey,
            adUnitId: resolvedAdUnit,
            format: format,
            env: env,
            overrides: overrides
        )
        return .success(request)
    }

    private func queryValue(named name: String, in components: URLComponents) -> String? {
        guard let item = components.queryItems?.first(where: { $0.name == name }) else {
            return nil
        }
        return item.value ?? ""
    }
}

enum EventCategory: String {
    case deepLink = "DEEP_LINK"
    case sdkInit = "SDK_INIT"
    case request = "REQUEST"
    case adLifecycle = "AD_LIFECYCLE"
    case revenue = "REVENUE"
    case error = "ERROR"
    case system = "SYSTEM"
}

enum EventSeverity: String {
    case info = "INFO"
    case success = "SUCCESS"
    case warn = "WARN"
    case error = "ERROR"

    var color: UIColor {
        switch self {
        case .success:
            return .statusSuccess
        case .warn:
            return .statusWarning
        case .error:
            return .statusError
        case .info:
            return .statusInfo
        }
    }
}

enum EventFilter: CaseIterable {
    case all
    case errors
    case lifecycle
    case revenue
    case `init`
    case deepLink

    var title: String {
        switch self {
        case .all:
            return "All"
        case .errors:
            return "Errors"
        case .lifecycle:
            return "Lifecycle"
        case .revenue:
            return "Revenue"
        case .`init`:
            return "Init"
        case .deepLink:
            return "Deep Link"
        }
    }

    func matches(_ event: EmulatorEvent) -> Bool {
        switch self {
        case .all:
            return true
        case .errors:
            return event.severity == .error || event.severity == .warn
        case .lifecycle:
            return event.category == .adLifecycle
        case .revenue:
            return event.category == .revenue
        case .`init`:
            return event.category == .sdkInit
        case .deepLink:
            return event.category == .deepLink
        }
    }
}

struct EmulatorEvent: Equatable {
    let timestampMs: Int64
    let timestampLabel: String
    let category: EventCategory
    let severity: EventSeverity
    let title: String
    let details: [String: String]
    let rawData: String
    let signature: String
    let duplicateCount: Int
}

struct SessionSnapshot: Equatable {
    var appKey: String?
    var adUnitId: String?
    var format: String?
    var env: String?
    var overrides: [String: String]
    var attemptCount: Int
    var successCount: Int
    var failureCount: Int
    var lastError: String?

    init(
        appKey: String? = nil,
        adUnitId: String? = nil,
        format: String? = nil,
        env: String? = nil,
        overrides: [String: String] = [:],
        attemptCount: Int = 0,
        successCount: Int = 0,
        failureCount: Int = 0,
        lastError: String? = nil
    ) {
        self.appKey = appKey
        self.adUnitId = adUnitId
        self.format = format
        self.env = env
        self.overrides = overrides
        self.attemptCount = attemptCount
        self.successCount = successCount
        self.failureCount = failureCount
        self.lastError = lastError
    }
}

struct BidInsightSnapshot: Equatable {
    var status: String = "Waiting for ad request"
    var winningNetwork: String?
    var networkPlacement: String?
    var revenueUsd: Double?
    var latencyMsApprox: Int?
    var errorCode: Int?
    var errorName: String?
    var errorMessage: String?
    var auctionRound: String = "Not available via SDK"
    var participants: String = "Not available via SDK"
}

struct DelayResolution: Equatable {
    enum Diagnostic: Equatable {
        case none
        case invalid(value: String, fallbackMs: Int)
        case clamped(requestedMs: Int, appliedMs: Int)
    }

    let delayMs: Int
    let diagnostic: Diagnostic
}

enum EmulatorLogic {
    static func needsInitialization(
        sdkInitialized: Bool,
        initializedAppKey: String?,
        initializedEnv: EmulatorEnvironment?,
        request: DeepLinkLoadRequest
    ) -> Bool {
        return !sdkInitialized || initializedAppKey != request.appKey || initializedEnv != request.env
    }

    static func resolvePostInitLoadDelay(rawValue: String?) -> DelayResolution {
        guard let raw = rawValue, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return DelayResolution(delayMs: EmulatorConstants.defaultPostInitLoadDelayMs, diagnostic: .none)
        }

        guard let parsed = Int(raw) else {
            return DelayResolution(
                delayMs: EmulatorConstants.defaultPostInitLoadDelayMs,
                diagnostic: .invalid(value: raw, fallbackMs: EmulatorConstants.defaultPostInitLoadDelayMs)
            )
        }

        let clamped = max(0, min(parsed, EmulatorConstants.maxPostInitLoadDelayMs))
        if clamped != parsed {
            return DelayResolution(delayMs: clamped, diagnostic: .clamped(requestedMs: parsed, appliedMs: clamped))
        }

        return DelayResolution(delayMs: clamped, diagnostic: .none)
    }

    static func isRetryableFirstLoadError(code: Int) -> Bool {
        EmulatorConstants.retryableFirstLoadErrorCodes.contains(code)
    }
}

enum EventMapper {
    private static let timelineFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    static func map(event: String, data: [String: Any], now: Date = Date()) -> EmulatorEvent {
        let details = data.reduce(into: [String: String]()) { partial, element in
            let key = element.key == "placement" ? "ad_unit" : element.key
            let value = String(describing: element.value).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { return }
            partial[key] = value
        }

        let category: EventCategory
        switch event {
        case "deep_link_received", "deep_link_parsed":
            category = .deepLink
        case "sdk_initializing", "sdk_initialized", "sdk_init_failed", "ENV_SET", "SDK_REUSE":
            category = .sdkInit
        case "ad_loading", "ad_loaded", "ad_displayed", "ad_clicked", "ad_closed", "ad_rewarded":
            category = .adLifecycle
        case "ad_revenue_paid":
            category = .revenue
        case "ad_load_failed", "ad_display_failed", "error":
            category = .error
        default:
            category = .system
        }

        let severity: EventSeverity
        if ["sdk_init_failed", "ad_display_failed", "error"].contains(event) {
            severity = .error
        } else if event == "ad_load_failed", details["error"]?.localizedCaseInsensitiveContains("timeout") == true {
            severity = .warn
        } else if event == "ad_load_failed" {
            severity = .error
        } else if ["sdk_initialized", "ad_loaded", "ad_displayed", "ad_revenue_paid"].contains(event) {
            severity = .success
        } else {
            severity = .info
        }

        let title: String
        switch event {
        case "sdk_initializing":
            title = "SDK initialization started"
        case "sdk_initialized":
            title = "SDK initialized"
        case "sdk_init_failed":
            title = "SDK initialization failed"
        case "ENV_SET":
            title = "Environment selected"
        case "SDK_REUSE":
            title = "SDK reused"
        case "deep_link_received":
            title = "Deep link received"
        case "deep_link_parsed":
            title = "Deep link parsed"
        case "ad_loading":
            title = "Ad load started"
        case "ad_loaded":
            title = "Ad loaded"
        case "ad_load_failed":
            title = "Ad load failed"
        case "ad_displayed":
            title = "Ad displayed"
        case "ad_display_failed":
            title = "Ad display failed"
        case "ad_clicked":
            title = "Ad clicked"
        case "ad_closed":
            title = "Ad closed"
        case "ad_rewarded":
            title = "Reward granted"
        case "ad_revenue_paid":
            title = "Revenue paid"
        default:
            title = event
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }

        let sortedDetails = details.sorted { $0.key < $1.key }
        let signature = event + "|" + severity.rawValue + "|" + category.rawValue + "|" +
            sortedDetails.map { "\($0.key)=\($0.value)" }.joined(separator: "&")

        let rawData: String
        if sortedDetails.isEmpty {
            rawData = "{}"
        } else {
            rawData = "{" + sortedDetails.map { "\($0.key)=\($0.value)" }.joined(separator: ", ") + "}"
        }

        let timestampMs = Int64((now.timeIntervalSince1970 * 1000.0).rounded())
        return EmulatorEvent(
            timestampMs: timestampMs,
            timestampLabel: timelineFormatter.string(from: now),
            category: category,
            severity: severity,
            title: title,
            details: details,
            rawData: rawData,
            signature: signature,
            duplicateCount: 1
        )
    }
}

final class EventTimelineStore {
    var allEvents: [EmulatorEvent] = []
    var activeFilter: EventFilter = .all

    func appendMapped(event: String, data: [String: Any], now: Date = Date()) {
        let mapped = EventMapper.map(event: event, data: data, now: now)
        if let last = allEvents.last,
           mapped.signature == last.signature,
           mapped.timestampMs - last.timestampMs <= EmulatorConstants.duplicateCollapseWindowMs {
            let deduped = EmulatorEvent(
                timestampMs: mapped.timestampMs,
                timestampLabel: mapped.timestampLabel,
                category: mapped.category,
                severity: mapped.severity,
                title: mapped.title,
                details: mapped.details,
                rawData: mapped.rawData,
                signature: mapped.signature,
                duplicateCount: last.duplicateCount + 1
            )
            allEvents[allEvents.count - 1] = deduped
        } else {
            allEvents.append(mapped)
        }

        if allEvents.count > EmulatorConstants.maxEventCount {
            let overflow = allEvents.count - EmulatorConstants.maxEventCount
            allEvents.removeFirst(overflow)
        }
    }

    func filteredEvents() -> [EmulatorEvent] {
        allEvents.reversed().filter { activeFilter.matches($0) }
    }

    func clear() {
        allEvents.removeAll()
    }
}

enum EventLogger {
    private static let eventPrefix = "[CX_EVENT]"
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    static var onEvent: ((String, [String: Any]) -> Void)?

    static func log(_ event: String, data: [String: Any] = [:]) {
        var payload: [String: Any] = [
            "event": event,
            "timestamp": isoFormatter.string(from: Date())
        ]
        if !data.isEmpty {
            payload["data"] = data
        }

        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
           let jsonString = String(data: data, encoding: .utf8) {
            let message = "\(eventPrefix) \(jsonString)"
            NSLog("%@", message)
            print(message)
        }

        onEvent?(event, data)
    }

    static func sdkInitializing(_ appKey: String) {
        log("sdk_initializing", data: ["app_key": appKey])
    }

    static func sdkInitialized(_ appKey: String) {
        log("sdk_initialized", data: ["app_key": appKey])
    }

    static func sdkInitFailed(_ appKey: String, _ error: String) {
        log("sdk_init_failed", data: ["app_key": appKey, "error": error])
    }

    static func overridesApplied(_ overrides: [String: String]) {
        log("overrides_applied", data: overrides)
    }

    static func adLoading(format: String, placement: String) {
        log("ad_loading", data: ["format": format, "placement": placement])
    }

    static func adRewarded(format: String, placement: String, rewardType: String, rewardAmount: Int) {
        log("ad_rewarded", data: [
            "format": format,
            "placement": placement,
            "reward_type": rewardType,
            "reward_amount": rewardAmount
        ])
    }

    static func deepLinkReceived(_ uri: String) {
        log("deep_link_received", data: ["uri": uri])
    }

    static func deepLinkParsed(_ params: [String: String]) {
        log("deep_link_parsed", data: params)
    }

    static func error(_ message: String, details: [String: Any] = [:]) {
        var merged = details
        merged["message"] = message
        log("error", data: merged)
    }
}

private final class InsetLabel: UILabel {
    private let insets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }
}

private final class DashedContainerView: UIView {
    private let borderLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .adContainerBackground
        layer.cornerRadius = 12
        layer.masksToBounds = true
        borderLayer.strokeColor = UIColor.adContainerBorder.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineDashPattern = [6, 4]
        borderLayer.lineWidth = 1
        layer.addSublayer(borderLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        borderLayer.frame = bounds
        borderLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: 12).cgPath
    }
}

private final class AutoRefreshLineView: UIView {
    private let trackLayer = CALayer()
    private let progressLayer = CALayer()
    private var progress: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        isUserInteractionEnabled = false
        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)
        trackLayer.backgroundColor = UIColor.divider.withAlphaComponent(0.35).cgColor
        progressLayer.backgroundColor = UIColor.primary.cgColor
        setProgress(0)
    }

    func setProgress(_ value: CGFloat) {
        progress = min(max(value, 0), 1)
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let lineHeight = min(max(bounds.height, 2), 4)
        let y = (bounds.height - lineHeight) / 2
        let fullWidth = max(0, bounds.width)

        trackLayer.frame = CGRect(x: 0, y: y, width: fullWidth, height: lineHeight)
        progressLayer.frame = CGRect(x: 0, y: y, width: fullWidth * progress, height: lineHeight)

        trackLayer.cornerRadius = lineHeight / 2
        progressLayer.cornerRadius = lineHeight / 2
    }
}

private final class EventTimelineCell: UITableViewCell {
    static let reuseIdentifier = "EventTimelineCell"

    private let severityDot = UIView()
    private let timeLabel = UILabel()
    private let categoryLabel = InsetLabel()
    private let countLabel = UILabel()
    private let titleLabel = UILabel()
    private let detailsLabel = UILabel()
    private let rawLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear

        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .surface
        card.layer.cornerRadius = 10
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.divider.cgColor
        contentView.addSubview(card)

        let topRow = UIStackView()
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = 8
        topRow.translatesAutoresizingMaskIntoConstraints = false

        severityDot.translatesAutoresizingMaskIntoConstraints = false
        severityDot.layer.cornerRadius = 4
        NSLayoutConstraint.activate([
            severityDot.widthAnchor.constraint(equalToConstant: 8),
            severityDot.heightAnchor.constraint(equalToConstant: 8)
        ])

        timeLabel.font = .monospacedSystemFont(ofSize: 11, weight: .bold)
        timeLabel.textColor = .textSecondary

        categoryLabel.font = .systemFont(ofSize: 10, weight: .bold)
        categoryLabel.textColor = .textSecondary
        categoryLabel.backgroundColor = .surfaceVariant
        categoryLabel.layer.cornerRadius = 8
        categoryLabel.layer.masksToBounds = true

        countLabel.font = .systemFont(ofSize: 10, weight: .bold)
        countLabel.textColor = .textSecondary

        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .textPrimary
        titleLabel.numberOfLines = 0

        detailsLabel.font = .systemFont(ofSize: 12)
        detailsLabel.textColor = .textSecondary
        detailsLabel.numberOfLines = 0

        rawLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        rawLabel.textColor = .textSecondary
        rawLabel.backgroundColor = .surfaceVariant
        rawLabel.layer.cornerRadius = 8
        rawLabel.layer.masksToBounds = true
        rawLabel.numberOfLines = 0

        topRow.addArrangedSubview(severityDot)
        topRow.addArrangedSubview(timeLabel)
        topRow.addArrangedSubview(categoryLabel)
        topRow.addArrangedSubview(countLabel)
        topRow.setCustomSpacing(4, after: severityDot)

        let stack = UIStackView(arrangedSubviews: [topRow, titleLabel, detailsLabel, rawLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10)
        ])
    }

    func configure(with event: EmulatorEvent, expanded: Bool) {
        severityDot.backgroundColor = event.severity.color
        timeLabel.text = event.timestampLabel
        categoryLabel.text = event.category.rawValue
        titleLabel.text = event.title

        let detailsText = event.details
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value.prefix(80))" }
            .joined(separator: "  ")
        detailsLabel.text = detailsText.isEmpty ? "No additional details" : detailsText

        countLabel.isHidden = event.duplicateCount <= 1
        countLabel.text = "x\(event.duplicateCount)"

        let canExpand = !event.rawData.isEmpty && event.rawData != "{}"
        rawLabel.isHidden = !(expanded && canExpand)
        rawLabel.text = "  \(event.rawData)  "
    }
}

private final class EventTimelineDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    private var items: [EmulatorEvent] = []
    private var expandedSignatures = Set<String>()

    func submit(_ events: [EmulatorEvent]) {
        items = events
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: EventTimelineCell.reuseIdentifier, for: indexPath) as? EventTimelineCell else {
            return UITableViewCell()
        }

        let event = items[indexPath.row]
        let expanded = expandedSignatures.contains(event.signature)
        cell.configure(with: event, expanded: expanded)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < items.count else { return }

        let event = items[indexPath.row]
        let canExpand = !event.rawData.isEmpty && event.rawData != "{}"
        guard canExpand else { return }

        if expandedSignatures.contains(event.signature) {
            expandedSignatures.remove(event.signature)
        } else {
            expandedSignatures.insert(event.signature)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

private enum Status {
    case waiting
    case initializing
    case loading
    case loaded
    case displayed
    case clicked
    case closed
    case error(message: String)

    var text: String {
        switch self {
        case .waiting:
            return "Waiting for deep link..."
        case .initializing:
            return "Initializing SDK..."
        case .loading:
            return "Loading ad..."
        case .loaded:
            return "Ad loaded"
        case .displayed:
            return "Ad displayed"
        case .clicked:
            return "Ad clicked"
        case .closed:
            return "Ad closed"
        case .error(let message):
            return "Error: \(message)"
        }
    }

    var color: UIColor {
        switch self {
        case .waiting, .clicked, .closed:
            return .statusInfo
        case .initializing, .loading:
            return .statusWarning
        case .loaded, .displayed:
            return .statusSuccess
        case .error:
            return .statusError
        }
    }
}

private final class MainView: UIView {
    let placementLabel = UILabel()
    let sdkVersionLabel = UILabel()

    let adUnitChip = UIButton(type: .system)
    let formatChip = UIButton(type: .system)
    let envChip = UIButton(type: .system)
    let bundleChip = UIButton(type: .system)
    let appKeyChip = UIButton(type: .system)
    let summaryLabel = UILabel()
    let autoRefreshLabel = UILabel()
    let autoRefreshLineView = AutoRefreshLineView()

    let statusIndicator = UIView()
    let statusLabel = UILabel()

    let overrideCountLabel = UILabel()
    let overridesLabel = UILabel()

    let adContainerBlock = UIView()
    let adContainer = DashedContainerView()
    let adPlaceholderLabel = UILabel()

    let showFullscreenButton = UIButton(type: .system)

    let bidStatusLabel = UILabel()
    let bidWinnerLabel = UILabel()
    let bidLatencyLabel = UILabel()
    let bidErrorLabel = UILabel()

    let timelineTableView = UITableView(frame: .zero, style: .plain)
    let clearEventsButton = UIButton(type: .system)
    let expandTimelineButton = UIButton(type: .system)

    let filterStack = UIStackView()
    private(set) var filterButtons: [EventFilter: UIButton] = [:]

    private(set) var adContainerHeightConstraint: NSLayoutConstraint!
    private let contentStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    func setActiveFilter(_ filter: EventFilter) {
        for (candidate, button) in filterButtons {
            if candidate == filter {
                button.backgroundColor = .primary
                button.setTitleColor(.white, for: .normal)
            } else {
                button.backgroundColor = .surfaceVariant
                button.setTitleColor(.textSecondary, for: .normal)
            }
        }
    }

    private func setupUI() {
        backgroundColor = .background

        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.backgroundColor = .clear
        addSubview(header)

        let headerStack = UIStackView()
        headerStack.axis = .vertical
        headerStack.spacing = 4
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(headerStack)

        let titleLabel = UILabel()
        titleLabel.text = "CloudXAdPreview"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .textPrimary

        let titleRow = UIStackView()
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 10
        titleRow.addArrangedSubview(titleLabel)
        titleRow.addArrangedSubview(UIView())

        let subtitleRow = UIStackView()
        subtitleRow.axis = .horizontal
        subtitleRow.spacing = 12
        subtitleRow.alignment = .center

        placementLabel.font = .systemFont(ofSize: 16, weight: .regular)
        placementLabel.textColor = .black
        placementLabel.text = "Ad unit: none"
        placementLabel.accessibilityIdentifier = "emu.placementLabel"
        placementLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        sdkVersionLabel.font = .systemFont(ofSize: 15, weight: .regular)
        sdkVersionLabel.textColor = .black
        sdkVersionLabel.textAlignment = .right
        sdkVersionLabel.text = "SDK: unknown"
        sdkVersionLabel.accessibilityIdentifier = "emu.sdkVersionLabel"

        subtitleRow.addArrangedSubview(placementLabel)
        subtitleRow.addArrangedSubview(sdkVersionLabel)

        headerStack.addArrangedSubview(titleRow)
        headerStack.addArrangedSubview(subtitleRow)

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 8
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        let sessionCard = makeCard()
        let sessionStack = UIStackView()
        sessionStack.axis = .vertical
        sessionStack.spacing = 8
        sessionStack.translatesAutoresizingMaskIntoConstraints = false
        sessionCard.addSubview(sessionStack)

        let chipScroll = UIScrollView()
        chipScroll.showsHorizontalScrollIndicator = false
        chipScroll.translatesAutoresizingMaskIntoConstraints = false

        let chipRow = UIStackView()
        chipRow.axis = .horizontal
        chipRow.spacing = 8
        chipRow.translatesAutoresizingMaskIntoConstraints = false
        chipScroll.addSubview(chipRow)

        [adUnitChip, formatChip, envChip, bundleChip, appKeyChip].forEach { chip in
            chip.titleLabel?.font = .systemFont(ofSize: 11, weight: .bold)
            chip.backgroundColor = .surfaceVariant
            chip.layer.cornerRadius = 10
            chip.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
            chip.setTitleColor(.textSecondary, for: .normal)
            chipRow.addArrangedSubview(chip)
        }

        summaryLabel.font = .systemFont(ofSize: 12)
        summaryLabel.textColor = .textSecondary
        summaryLabel.numberOfLines = 0
        autoRefreshLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        autoRefreshLabel.textColor = .textSecondary
        autoRefreshLabel.text = "Auto-refresh: waiting for ad load"
        autoRefreshLineView.translatesAutoresizingMaskIntoConstraints = false

        sessionStack.addArrangedSubview(chipScroll)
        sessionStack.addArrangedSubview(summaryLabel)
        sessionStack.addArrangedSubview(autoRefreshLabel)
        sessionStack.addArrangedSubview(autoRefreshLineView)
        autoRefreshLineView.heightAnchor.constraint(equalToConstant: 4).isActive = true

        adContainerHeightConstraint = adContainer.heightAnchor.constraint(equalToConstant: 100)

        NSLayoutConstraint.activate([
            chipRow.topAnchor.constraint(equalTo: chipScroll.topAnchor),
            chipRow.leadingAnchor.constraint(equalTo: chipScroll.leadingAnchor),
            chipRow.trailingAnchor.constraint(equalTo: chipScroll.trailingAnchor),
            chipRow.bottomAnchor.constraint(equalTo: chipScroll.bottomAnchor),
            chipRow.heightAnchor.constraint(equalTo: chipScroll.heightAnchor)
        ])

        let statusCard = makeCard()
        let statusRow = UIStackView()
        statusRow.axis = .horizontal
        statusRow.spacing = 12
        statusRow.alignment = .center
        statusRow.translatesAutoresizingMaskIntoConstraints = false
        statusCard.addSubview(statusRow)

        statusIndicator.translatesAutoresizingMaskIntoConstraints = false
        statusIndicator.layer.cornerRadius = 6
        NSLayoutConstraint.activate([
            statusIndicator.widthAnchor.constraint(equalToConstant: 12),
            statusIndicator.heightAnchor.constraint(equalToConstant: 12)
        ])

        statusLabel.font = .systemFont(ofSize: 16, weight: .medium)
        statusLabel.numberOfLines = 0
        statusLabel.accessibilityIdentifier = "emu.statusLabel"

        statusRow.addArrangedSubview(statusIndicator)
        statusRow.addArrangedSubview(statusLabel)

        let overridesCard = makeCard()
        let overridesStack = UIStackView()
        overridesStack.axis = .vertical
        overridesStack.spacing = 8
        overridesStack.translatesAutoresizingMaskIntoConstraints = false
        overridesCard.addSubview(overridesStack)

        overrideCountLabel.font = .systemFont(ofSize: 12, weight: .bold)
        overrideCountLabel.textColor = .textSecondary
        overrideCountLabel.isUserInteractionEnabled = true
        overrideCountLabel.accessibilityIdentifier = "emu.overrideCountLabel"

        overridesLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        overridesLabel.textColor = .textPrimary
        overridesLabel.numberOfLines = 0
        overridesLabel.accessibilityIdentifier = "emu.overridesLabel"

        overridesStack.addArrangedSubview(overrideCountLabel)
        overridesStack.addArrangedSubview(overridesLabel)

        adContainerBlock.translatesAutoresizingMaskIntoConstraints = false
        adContainerBlock.backgroundColor = .clear

        adContainer.translatesAutoresizingMaskIntoConstraints = false
        adContainerBlock.addSubview(adContainer)

        adPlaceholderLabel.text = "Ad Display Area"
        adPlaceholderLabel.textColor = .textSecondary
        adPlaceholderLabel.font = .systemFont(ofSize: 14)
        adPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        adContainer.addSubview(adPlaceholderLabel)

        showFullscreenButton.setTitle("Show Ad", for: .normal)
        showFullscreenButton.backgroundColor = .primary
        showFullscreenButton.setTitleColor(.white, for: .normal)
        showFullscreenButton.layer.cornerRadius = 10
        showFullscreenButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        showFullscreenButton.isHidden = true
        showFullscreenButton.isEnabled = false
        showFullscreenButton.accessibilityIdentifier = "emu.showFullscreenButton"

        let bidCard = makeCard()
        let bidStack = UIStackView()
        bidStack.axis = .vertical
        bidStack.spacing = 6
        bidStack.translatesAutoresizingMaskIntoConstraints = false
        bidCard.addSubview(bidStack)

        let bidTitle = UILabel()
        bidTitle.text = "Bid Insights"
        bidTitle.font = .systemFont(ofSize: 12, weight: .bold)
        bidTitle.textColor = .textSecondary

        [bidStatusLabel, bidWinnerLabel, bidLatencyLabel, bidErrorLabel].forEach { label in
            label.numberOfLines = 0
            label.font = .systemFont(ofSize: 12)
        }
        bidStatusLabel.textColor = .textPrimary
        bidWinnerLabel.textColor = .textSecondary
        bidLatencyLabel.textColor = .textSecondary
        bidErrorLabel.textColor = .statusError

        bidStack.addArrangedSubview(bidTitle)
        bidStack.addArrangedSubview(bidStatusLabel)
        bidStack.addArrangedSubview(bidWinnerLabel)
        bidStack.addArrangedSubview(bidLatencyLabel)
        bidStack.addArrangedSubview(bidErrorLabel)

        let timelineCard = makeCard()
        let timelineStack = UIStackView()
        timelineStack.axis = .vertical
        timelineStack.spacing = 8
        timelineStack.translatesAutoresizingMaskIntoConstraints = false
        timelineCard.addSubview(timelineStack)

        let timelineHeader = UIStackView()
        timelineHeader.axis = .horizontal
        timelineHeader.alignment = .center

        let timelineTitle = UILabel()
        timelineTitle.text = "Event Timeline"
        timelineTitle.font = .systemFont(ofSize: 12, weight: .bold)
        timelineTitle.textColor = .textSecondary

        clearEventsButton.setTitle("Clear", for: .normal)
        clearEventsButton.accessibilityIdentifier = "emu.clearEventsButton"
        clearEventsButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)

        expandTimelineButton.setTitle("Expand", for: .normal)
        expandTimelineButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)

        let timelineActions = UIStackView()
        timelineActions.axis = .horizontal
        timelineActions.alignment = .center
        timelineActions.spacing = 14
        timelineActions.addArrangedSubview(clearEventsButton)
        timelineActions.addArrangedSubview(expandTimelineButton)

        timelineHeader.addArrangedSubview(timelineTitle)
        timelineHeader.addArrangedSubview(UIView())
        timelineHeader.addArrangedSubview(timelineActions)

        filterStack.axis = .horizontal
        filterStack.spacing = 6
        filterStack.alignment = .fill

        for filter in EventFilter.allCases {
            let button = UIButton(type: .system)
            button.setTitle(filter.title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 10, weight: .semibold)
            button.layer.cornerRadius = 10
            button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
            button.backgroundColor = .surfaceVariant
            filterButtons[filter] = button
            filterStack.addArrangedSubview(button)
        }

        let filterScroll = UIScrollView()
        filterScroll.showsHorizontalScrollIndicator = false
        filterScroll.translatesAutoresizingMaskIntoConstraints = false
        filterScroll.isHidden = true
        filterScroll.addSubview(filterStack)

        NSLayoutConstraint.activate([
            filterStack.topAnchor.constraint(equalTo: filterScroll.topAnchor),
            filterStack.leadingAnchor.constraint(equalTo: filterScroll.leadingAnchor),
            filterStack.trailingAnchor.constraint(equalTo: filterScroll.trailingAnchor),
            filterStack.bottomAnchor.constraint(equalTo: filterScroll.bottomAnchor),
            filterStack.heightAnchor.constraint(equalTo: filterScroll.heightAnchor)
        ])

        timelineTableView.register(EventTimelineCell.self, forCellReuseIdentifier: EventTimelineCell.reuseIdentifier)
        timelineTableView.translatesAutoresizingMaskIntoConstraints = false
        timelineTableView.rowHeight = UITableView.automaticDimension
        timelineTableView.estimatedRowHeight = 88
        timelineTableView.separatorStyle = .none
        timelineTableView.backgroundColor = .clear

        timelineStack.addArrangedSubview(timelineHeader)
        timelineStack.addArrangedSubview(filterScroll)
        timelineStack.addArrangedSubview(timelineTableView)

        contentStack.addArrangedSubview(sessionCard)
        contentStack.addArrangedSubview(statusCard)
        contentStack.addArrangedSubview(overridesCard)
        contentStack.addArrangedSubview(adContainerBlock)
        contentStack.addArrangedSubview(showFullscreenButton)
        contentStack.addArrangedSubview(bidCard)
        contentStack.addArrangedSubview(timelineCard)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
            header.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            headerStack.topAnchor.constraint(equalTo: header.topAnchor),
            headerStack.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            headerStack.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            headerStack.bottomAnchor.constraint(equalTo: header.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),

            sessionStack.topAnchor.constraint(equalTo: sessionCard.topAnchor, constant: 12),
            sessionStack.leadingAnchor.constraint(equalTo: sessionCard.leadingAnchor, constant: 12),
            sessionStack.trailingAnchor.constraint(equalTo: sessionCard.trailingAnchor, constant: -12),
            sessionStack.bottomAnchor.constraint(equalTo: sessionCard.bottomAnchor, constant: -12),
            chipScroll.heightAnchor.constraint(equalToConstant: 28),

            statusRow.topAnchor.constraint(equalTo: statusCard.topAnchor, constant: 16),
            statusRow.leadingAnchor.constraint(equalTo: statusCard.leadingAnchor, constant: 16),
            statusRow.trailingAnchor.constraint(equalTo: statusCard.trailingAnchor, constant: -16),
            statusRow.bottomAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: -16),

            overridesStack.topAnchor.constraint(equalTo: overridesCard.topAnchor, constant: 16),
            overridesStack.leadingAnchor.constraint(equalTo: overridesCard.leadingAnchor, constant: 16),
            overridesStack.trailingAnchor.constraint(equalTo: overridesCard.trailingAnchor, constant: -16),
            overridesStack.bottomAnchor.constraint(equalTo: overridesCard.bottomAnchor, constant: -16),

            adContainer.topAnchor.constraint(equalTo: adContainerBlock.topAnchor),
            adContainer.leadingAnchor.constraint(equalTo: adContainerBlock.leadingAnchor),
            adContainer.trailingAnchor.constraint(equalTo: adContainerBlock.trailingAnchor),
            adContainer.bottomAnchor.constraint(equalTo: adContainerBlock.bottomAnchor),
            adContainerHeightConstraint,
            adPlaceholderLabel.centerXAnchor.constraint(equalTo: adContainer.centerXAnchor),
            adPlaceholderLabel.centerYAnchor.constraint(equalTo: adContainer.centerYAnchor),

            bidStack.topAnchor.constraint(equalTo: bidCard.topAnchor, constant: 12),
            bidStack.leadingAnchor.constraint(equalTo: bidCard.leadingAnchor, constant: 12),
            bidStack.trailingAnchor.constraint(equalTo: bidCard.trailingAnchor, constant: -12),
            bidStack.bottomAnchor.constraint(equalTo: bidCard.bottomAnchor, constant: -12),

            timelineStack.topAnchor.constraint(equalTo: timelineCard.topAnchor, constant: 12),
            timelineStack.leadingAnchor.constraint(equalTo: timelineCard.leadingAnchor, constant: 12),
            timelineStack.trailingAnchor.constraint(equalTo: timelineCard.trailingAnchor, constant: -12),
            timelineStack.bottomAnchor.constraint(equalTo: timelineCard.bottomAnchor, constant: -12),
            timelineTableView.heightAnchor.constraint(equalToConstant: 320)
        ])
    }

    private func makeCard() -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .surface
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.divider.cgColor
        return card
    }
}

final class EmulatorViewController: UIViewController {
    private let mainViewRef = MainView()
    private let parser = DeepLinkParser()
    private let timelineStore = EventTimelineStore()
    private let timelineDataSource = EventTimelineDataSource()

    private var bannerAd: CLXBannerAdView?
    private var interstitialAd: CLXInterstitial?
    private var rewardedAd: CLXRewarded?

    private var currentRequest: DeepLinkLoadRequest?
    private var pendingFlowRequest: DeepLinkLoadRequest?
    private var sdkInitialized = false
    private var initializedAppKey: String?
    private var initializedEnv: EmulatorEnvironment?

    private var sessionSnapshot = SessionSnapshot()
    private var bidInsightSnapshot = BidInsightSnapshot()
    private var displayedCount = 0
    private var currentLoadStartMs: Int64?

    private var pendingPostInitLoad: DispatchWorkItem?
    private var pendingFirstLoadRetry: DispatchWorkItem?
    private var firstLoadRetryArmed = false

    private var overridesExpanded = true
    private var isTimelineExpanded = false
    private var autoRefreshDisplayLink: CADisplayLink?
    private var autoRefreshCycleStartedAt: CFTimeInterval?
    private var autoRefreshIntervalSeconds: TimeInterval = EmulatorConstants.defaultBannerAutoRefreshSeconds
    private var renderedTimelineEvents: [EmulatorEvent] = []

    override func loadView() {
        view = mainViewRef
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        timelineStore.activeFilter = .all
        setupUIBindings()
        setupLogger()

        updateSDKVersionLabel()
        updateStatus(.waiting)
        updateSessionUI()
        updateBidInsightsUI()
        updateOverridesUI()
        updateAdPlacementVisibility(format: .banner)
        updateAutoRefreshTimerMode(for: .banner)
    }

    deinit {
        EventLogger.onEvent = nil
        cancelPendingPostInitLoad()
        cancelPendingFirstLoadRetry()
        stopAutoRefreshTimer(resetProgress: true)
        clearAds()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        schedulePendingFlowIfNeeded()
    }

    func handleIncomingURL(_ url: URL) {
        loadViewIfNeeded()
        EventLogger.deepLinkReceived(url.absoluteString)

        switch parser.parse(url) {
        case .failure(let error):
            EventLogger.error("deep_link_parse_failed", details: [
                "reason": error.description,
                "uri": url.absoluteString
            ])
            updateStatus(.error(message: error.description))
        case .success(let request):
            currentRequest = request
            EventLogger.deepLinkParsed(request.normalizedPayload)
            applyRequestSnapshot(request)
            pendingFlowRequest = request
            schedulePendingFlowIfNeeded()
        }
    }

    private func schedulePendingFlowIfNeeded() {
        guard let request = pendingFlowRequest, currentRequest == request else {
            pendingFlowRequest = nil
            return
        }

        guard isViewLoaded, view.window != nil else {
            return
        }

        // Let the first frame render before kicking off SDK init for a launch deep link.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, self.pendingFlowRequest == request, self.currentRequest == request else { return }
            self.pendingFlowRequest = nil
            self.startEmulatorFlow(with: request)
        }
    }

    private func setupUIBindings() {
        mainViewRef.timelineTableView.dataSource = timelineDataSource
        mainViewRef.timelineTableView.delegate = timelineDataSource

        for (_, button) in mainViewRef.filterButtons {
            button.addTarget(self, action: #selector(handleFilterButtonTap(_:)), for: .touchUpInside)
        }
        mainViewRef.setActiveFilter(.all)

        mainViewRef.clearEventsButton.addTarget(self, action: #selector(handleClearEventsTap), for: .touchUpInside)
        mainViewRef.expandTimelineButton.addTarget(self, action: #selector(handleExpandTimelineTap), for: .touchUpInside)
        mainViewRef.showFullscreenButton.addTarget(self, action: #selector(handleShowFullscreenTap), for: .touchUpInside)

        let overrideTap = UITapGestureRecognizer(target: self, action: #selector(toggleOverridesExpanded))
        mainViewRef.overrideCountLabel.addGestureRecognizer(overrideTap)

        mainViewRef.adUnitChip.addTarget(self, action: #selector(handleAdUnitChipTap), for: .touchUpInside)
        mainViewRef.formatChip.addTarget(self, action: #selector(handleFormatChipTap), for: .touchUpInside)
        mainViewRef.envChip.addTarget(self, action: #selector(handleEnvChipTap), for: .touchUpInside)
        mainViewRef.bundleChip.addTarget(self, action: #selector(handleBundleChipTap), for: .touchUpInside)
        mainViewRef.appKeyChip.addTarget(self, action: #selector(handleAppKeyChipTap), for: .touchUpInside)
    }

    @objc private func handleFilterButtonTap(_ sender: UIButton) {
        guard let filter = mainViewRef.filterButtons.first(where: { $0.value === sender })?.key else {
            return
        }
        timelineStore.activeFilter = filter
        mainViewRef.setActiveFilter(filter)
        renderFilteredEvents()
    }

    @objc private func handleClearEventsTap() {
        timelineStore.clear()
        renderFilteredEvents()
    }

    @objc private func handleCopyEventsTap() {
        copyFilteredEvents()
    }

    @objc private func handleShareEventsTap() {
        shareFilteredEvents()
    }

    @objc private func handleExpandTimelineTap() {
        toggleTimelineFullscreen()
    }

    @objc private func handleShowFullscreenTap() {
        showFullscreenAd()
    }

    @objc private func handleAdUnitChipTap() {
        copySessionValue(key: "ad_unit_id", value: sessionSnapshot.adUnitId)
    }

    @objc private func handleFormatChipTap() {
        copySessionValue(key: "format", value: sessionSnapshot.format)
    }

    @objc private func handleEnvChipTap() {
        copySessionValue(key: "env", value: sessionSnapshot.env)
    }

    @objc private func handleBundleChipTap() {
        copySessionValue(key: "bundle_id", value: sessionSnapshot.overrides["bundle_id"])
    }

    @objc private func handleAppKeyChipTap() {
        copySessionValue(key: "app_key", value: sessionSnapshot.appKey)
    }

    private func setupLogger() {
        EventLogger.onEvent = { [weak self] event, data in
            self?.runOnMain { [weak self] in
                guard let self else { return }
                self.timelineStore.appendMapped(event: event, data: data)
                self.renderFilteredEvents()
            }
        }
    }

    private func applyRequestSnapshot(_ request: DeepLinkLoadRequest) {
        mainViewRef.placementLabel.text = "Ad unit: \(request.adUnitId)"

        sessionSnapshot.appKey = request.appKey
        sessionSnapshot.adUnitId = request.adUnitId
        sessionSnapshot.format = request.format.rawValue
        sessionSnapshot.env = request.env.rawValue
        sessionSnapshot.overrides = request.overrides

        updateSessionUI()
        updateOverridesUI()
        updateAdPlacementVisibility(format: request.format)
        updateAutoRefreshTimerMode(for: request.format)
    }

    private func startEmulatorFlow(with request: DeepLinkLoadRequest) {
        cancelPendingPostInitLoad()
        cancelPendingFirstLoadRetry()
        firstLoadRetryArmed = false

        clearAds()
        applyEmulatorAppKeyValues(overrides: request.overrides)

        EmulatorDebugConfig.setBundleOverride(request.overrides["bundle_id"])

        if !request.overrides.isEmpty {
            EventLogger.overridesApplied(request.overrides)
        }

        let needsInit = EmulatorLogic.needsInitialization(
            sdkInitialized: sdkInitialized,
            initializedAppKey: initializedAppKey,
            initializedEnv: initializedEnv,
            request: request
        )

        if needsInit {
            if sdkInitialized {
                EmulatorDebugConfig.deinitializeSDK()
                sdkInitialized = false
            }

            EmulatorDebugConfig.setEnvironment(request.env)
            EventLogger.log("ENV_SET", data: ["env": request.env.rawValue])

            updateStatus(.initializing)
            EventLogger.sdkInitializing(request.appKey)

            let initConfig = CLXInitializationConfiguration.configuration(appKey: request.appKey)
            CloudXCore.shared.initialize(with: initConfig) { [weak self] sdkConfig, error in
                guard let self else { return }
                DispatchQueue.main.async {
                    if sdkConfig != nil {
                        self.sdkInitialized = true
                        self.initializedAppKey = request.appKey
                        self.initializedEnv = request.env
                        self.firstLoadRetryArmed = true
                        EventLogger.sdkInitialized(request.appKey)
                        self.schedulePostInitLoad(for: request)
                    } else {
                        self.sdkInitialized = false
                        self.firstLoadRetryArmed = false
                        let message = error?.localizedDescription ?? "Unknown"
                        self.recordFailure(message: message, errorCode: error?.code)
                        EventLogger.sdkInitFailed(request.appKey, message)
                        self.updateStatus(.error(message: message))
                    }
                }
            }
        } else {
            firstLoadRetryArmed = false
            EventLogger.log("SDK_REUSE", data: ["app_key": request.appKey, "env": request.env.rawValue])
            loadAd(for: request)
        }
    }

    private func schedulePostInitLoad(for request: DeepLinkLoadRequest) {
        cancelPendingPostInitLoad()

        let resolution = EmulatorLogic.resolvePostInitLoadDelay(rawValue: request.overrides[EmulatorConstants.postInitLoadDelayOverrideKey])

        switch resolution.diagnostic {
        case .invalid(let value, let fallbackMs):
            EventLogger.log("POST_INIT_LOAD_DELAY_INVALID", data: ["value": value, "fallback_ms": fallbackMs])
        case .clamped(let requestedMs, let appliedMs):
            EventLogger.log("POST_INIT_LOAD_DELAY_CLAMPED", data: ["requested_ms": requestedMs, "applied_ms": appliedMs])
        case .none:
            break
        }

        if resolution.delayMs <= 0 {
            loadAd(for: request)
            return
        }

        EventLogger.log("POST_INIT_LOAD_DELAY", data: [
            "placement": request.adUnitId,
            "delay_ms": resolution.delayMs
        ])

        let workItem = DispatchWorkItem { [weak self] in
            self?.pendingPostInitLoad = nil
            self?.loadAd(for: request)
        }

        pendingPostInitLoad = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(resolution.delayMs), execute: workItem)
    }

    private func cancelPendingPostInitLoad() {
        pendingPostInitLoad?.cancel()
        pendingPostInitLoad = nil
    }

    private func maybeScheduleFirstLoadRetry(for request: DeepLinkLoadRequest, error: CLXError) -> Bool {
        guard firstLoadRetryArmed else { return false }
        firstLoadRetryArmed = false

        guard EmulatorLogic.isRetryableFirstLoadError(code: error.code) else {
            return false
        }

        cancelPendingFirstLoadRetry()

        EventLogger.log("FIRST_LOAD_RETRY_SCHEDULED", data: [
            "format": request.format.rawValue,
            "placement": request.adUnitId,
            "retry_delay_ms": EmulatorConstants.firstLoadRetryDelayMs,
            "error_code": error.code,
            "error_name": errorName(for: error)
        ])

        let workItem = DispatchWorkItem { [weak self] in
            self?.pendingFirstLoadRetry = nil
            EventLogger.log("FIRST_LOAD_RETRY_LOADING", data: [
                "format": request.format.rawValue,
                "placement": request.adUnitId
            ])
            self?.loadAd(for: request)
        }

        pendingFirstLoadRetry = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(EmulatorConstants.firstLoadRetryDelayMs), execute: workItem)
        return true
    }

    private func cancelPendingFirstLoadRetry() {
        pendingFirstLoadRetry?.cancel()
        pendingFirstLoadRetry = nil
    }

    private func onAdLoadSucceeded() {
        firstLoadRetryArmed = false
        cancelPendingFirstLoadRetry()
    }

    private func applyEmulatorAppKeyValues(overrides: [String: String]) {
        CloudXCore.shared.clearAllKeyValues()

        for key in EmulatorConstants.overrideKeys {
            let value = overrides[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !value.isEmpty else { continue }
            CloudXCore.shared.setAppKeyValue("\(EmulatorConstants.overridePrefix)\(key)", value: value)
        }
    }

    private func loadAd(for request: DeepLinkLoadRequest) {
        sessionSnapshot.attemptCount += 1
        currentLoadStartMs = nowMs()

        bidInsightSnapshot.status = "Attempt #\(sessionSnapshot.attemptCount) in progress"
        bidInsightSnapshot.winningNetwork = nil
        bidInsightSnapshot.networkPlacement = nil
        bidInsightSnapshot.revenueUsd = nil
        bidInsightSnapshot.latencyMsApprox = nil
        bidInsightSnapshot.errorCode = nil
        bidInsightSnapshot.errorName = nil
        bidInsightSnapshot.errorMessage = nil

        updateSessionUI()
        updateBidInsightsUI()

        updateStatus(.loading)
        EventLogger.adLoading(format: request.format.rawValue, placement: request.adUnitId)

        switch request.format {
        case .banner:
            loadBanner(adUnitId: request.adUnitId, formatName: "banner")
        case .mrec:
            loadMREC(adUnitId: request.adUnitId, formatName: "mrec")
        case .interstitial:
            loadInterstitial(adUnitId: request.adUnitId)
        case .rewarded:
            loadRewarded(adUnitId: request.adUnitId)
        }
    }

    private func loadBanner(adUnitId: String, formatName: String) {
        let adView = formatName == "mrec"
            ? CloudXCore.shared.createMREC(adUnitId: adUnitId)
            : CloudXCore.shared.createBanner(adUnitId: adUnitId)

        bannerAd = adView
        bannerAd?.delegate = self
        bannerAd?.revenueDelegate = self
        bannerAd?.load()
    }

    private func loadMREC(adUnitId: String, formatName: String) {
        loadBanner(adUnitId: adUnitId, formatName: formatName)
    }

    private func loadInterstitial(adUnitId: String) {
        mainViewRef.showFullscreenButton.isHidden = false
        mainViewRef.showFullscreenButton.isEnabled = false

        interstitialAd = CloudXCore.shared.createInterstitial(adUnitId: adUnitId)
        interstitialAd?.delegate = self
        interstitialAd?.revenueDelegate = self
        interstitialAd?.load()
    }

    private func loadRewarded(adUnitId: String) {
        mainViewRef.showFullscreenButton.isHidden = false
        mainViewRef.showFullscreenButton.isEnabled = false

        rewardedAd = CloudXCore.shared.createRewarded(adUnitId: adUnitId)
        rewardedAd?.delegate = self
        rewardedAd?.revenueDelegate = self
        rewardedAd?.load()
    }

    private func showFullscreenAd() {
        interstitialAd?.show(from: self)
        rewardedAd?.show(from: self)
    }

    private func clearAds() {
        mainViewRef.adContainer.subviews
            .filter { $0 !== mainViewRef.adPlaceholderLabel }
            .forEach { $0.removeFromSuperview() }

        mainViewRef.adPlaceholderLabel.isHidden = false
        mainViewRef.adContainerHeightConstraint.constant = 100

        bannerAd?.removeFromSuperview()
        bannerAd?.destroy()
        bannerAd = nil

        interstitialAd?.destroy()
        interstitialAd = nil

        rewardedAd?.destroy()
        rewardedAd = nil

        mainViewRef.showFullscreenButton.isHidden = true
        mainViewRef.showFullscreenButton.isEnabled = false
        stopAutoRefreshTimer(resetProgress: true)
    }

    private func resolvedInlineAdSize(for adView: UIView) -> CGSize {
        let intrinsic = adView.intrinsicContentSize
        let intrinsicWidth = intrinsic.width
        let intrinsicHeight = intrinsic.height

        if intrinsicWidth > 0, intrinsicHeight > 0 {
            return CGSize(width: intrinsicWidth, height: intrinsicHeight)
        }

        let boundsSize = adView.bounds.size
        if boundsSize.width > 0, boundsSize.height > 0 {
            return boundsSize
        }

        guard let format = currentRequest?.format else {
            return CGSize(width: 320, height: 50)
        }

        switch format {
        case .mrec:
            return CGSize(width: 300, height: 250)
        case .banner:
            return CGSize(width: 320, height: 50)
        case .interstitial, .rewarded:
            return CGSize(width: 320, height: 50)
        }
    }

    private func attachAdViewCentered(_ adView: UIView) {
        adView.translatesAutoresizingMaskIntoConstraints = false
        mainViewRef.adContainer.subviews
            .filter { $0 !== mainViewRef.adPlaceholderLabel }
            .forEach { $0.removeFromSuperview() }

        mainViewRef.adContainer.addSubview(adView)
        let adSize = resolvedInlineAdSize(for: adView)
        mainViewRef.adContainerHeightConstraint.constant = max(CGFloat(100), adSize.height)

        NSLayoutConstraint.activate([
            adView.widthAnchor.constraint(equalToConstant: adSize.width),
            adView.heightAnchor.constraint(equalToConstant: adSize.height),
            adView.centerXAnchor.constraint(equalTo: mainViewRef.adContainer.centerXAnchor),
            adView.centerYAnchor.constraint(equalTo: mainViewRef.adContainer.centerYAnchor)
        ])

        mainViewRef.adPlaceholderLabel.isHidden = true
    }

    private func recordLoaded(ad: CLXAd) {
        sessionSnapshot.successCount += 1

        if let start = currentLoadStartMs {
            bidInsightSnapshot.latencyMsApprox = Int(nowMs() - start)
        }

        bidInsightSnapshot.status = "Ad loaded"
        bidInsightSnapshot.winningNetwork = ad.networkName
        bidInsightSnapshot.networkPlacement = ad.networkPlacement
        bidInsightSnapshot.errorCode = nil
        bidInsightSnapshot.errorName = nil
        bidInsightSnapshot.errorMessage = nil

        updateSessionUI()
        updateBidInsightsUI()
    }

    private func recordDisplayed() {
        displayedCount += 1
        updateSessionUI()
    }

    private func recordFailure(message: String, errorCode: Int?) {
        sessionSnapshot.failureCount += 1

        if let errorCode, let code = CLXErrorCode(rawValue: errorCode) {
            sessionSnapshot.lastError = CLXError.name(for: code)
            bidInsightSnapshot.errorName = CLXError.name(for: code)
        } else {
            sessionSnapshot.lastError = "UNKNOWN"
            bidInsightSnapshot.errorName = "UNKNOWN"
        }

        bidInsightSnapshot.status = "Failed"
        bidInsightSnapshot.errorCode = errorCode
        bidInsightSnapshot.errorMessage = message

        updateSessionUI()
        updateBidInsightsUI()
    }

    private func updateSDKVersionLabel() {
        mainViewRef.sdkVersionLabel.text = "SDK: \(formatSDKVersion(CloudXCore.shared.sdkVersion))"
    }

    private func updateStatus(_ status: Status) {
        mainViewRef.statusLabel.text = status.text
        mainViewRef.statusLabel.textColor = status.color
        mainViewRef.statusIndicator.backgroundColor = status.color
    }

    private func updateAdPlacementVisibility(format: AdFormat) {
        mainViewRef.adContainerBlock.isHidden = !format.isInline
    }

    private func updateAutoRefreshTimerMode(for format: AdFormat) {
        if format.isInline {
            mainViewRef.autoRefreshLabel.text = "Auto-refresh: waiting for ad load"
            mainViewRef.autoRefreshLineView.alpha = 1
            mainViewRef.autoRefreshLineView.setProgress(0)
        } else {
            mainViewRef.autoRefreshLabel.text = "Auto-refresh: not active for \(format.rawValue)"
            mainViewRef.autoRefreshLineView.alpha = 0.35
            stopAutoRefreshTimer(resetProgress: true)
        }
    }

    private func startAutoRefreshTimerFromSDKIfNeeded(for format: AdFormat) {
        guard format.isInline else {
            stopAutoRefreshTimer(resetProgress: true)
            return
        }

        let interval = resolvedBannerRefreshIntervalSecondsFromSDK()
        autoRefreshIntervalSeconds = interval
        mainViewRef.autoRefreshLabel.text = "Auto-refresh every \(formatAutoRefreshInterval(interval))"
        startAutoRefreshTimer(intervalSeconds: interval)
    }

    private func resolvedBannerRefreshIntervalSecondsFromSDK() -> TimeInterval {
        guard let bannerAd else {
            return EmulatorConstants.defaultBannerAutoRefreshSeconds
        }

        let bannerSelector = NSSelectorFromString("banner")
        guard bannerAd.responds(to: bannerSelector),
              let bannerValue = bannerAd.perform(bannerSelector)?.takeUnretainedValue() as? NSObject else {
            return EmulatorConstants.defaultBannerAutoRefreshSeconds
        }

        let refreshSelector = NSSelectorFromString("refreshSeconds")
        guard bannerValue.responds(to: refreshSelector),
              let method = bannerValue.method(for: refreshSelector) else {
            return EmulatorConstants.defaultBannerAutoRefreshSeconds
        }

        typealias RefreshGetter = @convention(c) (AnyObject, Selector) -> Double
        let refreshGetter = unsafeBitCast(method, to: RefreshGetter.self)
        let resolved = refreshGetter(bannerValue, refreshSelector)
        if resolved > 0 {
            return resolved
        }
        return EmulatorConstants.defaultBannerAutoRefreshSeconds
    }

    private func startAutoRefreshTimer(intervalSeconds: TimeInterval) {
        autoRefreshIntervalSeconds = max(intervalSeconds, 0.5)
        autoRefreshCycleStartedAt = CACurrentMediaTime()
        mainViewRef.autoRefreshLineView.setProgress(1)
        ensureAutoRefreshDisplayLink()
    }

    private func stopAutoRefreshTimer(resetProgress: Bool) {
        autoRefreshDisplayLink?.invalidate()
        autoRefreshDisplayLink = nil
        autoRefreshCycleStartedAt = nil
        if resetProgress {
            mainViewRef.autoRefreshLineView.setProgress(0)
        }
    }

    private func ensureAutoRefreshDisplayLink() {
        guard autoRefreshDisplayLink == nil else { return }
        let displayLink = CADisplayLink(target: self, selector: #selector(handleAutoRefreshDisplayTick))
        displayLink.add(to: .main, forMode: .common)
        autoRefreshDisplayLink = displayLink
    }

    @objc private func handleAutoRefreshDisplayTick() {
        guard let startedAt = autoRefreshCycleStartedAt else {
            stopAutoRefreshTimer(resetProgress: false)
            return
        }

        let elapsed = CACurrentMediaTime() - startedAt
        let progress = max(0, 1 - elapsed / autoRefreshIntervalSeconds)
        mainViewRef.autoRefreshLineView.setProgress(CGFloat(progress))

        if progress <= 0 {
            autoRefreshCycleStartedAt = nil
            stopAutoRefreshTimer(resetProgress: false)
        }
    }

    private func formatAutoRefreshInterval(_ interval: TimeInterval) -> String {
        let rounded = interval.rounded()
        if abs(interval - rounded) < 0.05 {
            return "\(Int(rounded))s"
        }
        return String(format: "%.1fs", interval)
    }

    @objc private func toggleOverridesExpanded() {
        overridesExpanded.toggle()
        updateOverridesUI()
    }

    private func updateOverridesUI() {
        let count = sessionSnapshot.overrides.count
        let suffix = "(\(count))"
        let toggleHint = overridesExpanded ? "tap to collapse" : "tap to expand"
        mainViewRef.overrideCountLabel.text = "Active Overrides \(suffix) \(toggleHint)"

        if sessionSnapshot.overrides.isEmpty {
            mainViewRef.overridesLabel.text = "No overrides set"
        } else {
            mainViewRef.overridesLabel.text = sessionSnapshot.overrides
                .sorted { $0.key < $1.key }
                .map { "\($0.key): \($0.value)" }
                .joined(separator: "\n")
        }

        mainViewRef.overridesLabel.isHidden = !overridesExpanded
    }

    private func updateSessionUI() {
        mainViewRef.adUnitChip.setTitle("ad_unit_id=\(sessionSnapshot.adUnitId ?? "n/a")", for: .normal)
        mainViewRef.formatChip.setTitle("format=\(sessionSnapshot.format ?? "n/a")", for: .normal)
        mainViewRef.envChip.setTitle("env=\(sessionSnapshot.env ?? "n/a")", for: .normal)
        mainViewRef.bundleChip.setTitle("bundle_id=\(sessionSnapshot.overrides["bundle_id"] ?? "n/a")", for: .normal)
        mainViewRef.appKeyChip.setTitle("app_key=\(mask(sessionSnapshot.appKey))", for: .normal)

        mainViewRef.summaryLabel.text = [
            "Attempts \(sessionSnapshot.attemptCount)",
            "Loaded \(sessionSnapshot.successCount)",
            "Displayed \(displayedCount)",
            "Failed \(sessionSnapshot.failureCount)",
            "Last error \(sessionSnapshot.lastError ?? "none")"
        ].joined(separator: "  ")
    }

    private func updateBidInsightsUI() {
        mainViewRef.bidStatusLabel.text = "Status: \(bidInsightSnapshot.status)"
        mainViewRef.bidWinnerLabel.text = "Winner: \(bidInsightSnapshot.winningNetwork ?? "n/a") (ad_unit=\(bidInsightSnapshot.networkPlacement ?? "n/a"))"
        mainViewRef.bidLatencyLabel.text = "Latency: \(bidInsightSnapshot.latencyMsApprox.map { "\($0)ms" } ?? "n/a")"

        if let errorName = bidInsightSnapshot.errorName {
            let codeText = bidInsightSnapshot.errorCode.map(String.init) ?? "n/a"
            let message = bidInsightSnapshot.errorMessage ?? ""
            mainViewRef.bidErrorLabel.text = "Last error: \(errorName) (\(codeText)) \(message)"
        } else {
            mainViewRef.bidErrorLabel.text = "Last error: none"
        }
    }

    private func renderFilteredEvents() {
        let events = timelineStore.filteredEvents()
        let stickToTop = isNearTop()
        let previous = renderedTimelineEvents
        let tableView = mainViewRef.timelineTableView
        timelineDataSource.submit(events)

        if tableView.window != nil {
            UIView.transition(with: tableView, duration: 0.2, options: .transitionCrossDissolve) {
                tableView.reloadData()
            }
        } else {
            tableView.reloadData()
        }

        renderedTimelineEvents = events

        if stickToTop, !events.isEmpty {
            let index = IndexPath(row: 0, section: 0)
            tableView.scrollToRow(at: index, at: .top, animated: false)
        }
    }

    private func shouldAnimateTopInsert(from previous: [EmulatorEvent], to current: [EmulatorEvent]) -> Bool {
        current.count == previous.count + 1 && current.dropFirst().elementsEqual(previous)
    }

    private func shouldAnimateTopInsertAndTrim(from previous: [EmulatorEvent], to current: [EmulatorEvent]) -> Bool {
        !previous.isEmpty &&
            current.count == previous.count &&
            current.dropFirst().elementsEqual(previous.dropLast())
    }

    private func shouldAnimateTopUpdate(from previous: [EmulatorEvent], to current: [EmulatorEvent]) -> Bool {
        guard current.count == previous.count, !current.isEmpty else {
            return false
        }

        guard current.first?.signature == previous.first?.signature else {
            return false
        }

        return current.first != previous.first && current.dropFirst().elementsEqual(previous.dropFirst())
    }

    private func isNearTop() -> Bool {
        guard let indices = mainViewRef.timelineTableView.indexPathsForVisibleRows, !indices.isEmpty else {
            return true
        }

        let firstVisible = indices.map(\.row).min() ?? 0
        return firstVisible <= 1
    }

    private func exportFilteredEventsText() -> String {
        timelineStore.filteredEvents().map { event in
            let details = event.details
                .sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: " ")
            return "\(event.timestampLabel) | \(event.severity.rawValue) | \(event.category.rawValue) | \(event.title) | \(details)"
        }.joined(separator: "\n")
    }

    private func copyFilteredEvents() {
        UIPasteboard.general.string = exportFilteredEventsText()
        showToast("Filtered events copied")
    }

    private func shareFilteredEvents() {
        let payload = exportFilteredEventsText()
        let activity = UIActivityViewController(activityItems: [payload], applicationActivities: nil)
        present(activity, animated: true)
    }

    private func copySessionValue(key: String, value: String?) {
        let normalized = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !normalized.isEmpty else {
            showToast("\(key) not available")
            return
        }

        UIPasteboard.general.string = normalized
        showToast("Copied \(key)")
    }

    private func toggleTimelineFullscreen() {
        isTimelineExpanded.toggle()

        if isTimelineExpanded {
            let controller = TimelineFullscreenViewController()
            controller.configure(
                events: timelineStore.filteredEvents(),
                activeFilter: timelineStore.activeFilter,
                exportText: exportFilteredEventsText()
            )
            controller.onDismiss = { [weak self] in
                self?.isTimelineExpanded = false
            }
            present(UINavigationController(rootViewController: controller), animated: true)
        }
    }

    private func showToast(_ text: String) {
        let toast = UILabel()
        toast.text = text
        toast.font = .systemFont(ofSize: 12, weight: .semibold)
        toast.textColor = .white
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        toast.layer.cornerRadius = 8
        toast.layer.masksToBounds = true
        toast.textAlignment = .center
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)

        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            toast.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            toast.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])

        UIView.animate(withDuration: 0.25, delay: 1.4, options: .curveEaseInOut) {
            toast.alpha = 0
        } completion: { _ in
            toast.removeFromSuperview()
        }
    }

    private func nowMs() -> Int64 {
        Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
    }

    private func runOnMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }

    private func mask(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "n/a" }
        guard value.count > 8 else { return value }
        return String(value.prefix(4)) + "..." + String(value.suffix(4))
    }

    private func formatSDKVersion(_ rawVersion: String) -> String {
        let regex = try? NSRegularExpression(pattern: "^\\d+(?:\\.\\d+)+")
        let range = NSRange(rawVersion.startIndex..<rawVersion.endIndex, in: rawVersion)
        guard let match = regex?.firstMatch(in: rawVersion, options: [], range: range),
              let resultRange = Range(match.range, in: rawVersion) else {
            return rawVersion
        }
        return String(rawVersion[resultRange])
    }

    private func errorName(for error: CLXError) -> String {
        guard let code = CLXErrorCode(rawValue: error.code) else { return "UNKNOWN" }
        return CLXError.name(for: code)
    }
}

extension EmulatorViewController: CLXBannerDelegate, CLXInterstitialDelegate, CLXRewardedDelegate, CLXAdRevenueDelegate {
    func didLoad(_ ad: CLXAd) {
        runOnMain { [weak self] in
            guard let self else { return }
            guard let request = self.currentRequest else { return }

            self.onAdLoadSucceeded()
            self.recordLoaded(ad: ad)

            EventLogger.log("ad_loaded", data: [
                "format": request.format.rawValue,
                "placement": request.adUnitId,
                "network": ad.networkName ?? "",
                "network_placement": ad.networkPlacement ?? ""
            ])
            self.updateStatus(.loaded)

            if request.format.isInline {
                self.startAutoRefreshTimerFromSDKIfNeeded(for: request.format)
            }

            if request.format.isInline, let bannerAd = self.bannerAd {
                self.attachAdViewCentered(bannerAd)
                EventLogger.log("ad_displayed", data: [
                    "format": request.format.rawValue,
                    "placement": request.adUnitId,
                    "network": ad.networkName ?? ""
                ])
                self.recordDisplayed()
                self.updateStatus(.displayed)
            } else {
                self.mainViewRef.showFullscreenButton.isEnabled = true
            }
        }
    }

    func didFailToLoadAd(_ adUnitId: String, error: CLXError) {
        runOnMain { [weak self] in
            guard let self else { return }
            guard let request = self.currentRequest else { return }

            self.startAutoRefreshTimerFromSDKIfNeeded(for: request.format)

            self.recordFailure(message: error.localizedDescription, errorCode: error.code)
            EventLogger.log("ad_load_failed", data: [
                "format": request.format.rawValue,
                "placement": request.adUnitId,
                "error": error.localizedDescription,
                "error_code": error.code,
                "error_name": self.errorName(for: error)
            ])

            let retryScheduled = self.maybeScheduleFirstLoadRetry(for: request, error: error)
            if retryScheduled {
                self.updateStatus(.loading)
            } else {
                self.updateStatus(.error(message: error.localizedDescription))
            }
        }
    }

    func didClick(_ ad: CLXAd) {
        runOnMain { [weak self] in
            guard let self else { return }
            guard let request = self.currentRequest else { return }

            EventLogger.log("ad_clicked", data: [
                "format": request.format.rawValue,
                "placement": request.adUnitId,
                "network": ad.networkName ?? ""
            ])
            self.updateStatus(.clicked)
        }
    }

    func didExpand(_ ad: CLXAd) {}

    func didCollapse(_ ad: CLXAd) {}

    func didDisplay(_ ad: CLXAd) {
        runOnMain { [weak self] in
            guard let self else { return }
            guard let request = self.currentRequest else { return }

            EventLogger.log("ad_displayed", data: [
                "format": request.format.rawValue,
                "placement": request.adUnitId,
                "network": ad.networkName ?? ""
            ])
            self.recordDisplayed()
            self.updateStatus(.displayed)
        }
    }

    func didFailToDisplay(_ ad: CLXAd, error: CLXError) {
        runOnMain { [weak self] in
            guard let self else { return }
            guard let request = self.currentRequest else { return }

            self.recordFailure(message: error.localizedDescription, errorCode: error.code)
            EventLogger.log("ad_display_failed", data: [
                "format": request.format.rawValue,
                "placement": request.adUnitId,
                "error": error.localizedDescription,
                "error_code": error.code,
                "error_name": self.errorName(for: error)
            ])
            self.updateStatus(.error(message: error.localizedDescription))
        }
    }

    func didHide(_ ad: CLXAd) {
        runOnMain { [weak self] in
            guard let self else { return }
            guard let request = self.currentRequest else { return }

            EventLogger.log("ad_closed", data: [
                "format": request.format.rawValue,
                "placement": request.adUnitId
            ])
            self.updateStatus(.closed)
            self.mainViewRef.showFullscreenButton.isEnabled = false
        }
    }

    func didRewardUser(for ad: CLXAd, with reward: CLXReward) {
        runOnMain { [weak self] in
            guard let self else { return }
            guard let request = self.currentRequest else { return }
            EventLogger.adRewarded(
                format: request.format.rawValue,
                placement: request.adUnitId,
                rewardType: reward.label,
                rewardAmount: Int(reward.amount)
            )
        }
    }

    func didPayRevenue(for ad: CLXAd) {
        runOnMain { [weak self] in
            guard let self else { return }
            guard let request = self.currentRequest else { return }

            self.bidInsightSnapshot.revenueUsd = ad.revenue?.doubleValue
            self.updateBidInsightsUI()

            EventLogger.log("ad_revenue_paid", data: [
                "placement": request.adUnitId,
                "network": ad.networkName ?? "",
                "revenue_usd": ad.revenue?.doubleValue ?? 0
            ])
        }
    }
}

private final class TimelineFullscreenViewController: UIViewController {
    private let textView = UITextView()
    private var exportText = ""
    private var events: [EmulatorEvent] = []
    private var activeFilter: EventFilter = .all

    var onDismiss: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = "Event Timeline"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(close)
        )

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = .label
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let header = "Filter: \(activeFilter.title)\nEvents: \(events.count)\n\n"
        textView.text = header + exportText
    }

    func configure(events: [EmulatorEvent], activeFilter: EventFilter, exportText: String) {
        self.events = events
        self.activeFilter = activeFilter
        self.exportText = exportText
    }

    @objc private func close() {
        dismiss(animated: true) { [weak self] in
            self?.onDismiss?()
        }
    }
}

private extension UIColor {
    static let primary = UIColor.systemBlue
    static let primaryLight = UIColor.systemBlue.withAlphaComponent(0.65)
    static let background = UIColor.systemGroupedBackground
    static let surface = UIColor.secondarySystemGroupedBackground
    static let surfaceVariant = UIColor.tertiarySystemGroupedBackground
    static let divider = UIColor.separator
    static let textPrimary = UIColor.label
    static let textSecondary = UIColor.secondaryLabel
    static let textOnPrimary = UIColor.white

    static let statusSuccess = UIColor.systemGreen
    static let statusError = UIColor.systemRed
    static let statusWarning = UIColor.systemOrange
    static let statusInfo = UIColor.systemBlue

    static let adContainerBackground = UIColor.tertiarySystemGroupedBackground
    static let adContainerBorder = UIColor.separator.withAlphaComponent(0.6)

    convenience init(hex: Int) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
