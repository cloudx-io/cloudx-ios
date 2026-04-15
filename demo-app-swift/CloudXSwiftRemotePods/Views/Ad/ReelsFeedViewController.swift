import UIKit
import CloudXCore

private let kReelsAdCount = 5

private class ReelsAdItem {
    var loader: CLXNativeAdLoader?
    var ad: CLXAd?
    var nativeAd: CLXNativeAd?
    var isLoading = false
    var isLoaded = false
    var isFailed = false
    var hideControls = false
    var isImagePlaceholder = false

    init(loader: CLXNativeAdLoader?) {
        self.loader = loader
    }
}

// MARK: - ReelsCell

private class ReelsCell: UICollectionViewCell {
    let nativeAdView = CLXNativeAdView()
    let mediaContainer = UIView()
    let gradientContainer = UIView()
    let reelsTitleLabel = UILabel()
    let reelsBodyLabel = UILabel()
    let reelsAdvertiserLabel = UILabel()
    let ctaButton = UIButton(type: .system)
    let optionsContainer = UIView()
    let iconContainer = UIView()
    let reelsIconImageView = UIImageView()
    let spinner = UIActivityIndicatorView(style: .large)
    let slotLabel = UILabel()
    let videoBadge = UILabel()
    let durationLabel = UILabel()
    let placeholderImageView = UIImageView()
    private var gradient: CAGradientLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .black
        contentView.clipsToBounds = true
        buildSubviews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildSubviews() {
        nativeAdView.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.backgroundColor = .clear
        contentView.addSubview(nativeAdView)

        mediaContainer.translatesAutoresizingMaskIntoConstraints = false
        mediaContainer.clipsToBounds = true
        nativeAdView.addSubview(mediaContainer)

        gradientContainer.translatesAutoresizingMaskIntoConstraints = false
        gradientContainer.isUserInteractionEnabled = false
        nativeAdView.addSubview(gradientContainer)

        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.clipsToBounds = true
        iconContainer.layer.cornerRadius = 20
        nativeAdView.addSubview(iconContainer)

        reelsIconImageView.contentMode = .scaleAspectFill
        reelsIconImageView.clipsToBounds = true
        reelsIconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(reelsIconImageView)

        reelsTitleLabel.font = .boldSystemFont(ofSize: 17)
        reelsTitleLabel.textColor = .white
        reelsTitleLabel.numberOfLines = 2
        reelsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(reelsTitleLabel)

        reelsAdvertiserLabel.font = .systemFont(ofSize: 13)
        reelsAdvertiserLabel.textColor = UIColor(white: 1.0, alpha: 0.7)
        reelsAdvertiserLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(reelsAdvertiserLabel)

        reelsBodyLabel.font = .systemFont(ofSize: 14)
        reelsBodyLabel.textColor = UIColor(white: 1.0, alpha: 0.9)
        reelsBodyLabel.numberOfLines = 2
        reelsBodyLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(reelsBodyLabel)

        ctaButton.titleLabel?.font = .boldSystemFont(ofSize: 15)
        ctaButton.backgroundColor = .white
        ctaButton.setTitleColor(.black, for: .normal)
        ctaButton.layer.cornerRadius = 22
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(ctaButton)

        optionsContainer.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(optionsContainer)

        spinner.color = .white
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        nativeAdView.addSubview(spinner)

        slotLabel.font = .monospacedSystemFont(ofSize: 11, weight: .medium)
        slotLabel.textColor = UIColor(white: 1.0, alpha: 0.5)
        slotLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(slotLabel)

        videoBadge.font = .monospacedSystemFont(ofSize: 10, weight: .bold)
        videoBadge.textColor = .white
        videoBadge.textAlignment = .center
        videoBadge.layer.cornerRadius = 4
        videoBadge.clipsToBounds = true
        videoBadge.translatesAutoresizingMaskIntoConstraints = false
        videoBadge.isHidden = true
        nativeAdView.addSubview(videoBadge)

        durationLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
        durationLabel.textColor = .white
        durationLabel.textAlignment = .center
        durationLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        durationLabel.layer.cornerRadius = 4
        durationLabel.clipsToBounds = true
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.isHidden = true
        nativeAdView.addSubview(durationLabel)

        placeholderImageView.contentMode = .scaleAspectFill
        placeholderImageView.clipsToBounds = true
        placeholderImageView.translatesAutoresizingMaskIntoConstraints = false
        placeholderImageView.isHidden = true
        nativeAdView.insertSubview(placeholderImageView, aboveSubview: mediaContainer)

        nativeAdView.mediaContentView = mediaContainer
        nativeAdView.callToActionButton = ctaButton
        nativeAdView.titleLabel = reelsTitleLabel
        nativeAdView.bodyLabel = reelsBodyLabel
        nativeAdView.advertiserLabel = reelsAdvertiserLabel
        nativeAdView.optionsContentView = optionsContainer
        nativeAdView.iconContentView = iconContainer
        nativeAdView.iconImageView = reelsIconImageView

        let pad: CGFloat = 16
        NSLayoutConstraint.activate([
            nativeAdView.topAnchor.constraint(equalTo: contentView.topAnchor),
            nativeAdView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nativeAdView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            nativeAdView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            mediaContainer.topAnchor.constraint(equalTo: nativeAdView.topAnchor),
            mediaContainer.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor),
            mediaContainer.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor),
            mediaContainer.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor),

            gradientContainer.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor),
            gradientContainer.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor),
            gradientContainer.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor),
            gradientContainer.heightAnchor.constraint(equalToConstant: 280),

            ctaButton.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: pad),
            ctaButton.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -pad),
            ctaButton.bottomAnchor.constraint(equalTo: nativeAdView.safeAreaLayoutGuide.bottomAnchor, constant: -pad),
            ctaButton.heightAnchor.constraint(equalToConstant: 44),

            reelsBodyLabel.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: pad),
            reelsBodyLabel.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -pad),
            reelsBodyLabel.bottomAnchor.constraint(equalTo: ctaButton.topAnchor, constant: -12),

            iconContainer.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: pad),
            iconContainer.widthAnchor.constraint(equalToConstant: 40),
            iconContainer.heightAnchor.constraint(equalToConstant: 40),
            iconContainer.bottomAnchor.constraint(equalTo: reelsBodyLabel.topAnchor, constant: -10),

            reelsIconImageView.topAnchor.constraint(equalTo: iconContainer.topAnchor),
            reelsIconImageView.leadingAnchor.constraint(equalTo: iconContainer.leadingAnchor),
            reelsIconImageView.trailingAnchor.constraint(equalTo: iconContainer.trailingAnchor),
            reelsIconImageView.bottomAnchor.constraint(equalTo: iconContainer.bottomAnchor),

            reelsTitleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 10),
            reelsTitleLabel.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -pad),
            reelsTitleLabel.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor, constant: -8),

            reelsAdvertiserLabel.leadingAnchor.constraint(equalTo: reelsTitleLabel.leadingAnchor),
            reelsAdvertiserLabel.trailingAnchor.constraint(equalTo: reelsTitleLabel.trailingAnchor),
            reelsAdvertiserLabel.topAnchor.constraint(equalTo: reelsTitleLabel.bottomAnchor, constant: 2),

            optionsContainer.topAnchor.constraint(equalTo: nativeAdView.safeAreaLayoutGuide.topAnchor, constant: 8),
            optionsContainer.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -pad),
            optionsContainer.widthAnchor.constraint(equalToConstant: 30),
            optionsContainer.heightAnchor.constraint(equalToConstant: 30),

            spinner.centerXAnchor.constraint(equalTo: nativeAdView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: nativeAdView.centerYAnchor),

            slotLabel.topAnchor.constraint(equalTo: nativeAdView.safeAreaLayoutGuide.topAnchor, constant: 8),
            slotLabel.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: pad),

            videoBadge.leadingAnchor.constraint(equalTo: slotLabel.trailingAnchor, constant: 8),
            videoBadge.centerYAnchor.constraint(equalTo: slotLabel.centerYAnchor),
            videoBadge.heightAnchor.constraint(equalToConstant: 18),

            durationLabel.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -pad),
            durationLabel.bottomAnchor.constraint(equalTo: iconContainer.topAnchor, constant: -16),
            durationLabel.heightAnchor.constraint(equalToConstant: 24),

            placeholderImageView.topAnchor.constraint(equalTo: nativeAdView.topAnchor),
            placeholderImageView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor),
            placeholderImageView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor),
            placeholderImageView.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if gradient == nil {
            let g = CAGradientLayer()
            g.colors = [UIColor.clear.cgColor, UIColor(white: 0, alpha: 0.8).cgColor]
            g.locations = [0.0, 1.0]
            gradientContainer.layer.insertSublayer(g, at: 0)
            gradient = g
        }
        gradient?.frame = gradientContainer.bounds
    }

    func configure(with item: ReelsAdItem, at index: Int) {
        slotLabel.text = "\(index + 1) / \(kReelsAdCount)"

        if item.isImagePlaceholder {
            spinner.stopAnimating()
            placeholderImageView.isHidden = false
            placeholderImageView.image = UIImage(systemName: "photo.artframe")
            placeholderImageView.tintColor = UIColor(white: 1.0, alpha: 0.15)
            placeholderImageView.contentMode = .scaleAspectFit
            mediaContainer.isHidden = true
            setOverlayVisible(true)
            reelsTitleLabel.text = "Sample Static Ad"
            reelsBodyLabel.text = "This reel demonstrates the IMAGE badge path"
            reelsAdvertiserLabel.text = "Demo Advertiser"
            ctaButton.setTitle("Learn More", for: .normal)
            videoBadge.isHidden = false
            videoBadge.text = " IMAGE "
            videoBadge.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.7)
            durationLabel.isHidden = true
        } else if item.isLoaded, let nativeAd = item.nativeAd {
            spinner.stopAnimating()
            placeholderImageView.isHidden = true
            mediaContainer.isHidden = false
            setOverlayVisible(!item.hideControls)
            updateVideoBadge(with: nativeAd)
        } else if item.isFailed {
            spinner.stopAnimating()
            placeholderImageView.isHidden = true
            mediaContainer.isHidden = false
            setOverlayVisible(false)
            reelsTitleLabel.text = "Load Failed"
            reelsTitleLabel.isHidden = false
            reelsBodyLabel.isHidden = true
            videoBadge.isHidden = true
            durationLabel.isHidden = true
        } else {
            spinner.startAnimating()
            placeholderImageView.isHidden = true
            mediaContainer.isHidden = false
            setOverlayVisible(false)
            videoBadge.isHidden = true
            durationLabel.isHidden = true
        }
    }

    private func updateVideoBadge(with nativeAd: CLXNativeAd) {
        videoBadge.isHidden = false
        if nativeAd.isVideoContent {
            videoBadge.text = " VIDEO "
            videoBadge.backgroundColor = UIColor.systemRed.withAlphaComponent(0.85)

            if nativeAd.videoDuration > 0 {
                let totalSeconds = Int(nativeAd.videoDuration)
                let minutes = totalSeconds / 60
                let seconds = totalSeconds % 60
                durationLabel.text = " \(minutes):\(String(format: "%02d", seconds)) "
                durationLabel.isHidden = false
            } else {
                durationLabel.isHidden = true
            }
        } else {
            videoBadge.text = " STATIC "
            videoBadge.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.7)
            durationLabel.isHidden = true
        }
    }

    private func setOverlayVisible(_ visible: Bool) {
        reelsTitleLabel.isHidden = !visible
        reelsAdvertiserLabel.isHidden = !visible
        reelsBodyLabel.isHidden = !visible
        ctaButton.isHidden = !visible
        gradientContainer.isHidden = !visible
        iconContainer.isHidden = !visible
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        spinner.stopAnimating()
        nativeAdView.prepareForReuse()
        placeholderImageView.isHidden = true
        placeholderImageView.image = nil
        mediaContainer.isHidden = false
        iconContainer.addSubview(reelsIconImageView)
        reelsIconImageView.image = nil
        videoBadge.isHidden = true
        durationLabel.isHidden = true
    }
}

// MARK: - ReelsFeedViewController

class ReelsFeedViewController: UIViewController, UICollectionViewDataSource,
                                UICollectionViewDelegateFlowLayout,
                                CLXNativeAdDelegate, CLXAdRevenueDelegate {

    private var collectionView: UICollectionView!
    private var items: [ReelsAdItem] = []
    private var nextLoadIndex = 0
    private let settings = UserDefaultsSettings.shared
    private var settingsPanel: UIView!
    private var fullScreenSwitch: UISwitch!
    private var unmutedSwitch: UISwitch!
    private var hideControlsSwitch: UISwitch!
    private var settingsPanelVisible = false
    private var gearButton: UIButton!
    private var settingsBadgesStack: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Reels Feed"
        view.backgroundColor = .black
        setupCollectionView()
        setupAppLogsButton()
        setupSettingsPanel()
        createItems()
        loadNextAd()
    }

    deinit {
        items.forEach { $0.loader?.destroy() }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - Setup

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .black
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.register(ReelsCell.self, forCellWithReuseIdentifier: "ReelsCell")
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupAppLogsButton() {
        let logsButton = UIButton(type: .system)
        logsButton.setTitle("App Logs", for: .normal)
        logsButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        logsButton.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.9)
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

    private func setupSettingsPanel() {
        gearButton = UIButton(type: .system)
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        let gearIcon = UIImage(systemName: "slider.horizontal.3", withConfiguration: iconConfig)
        gearButton.setImage(gearIcon, for: .normal)
        gearButton.setTitle(" Video Config", for: .normal)
        gearButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        gearButton.tintColor = .white
        gearButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        gearButton.layer.cornerRadius = 14
        gearButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 12)
        gearButton.translatesAutoresizingMaskIntoConstraints = false
        gearButton.addTarget(self, action: #selector(toggleSettingsPanel), for: .touchUpInside)
        view.addSubview(gearButton)

        settingsBadgesStack = UIStackView()
        settingsBadgesStack.axis = .horizontal
        settingsBadgesStack.spacing = 4
        settingsBadgesStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(settingsBadgesStack)

        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.layer.cornerRadius = 12
        blurView.clipsToBounds = true
        blurView.translatesAutoresizingMaskIntoConstraints = false

        settingsPanel = UIView()
        settingsPanel.translatesAutoresizingMaskIntoConstraints = false
        settingsPanel.alpha = 0
        settingsPanel.isHidden = true
        view.addSubview(settingsPanel)

        settingsPanel.addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: settingsPanel.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: settingsPanel.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: settingsPanel.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: settingsPanel.bottomAnchor),
        ])

        let header = UILabel()
        header.text = "Video Config"
        header.font = .boldSystemFont(ofSize: 14)
        header.textColor = .white

        fullScreenSwitch = UISwitch()
        fullScreenSwitch.isOn = true
        fullScreenSwitch.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)

        unmutedSwitch = UISwitch()
        unmutedSwitch.isOn = true
        unmutedSwitch.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)

        hideControlsSwitch = UISwitch()
        hideControlsSwitch.isOn = true
        hideControlsSwitch.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)

        let row1 = settingsRow(label: "Disable Fullscreen", toggle: fullScreenSwitch)
        let row2 = settingsRow(label: "Start Unmuted", toggle: unmutedSwitch)
        let row3 = settingsRow(label: "Hide Controls", toggle: hideControlsSwitch)

        let reloadButton = UIButton(type: .system)
        reloadButton.setTitle("Reload Ads", for: .normal)
        reloadButton.titleLabel?.font = .boldSystemFont(ofSize: 13)
        reloadButton.backgroundColor = .systemBlue
        reloadButton.setTitleColor(.white, for: .normal)
        reloadButton.layer.cornerRadius = 8
        reloadButton.translatesAutoresizingMaskIntoConstraints = false
        reloadButton.addTarget(self, action: #selector(reloadAdsWithSettings), for: .touchUpInside)
        reloadButton.heightAnchor.constraint(equalToConstant: 32).isActive = true

        let disclaimer = UILabel()
        disclaimer.text = "Requires FAN SDK 6.21.1+ for Meta native ads"
        disclaimer.font = .italicSystemFont(ofSize: 9)
        disclaimer.textColor = UIColor(white: 1.0, alpha: 0.45)
        disclaimer.numberOfLines = 0
        disclaimer.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [header, row1, row2, row3, reloadButton, disclaimer])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        settingsPanel.addSubview(stack)

        NSLayoutConstraint.activate([
            gearButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44),
            gearButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            gearButton.heightAnchor.constraint(equalToConstant: 28),

            settingsBadgesStack.topAnchor.constraint(equalTo: gearButton.bottomAnchor, constant: 6),
            settingsBadgesStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            settingsPanel.topAnchor.constraint(equalTo: settingsBadgesStack.bottomAnchor, constant: 6),
            settingsPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            settingsPanel.widthAnchor.constraint(equalToConstant: 220),

            stack.topAnchor.constraint(equalTo: settingsPanel.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: settingsPanel.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: settingsPanel.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: settingsPanel.bottomAnchor, constant: -12),
        ])

        updateSettingsBadges()
    }

    private func settingsRow(label text: String, toggle: UISwitch) -> UIStackView {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(white: 1.0, alpha: 0.9)
        let row = UIStackView(arrangedSubviews: [label, toggle])
        row.axis = .horizontal
        row.alignment = .center
        row.distribution = .equalSpacing
        return row
    }

    private func updateSettingsBadges() {
        settingsBadgesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let disableFS = fullScreenSwitch?.isOn ?? true
        let unmuted   = unmutedSwitch?.isOn ?? true
        let hideCtrl  = hideControlsSwitch?.isOn ?? true

        if disableFS  { settingsBadgesStack.addArrangedSubview(makeBadge(text: "No FS", color: .systemPurple)) }
        if unmuted    { settingsBadgesStack.addArrangedSubview(makeBadge(text: "Unmuted", color: .systemGreen)) }
        if hideCtrl   { settingsBadgesStack.addArrangedSubview(makeBadge(text: "No Ctrl", color: .systemOrange)) }
    }

    private func makeBadge(text: String, color: UIColor) -> UILabel {
        let badge = UILabel()
        badge.text = "  \(text)  "
        badge.font = .systemFont(ofSize: 9, weight: .bold)
        badge.textColor = .white
        badge.backgroundColor = color.withAlphaComponent(0.8)
        badge.layer.cornerRadius = 8
        badge.clipsToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.heightAnchor.constraint(equalToConstant: 16).isActive = true
        return badge
    }

    @objc private func toggleSettingsPanel() {
        settingsPanelVisible.toggle()
        if settingsPanelVisible {
            settingsPanel.isHidden = false
            UIView.animate(withDuration: 0.25) { self.settingsPanel.alpha = 1.0 }
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                self.settingsPanel.alpha = 0
            }, completion: { _ in self.settingsPanel.isHidden = true })
        }
    }

    @objc private func reloadAdsWithSettings() {
        items.forEach { $0.loader?.destroy() }
        items.removeAll()
        nextLoadIndex = 0

        let hideCtrl = hideControlsSwitch.isOn
        for i in 0..<kReelsAdCount {
            if i % 2 == 1 {
                let item = ReelsAdItem(loader: nil)
                item.isImagePlaceholder = true
                item.isLoaded = true
                items.append(item)
            } else {
                let loader = CloudXCore.shared.createNativeAdLoader(adUnitIdentifier: adUnitId)
                loader.nativeAdDelegate = self
                loader.revenueDelegate = self
                loader.placement = "reels_slot_\(i)"
                loader.disableVideoFullScreen = fullScreenSwitch.isOn
                loader.startVideoUnmuted = unmutedSwitch.isOn
                loader.hideVideoMediaControls = hideCtrl
                let item = ReelsAdItem(loader: loader)
                item.hideControls = hideCtrl
                items.append(item)
            }
        }

        collectionView.reloadData()
        loadNextAd()
        toggleSettingsPanel()
        updateSettingsBadges()

        DemoAppLogger.sharedInstance.logMessage("🔄 Reels reloading with: fullscreen=\(fullScreenSwitch.isOn ? "OFF" : "ON"), unmuted=\(unmutedSwitch.isOn ? "YES" : "NO"), hideControls=\(hideControlsSwitch.isOn ? "YES" : "NO")")
    }

    private var adUnitId: String {
        let id = CLXDemoConfigManager.sharedManager.currentConfig.nativeAdUnitId
        return settings.nativeMediumAdUnitId.isEmpty ? id : settings.nativeMediumAdUnitId
    }

    private func createItems() {
        let disableFS = fullScreenSwitch?.isOn ?? true
        let unmuted = unmutedSwitch?.isOn ?? true
        let hideCtrl = hideControlsSwitch?.isOn ?? true

        for i in 0..<kReelsAdCount {
            if i % 2 == 1 {
                let item = ReelsAdItem(loader: nil)
                item.isImagePlaceholder = true
                item.isLoaded = true
                items.append(item)
            } else {
                let loader = CloudXCore.shared.createNativeAdLoader(adUnitIdentifier: adUnitId)
                loader.nativeAdDelegate = self
                loader.revenueDelegate = self
                loader.placement = "reels_slot_\(i)"
                loader.disableVideoFullScreen = disableFS
                loader.startVideoUnmuted = unmuted
                loader.hideVideoMediaControls = hideCtrl
                let item = ReelsAdItem(loader: loader)
                item.hideControls = hideCtrl
                items.append(item)
            }
        }
    }

    // MARK: - Sequential Loading

    private func loadNextAd() {
        while nextLoadIndex < kReelsAdCount && items[nextLoadIndex].isImagePlaceholder {
            nextLoadIndex += 1
        }
        guard nextLoadIndex < kReelsAdCount else { return }
        let item = items[nextLoadIndex]
        item.isLoading = true
        item.loader?.loadAd()
    }

    // MARK: - CLXNativeAdDelegate

    func didLoadNativeAd(_ nativeAdView: CLXNativeAdView?, for ad: CLXAd) {
        let idx = nextLoadIndex
        guard idx < kReelsAdCount else { return }

        let item = items[idx]
        item.isLoading = false
        item.isLoaded = true
        item.ad = ad
        item.nativeAd = ad.nativeAd

        let creativeType = ad.nativeAd?.isVideoContent == true ? "video" : "static"
        let duration = ad.nativeAd?.videoDuration ?? 0
        DemoAppLogger.sharedInstance.logAdEvent("✅ Reels didLoadNativeAd (slot \(idx), \(creativeType), duration=\(String(format: "%.1f", duration))s)", ad: ad)
        collectionView.reloadItems(at: [IndexPath(item: idx, section: 0)])

        nextLoadIndex += 1
        loadNextAd()
    }

    func didFailToLoadNativeAd(forAdUnitIdentifier adUnitId: String, error: CLXError) {
        let idx = nextLoadIndex
        guard idx < kReelsAdCount else { return }

        let item = items[idx]
        item.isLoading = false
        item.isFailed = true

        DemoAppLogger.sharedInstance.logMessage("❌ Reels didFailToLoadNativeAd (slot \(idx)): \(error.localizedDescription)")
        collectionView.reloadItems(at: [IndexPath(item: idx, section: 0)])

        nextLoadIndex += 1
        loadNextAd()
    }

    func didClickNativeAd(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("👆 Reels didClickNativeAd", ad: ad)
    }

    func didExpireNativeAd(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("⏰ Reels didExpireNativeAd", ad: ad)
    }

    func didCloseNativeAd(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("🚪 Reels didCloseNativeAd — user reported/hid ad via AdChoices", ad: ad)

        let closedIdx = items.firstIndex(where: { $0.ad === ad })
        showDismissToast()

        if let idx = closedIdx, idx + 1 < kReelsAdCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                guard let self else { return }
                let next = IndexPath(item: idx + 1, section: 0)
                self.collectionView.scrollToItem(at: next, at: .centeredVertically, animated: true)
            }
        }
    }

    private func showDismissToast() {
        let toast = UILabel()
        toast.text = "  Ad reported by user — moving to next  "
        toast.font = .systemFont(ofSize: 13, weight: .medium)
        toast.textColor = .white
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        toast.textAlignment = .center
        toast.layer.cornerRadius = 16
        toast.clipsToBounds = true
        toast.translatesAutoresizingMaskIntoConstraints = false
        toast.alpha = 0
        view.addSubview(toast)

        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            toast.heightAnchor.constraint(equalToConstant: 32),
        ])

        UIView.animate(withDuration: 0.3) { toast.alpha = 1.0 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak toast] in
            UIView.animate(withDuration: 0.3, animations: {
                toast?.alpha = 0
            }, completion: { _ in toast?.removeFromSuperview() })
        }
    }

    // MARK: - CLXAdRevenueDelegate

    func didPayRevenue(for ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("💰 Reels didPayRevenueForAd", ad: ad)
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        kReelsAdCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ReelsCell", for: indexPath) as! ReelsCell
        let item = items[indexPath.item]
        cell.configure(with: item, at: indexPath.item)

        if item.isLoaded, !item.isImagePlaceholder, let ad = item.ad {
            item.loader?.renderNativeAdView(cell.nativeAdView, with: ad)
        }

        return cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }
}
