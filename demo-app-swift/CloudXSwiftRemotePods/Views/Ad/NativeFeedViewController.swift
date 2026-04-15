import UIKit
import CloudXCore

private let kAdCount = 10

private enum NativeAdCreativeType {
    case unknown, image, videoLandscape, videoPortrait

    var badgeText: String {
        switch self {
        case .unknown: return "UNKNOWN"
        case .image: return "IMAGE"
        case .videoLandscape: return "VIDEO 16:9"
        case .videoPortrait: return "REELS 9:16"
        }
    }

    var badgeColor: UIColor {
        switch self {
        case .unknown: return .systemGray
        case .image: return .systemBlue
        case .videoLandscape: return .systemOrange
        case .videoPortrait: return .systemPurple
        }
    }
}

private class NativeAdFeedItem {
    let loader: CLXNativeAdLoader
    var adView: CLXNativeAdView?
    var ad: CLXAd?
    var creativeType: NativeAdCreativeType = .unknown
    var isLoading = false
    var isLoaded = false
    var isFailed = false

    init(loader: CLXNativeAdLoader) {
        self.loader = loader
    }
}

class NativeFeedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
                                 CLXNativeAdDelegate, CLXAdRevenueDelegate {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var feedItems: [NativeAdFeedItem] = []
    private var nextLoadIndex = 0
    private let settings = UserDefaultsSettings.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Native Feed"
        view.backgroundColor = .systemBackground
        setupTableView()
        setupAppLogsButton()
        createFeedItems()
        loadNextAd()
    }

    deinit {
        feedItems.forEach { $0.loader.destroy() }
    }

    // MARK: - Setup

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "NativeAdCell")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupAppLogsButton() {
        let logsButton = UIButton(type: .system)
        logsButton.setTitle("App Logs", for: .normal)
        logsButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        logsButton.backgroundColor = .systemOrange
        logsButton.setTitleColor(.white, for: .normal)
        logsButton.layer.cornerRadius = 6
        logsButton.translatesAutoresizingMaskIntoConstraints = false
        logsButton.addTarget(self, action: #selector(showLogsModal), for: .touchUpInside)
        view.addSubview(logsButton)

        NSLayoutConstraint.activate([
            logsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            logsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            logsButton.widthAnchor.constraint(equalToConstant: 90),
            logsButton.heightAnchor.constraint(equalToConstant: 30),
        ])
    }

    @objc private func showLogsModal() {
        let logsModal = LogsModalViewController(title: "Logs")
        present(logsModal, animated: true)
    }

    private var adUnitId: String {
        let id = CLXDemoConfigManager.sharedManager.currentConfig.nativeAdUnitId
        return settings.nativeMediumAdUnitId.isEmpty ? id : settings.nativeMediumAdUnitId
    }

    private func createFeedItems() {
        for i in 0..<kAdCount {
            let loader = CloudXCore.shared.createNativeAdLoader(adUnitIdentifier: adUnitId)
            loader.nativeAdDelegate = self
            loader.revenueDelegate = self
            loader.placement = "feed_slot_\(i)"
            feedItems.append(NativeAdFeedItem(loader: loader))
        }
    }

    // MARK: - Sequential Loading

    private func loadNextAd() {
        guard nextLoadIndex < kAdCount else { return }
        let item = feedItems[nextLoadIndex]
        item.isLoading = true
        item.loader.loadAd()
    }

    // MARK: - Creative Type Detection

    private func detectCreativeType(from ad: CLXAd) -> NativeAdCreativeType {
        guard let nativeAd = ad.nativeAd else { return .unknown }

        if nativeAd.isVideoContent {
            let ar = nativeAd.mediaContentAspectRatio
            return ar < 1.0 ? .videoPortrait : .videoLandscape
        }

        return nativeAd.mediaContentAspectRatio > 0 ? .image : .unknown
    }

    // MARK: - CLXNativeAdDelegate

    func didLoadNativeAd(_ nativeAdView: CLXNativeAdView?, for ad: CLXAd) {
        let idx = nextLoadIndex
        guard idx < kAdCount else { return }

        let item = feedItems[idx]
        item.isLoading = false
        item.isLoaded = true
        item.ad = ad

        if let view = nativeAdView {
            item.adView = view
        } else if let nativeAd = ad.nativeAd {
            let templateView = CLXNativeAdView(from: nativeAd)
            item.loader.renderNativeAdView(templateView, with: ad)
            item.adView = templateView
        }

        item.creativeType = detectCreativeType(from: ad)
        DemoAppLogger.sharedInstance.logMessage("✅ Feed slot \(idx) loaded: \(item.creativeType.badgeText)")

        tableView.reloadRows(at: [IndexPath(row: idx, section: 0)], with: .fade)

        nextLoadIndex += 1
        loadNextAd()
    }

    func didFailToLoadNativeAd(forAdUnitIdentifier adUnitId: String, error: CLXError) {
        let idx = nextLoadIndex
        guard idx < kAdCount else { return }

        let item = feedItems[idx]
        item.isLoading = false
        item.isFailed = true

        DemoAppLogger.sharedInstance.logMessage("❌ Feed slot \(idx) failed: \(error.localizedDescription)")

        tableView.reloadRows(at: [IndexPath(row: idx, section: 0)], with: .fade)

        nextLoadIndex += 1
        loadNextAd()
    }

    func didClickNativeAd(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👆 Feed didClickNativeAd", ad: ad)
    }

    func didExpireNativeAd(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("⏰ Feed didExpireNativeAd", ad: ad)
    }

    // MARK: - CLXAdRevenueDelegate

    func didPayRevenue(for ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("💰 Feed didPayRevenueForAd", ad: ad)
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { kAdCount }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NativeAdCell", for: indexPath)
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let item = feedItems[indexPath.row]

        if item.isLoaded, let adView = item.adView {
            adView.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(adView)
            NSLayoutConstraint.activate([
                adView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                adView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 12),
                adView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -12),
                adView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
            ])

            let badge = UILabel()
            badge.text = " \(item.creativeType.badgeText) "
            badge.font = .boldSystemFont(ofSize: 11)
            badge.textColor = .white
            badge.backgroundColor = item.creativeType.badgeColor
            badge.layer.cornerRadius = 4
            badge.clipsToBounds = true
            badge.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(badge)

            let slotLabel = UILabel()
            slotLabel.text = "Slot \(indexPath.row)"
            slotLabel.font = .monospacedSystemFont(ofSize: 10, weight: .medium)
            slotLabel.textColor = .tertiaryLabel
            slotLabel.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(slotLabel)

            NSLayoutConstraint.activate([
                badge.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 14),
                badge.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -18),
                slotLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 14),
                slotLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 18),
            ])
        } else if item.isFailed {
            let errorLabel = UILabel()
            errorLabel.text = "Slot \(indexPath.row) — Load Failed"
            errorLabel.textColor = .systemRed
            errorLabel.font = .preferredFont(forTextStyle: .subheadline)
            errorLabel.textAlignment = .center
            errorLabel.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(errorLabel)
            NSLayoutConstraint.activate([
                errorLabel.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
                errorLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            ])
        } else {
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.translatesAutoresizingMaskIntoConstraints = false
            spinner.startAnimating()
            cell.contentView.addSubview(spinner)

            let loadingLabel = UILabel()
            loadingLabel.text = "Slot \(indexPath.row) — Loading..."
            loadingLabel.textColor = .secondaryLabel
            loadingLabel.font = .preferredFont(forTextStyle: .subheadline)
            loadingLabel.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(loadingLabel)

            NSLayoutConstraint.activate([
                spinner.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                spinner.trailingAnchor.constraint(equalTo: loadingLabel.leadingAnchor, constant: -8),
                loadingLabel.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor, constant: 12),
                loadingLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            ])
        }

        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = feedItems[indexPath.row]
        if item.isLoaded {
            return item.creativeType == .videoPortrait ? 600 : 400
        }
        return 80
    }
}
