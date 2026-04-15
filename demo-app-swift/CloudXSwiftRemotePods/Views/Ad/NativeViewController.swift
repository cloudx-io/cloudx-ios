import UIKit
import CloudXCore

private enum NativeFlow: Int {
    case template = 0
    case manual = 1
    case lateBinding = 2
}

class NativeViewController: BaseAdViewController {
    private var nativeAdLoader: CLXNativeAdLoader?
    private var nativeAdView: CLXNativeAdView?
    private var loadedAd: CLXAd?
    private let adContainerView = UIView()
    private let settings = UserDefaultsSettings.shared
    private var activeFlow: NativeFlow = .template
    private let flowPicker = UISegmentedControl(items: ["A: Template", "B: Manual", "C: Late-Bind"])
    private let flowDescription = UILabel()
    private var loadButton: UIButton!
    private var bindButton: UIButton!
    private let flowBanner = UILabel()
    private var preloadedAd: CLXAd?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Native"
        setupUI()
        updateStatusUI(state: .noAd)
        flowPickerChanged()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetAdState()
    }

    deinit {
        nativeAdLoader?.destroy()
    }

    // MARK: - UI

    private func setupUI() {
        flowDescription.font = .systemFont(ofSize: 13, weight: .medium)
        flowDescription.textColor = .label
        flowDescription.textAlignment = .left
        flowDescription.numberOfLines = 0
        flowDescription.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(flowDescription)

        NSLayoutConstraint.activate([
            flowDescription.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            flowDescription.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            flowDescription.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -140),
            flowDescription.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 90),
        ])

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 6
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        flowPicker.selectedSegmentIndex = 0
        flowPicker.addTarget(self, action: #selector(flowPickerChanged), for: .valueChanged)
        contentStack.addArrangedSubview(flowPicker)

        loadButton = UIButton(type: .system)
        loadButton.setTitleColor(.white, for: .normal)
        loadButton.titleLabel?.font = .boldSystemFont(ofSize: 14)
        loadButton.layer.cornerRadius = 8
        loadButton.translatesAutoresizingMaskIntoConstraints = false
        loadButton.addTarget(self, action: #selector(loadAction), for: .touchUpInside)

        let destroyButton = UIButton(type: .system)
        destroyButton.setTitle("Destroy", for: .normal)
        destroyButton.setTitleColor(.systemRed, for: .normal)
        destroyButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        destroyButton.addTarget(self, action: #selector(destroyAd), for: .touchUpInside)

        let leftSpacer = UIView()
        let rightSpacer = UIView()
        let buttonRow = UIStackView(arrangedSubviews: [leftSpacer, loadButton, destroyButton, rightSpacer])
        buttonRow.axis = .horizontal
        buttonRow.spacing = 8
        buttonRow.alignment = .center
        contentStack.addArrangedSubview(buttonRow)

        NSLayoutConstraint.activate([
            loadButton.widthAnchor.constraint(equalToConstant: 200),
            loadButton.heightAnchor.constraint(equalToConstant: 36),
            leftSpacer.widthAnchor.constraint(equalTo: rightSpacer.widthAnchor),
        ])

        bindButton = UIButton(type: .system)
        bindButton.setTitle("Step 2: Bind & Display", for: .normal)
        bindButton.setTitleColor(.white, for: .normal)
        bindButton.titleLabel?.font = .boldSystemFont(ofSize: 14)
        bindButton.backgroundColor = .systemTeal
        bindButton.layer.cornerRadius = 8
        bindButton.isHidden = true
        bindButton.alpha = 0
        bindButton.addTarget(self, action: #selector(bindPreloadedAd), for: .touchUpInside)
        contentStack.addArrangedSubview(bindButton)
        bindButton.heightAnchor.constraint(equalToConstant: 36).isActive = true

        flowBanner.font = .monospacedSystemFont(ofSize: 11, weight: .bold)
        flowBanner.textAlignment = .center
        flowBanner.numberOfLines = 0
        flowBanner.textColor = .secondaryLabel
        contentStack.addArrangedSubview(flowBanner)

        adContainerView.translatesAutoresizingMaskIntoConstraints = false
        adContainerView.clipsToBounds = true
        contentStack.addArrangedSubview(adContainerView)
        adContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 400).isActive = true

        let pad: CGFloat = 16
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: statusStack.topAnchor, constant: -4),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: pad),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -pad),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -pad),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -pad * 2),
        ])
    }

    @objc private func flowPickerChanged() {
        activeFlow = NativeFlow(rawValue: flowPicker.selectedSegmentIndex) ?? .template

        switch activeFlow {
        case .template:
            flowDescription.text = "Template — SDK auto-generates the ad view. Zero custom UI code. Just load and the SDK handles layout."
            loadButton.setTitle("Load Ad", for: .normal)
            loadButton.backgroundColor = .systemGreen
        case .manual:
            flowDescription.text = "Manual — Publisher builds a fully custom layout. Every element is positioned and styled by your code."
            loadButton.setTitle("Load Ad", for: .normal)
            loadButton.backgroundColor = .systemBlue
        case .lateBinding:
            flowDescription.text = "Late-Bind — Pre-load ad data headlessly, then bind to any custom view on demand. A two-step process."
            loadButton.setTitle("Step 1: Pre-load", for: .normal)
            loadButton.backgroundColor = .systemOrange
        }
    }

    // MARK: - Helpers

    private func updateFlowBanner(text: String, color: UIColor) {
        flowBanner.text = text
        flowBanner.textColor = color
    }

    private func showBindButton(_ show: Bool) {
        if show, bindButton.isHidden {
            bindButton.isHidden = false
            UIView.animate(withDuration: 0.3) { self.bindButton.alpha = 1.0 }
        } else if !show, !bindButton.isHidden {
            UIView.animate(withDuration: 0.2, animations: {
                self.bindButton.alpha = 0
            }, completion: { _ in self.bindButton.isHidden = true })
        }
    }

    // MARK: - Ad Unit

    private var adUnitId: String {
        let id = CLXDemoConfigManager.sharedManager.currentConfig.nativeAdUnitId
        return settings.nativeMediumAdUnitId.isEmpty ? id : settings.nativeMediumAdUnitId
    }

    private func ensureLoader() -> CLXNativeAdLoader {
        if let loader = nativeAdLoader { return loader }
        let loader = cloudX.createNativeAdLoader(adUnitIdentifier: adUnitId)
        loader.nativeAdDelegate = self
        loader.revenueDelegate = self
        loader.placement = "demo_native"
        nativeAdLoader = loader
        return loader
    }

    // MARK: - Load Action

    @objc private func loadAction() {
        switch activeFlow {
        case .template:    loadTemplate()
        case .manual:      loadManual()
        case .lateBinding: loadLateBinding()
        }
    }

    // MARK: - Flow A: Template

    @objc func loadNativeAd() {
        loadTemplate()
    }

    private func loadTemplate() {
        guard !isLoading else {
            showAlert(title: "Info", message: "Native ad is already loading.")
            return
        }
        resetAdState()
        receivedCallbacks = []
        activeFlow = .template
        isLoading = true
        updateStatusUI(state: .loading)
        updateFlowBanner(text: "Loading template...", color: .secondaryLabel)
        ensureLoader().loadAd()
    }

    // MARK: - Flow B: Manual

    private func loadManual() {
        guard !isLoading else {
            showAlert(title: "Info", message: "Native ad is already loading.")
            return
        }
        resetAdState()
        activeFlow = .manual

        let adView = buildManualAdView()
        let binder = CLXNativeAdViewBinder(builderBlock: { builder in
            builder.titleLabelTag = CLXNativeAdViewTagTitleLabel
            builder.bodyLabelTag = CLXNativeAdViewTagBodyLabel
            builder.callToActionButtonTag = CLXNativeAdViewTagCallToActionButton
            builder.iconImageViewTag = CLXNativeAdViewTagIconImageView
            builder.mediaContentViewTag = CLXNativeAdViewTagMediaViewContainer
            builder.advertiserLabelTag = CLXNativeAdViewTagAdvertiserLabel
            builder.optionsContentViewTag = CLXNativeAdViewTagOptionsContentView
        })
        adView.bindViews(with: binder)

        isLoading = true
        updateStatusUI(state: .loading)
        updateFlowBanner(text: "Loading into custom publisher layout...", color: .secondaryLabel)
        ensureLoader().loadAd(into: adView)
    }

    // MARK: - Flow C: Late-Binding (2-step)

    private func loadLateBinding() {
        guard !isLoading else {
            showAlert(title: "Info", message: "Native ad is already loading.")
            return
        }
        resetAdState()
        activeFlow = .lateBinding
        isLoading = true
        updateStatusUI(state: .loading)
        updateFlowBanner(text: "Step 1: Loading headlessly...", color: .secondaryLabel)
        ensureLoader().loadAd()
    }

    @objc private func bindPreloadedAd() {
        guard let ad = preloadedAd else { return }

        let spotlightView = buildSpotlightAdView()
        let binder = CLXNativeAdViewBinder(builderBlock: { builder in
            builder.titleLabelTag = CLXNativeAdViewTagTitleLabel
            builder.bodyLabelTag = CLXNativeAdViewTagBodyLabel
            builder.callToActionButtonTag = CLXNativeAdViewTagCallToActionButton
            builder.iconImageViewTag = CLXNativeAdViewTagIconImageView
            builder.mediaContentViewTag = CLXNativeAdViewTagMediaViewContainer
            builder.advertiserLabelTag = CLXNativeAdViewTagAdvertiserLabel
            builder.optionsContentViewTag = CLXNativeAdViewTagOptionsContentView
        })
        spotlightView.bindViews(with: binder)
        ensureLoader().renderNativeAdView(spotlightView, with: ad)
        displayAdView(spotlightView)

        preloadedAd = nil
        showBindButton(false)
        updateFlowBanner(text: "COMPLETE — Bound to custom view on demand", color: .systemGreen)
        DemoAppLogger.sharedInstance.logMessage("Flow C Step 2: Bound pre-loaded ad to spotlight view")
    }

    // MARK: - Destroy

    @objc private func destroyAd() {
        resetAdState()
        DemoAppLogger.sharedInstance.logMessage("Native ad destroyed")
    }

    private func resetAdState() {
        if let ad = loadedAd {
            nativeAdLoader?.destroy(ad)
            loadedAd = nil
        }
        nativeAdView?.removeFromSuperview()
        nativeAdView = nil
        nativeAdLoader?.destroy()
        nativeAdLoader = nil
        preloadedAd = nil
        isLoading = false
        showBindButton(false)
        updateStatusUI(state: .noAd)
        flowBanner.text = nil
    }

    // MARK: - Manual Ad View Builder (media-hero layout)

    private func buildManualAdView() -> CLXNativeAdView {
        let adView = CLXNativeAdView()
        adView.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)
        adView.layer.cornerRadius = 16
        adView.clipsToBounds = true

        let media = UIView()
        media.tag = CLXNativeAdViewTagMediaViewContainer
        media.clipsToBounds = true
        media.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(media)

        let gradientView = GradientFadeView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        gradientView.isUserInteractionEnabled = false
        adView.addSubview(gradientView)

        let options = UIView()
        options.tag = CLXNativeAdViewTagOptionsContentView
        options.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(options)

        let bottomBar = UIView()
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(bottomBar)

        let icon = UIImageView()
        icon.tag = CLXNativeAdViewTagIconImageView
        icon.contentMode = .scaleAspectFill
        icon.clipsToBounds = true
        icon.layer.cornerRadius = 22
        icon.layer.borderWidth = 2
        icon.layer.borderColor = UIColor.white.cgColor
        icon.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(icon)

        let titleLabel = UILabel()
        titleLabel.tag = CLXNativeAdViewTagTitleLabel
        titleLabel.font = .boldSystemFont(ofSize: 15)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(titleLabel)

        let advertiser = UILabel()
        advertiser.tag = CLXNativeAdViewTagAdvertiserLabel
        advertiser.font = .systemFont(ofSize: 10)
        advertiser.textColor = UIColor(white: 1.0, alpha: 0.5)
        advertiser.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(advertiser)

        let body = UILabel()
        body.tag = CLXNativeAdViewTagBodyLabel
        body.font = .systemFont(ofSize: 12)
        body.textColor = UIColor(white: 1.0, alpha: 0.7)
        body.numberOfLines = 1
        body.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(body)

        let cta = UIButton(type: .system)
        cta.tag = CLXNativeAdViewTagCallToActionButton
        cta.titleLabel?.font = .boldSystemFont(ofSize: 13)
        cta.backgroundColor = .systemGreen
        cta.setTitleColor(.white, for: .normal)
        cta.layer.cornerRadius = 16
        cta.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        cta.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(cta)

        NSLayoutConstraint.activate([
            media.topAnchor.constraint(equalTo: adView.topAnchor),
            media.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            media.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
            media.heightAnchor.constraint(equalToConstant: 300),

            gradientView.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: media.bottomAnchor),
            gradientView.heightAnchor.constraint(equalToConstant: 80),

            options.topAnchor.constraint(equalTo: adView.topAnchor, constant: 8),
            options.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -8),
            options.widthAnchor.constraint(equalToConstant: 28),
            options.heightAnchor.constraint(equalToConstant: 28),

            bottomBar.topAnchor.constraint(equalTo: media.bottomAnchor, constant: 10),
            bottomBar.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            bottomBar.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            bottomBar.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -12),

            icon.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            icon.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            icon.widthAnchor.constraint(equalToConstant: 44),
            icon.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: cta.leadingAnchor, constant: -8),

            advertiser.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1),
            advertiser.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            body.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 8),
            body.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            body.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            body.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor),

            cta.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            cta.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            cta.heightAnchor.constraint(equalToConstant: 32),
        ])

        return adView
    }

    // MARK: - Spotlight Ad View Builder (light card for Flow C)

    private func buildSpotlightAdView() -> CLXNativeAdView {
        let adView = CLXNativeAdView()
        adView.backgroundColor = UIColor(red: 1.0, green: 0.97, blue: 0.93, alpha: 1.0)
        adView.layer.cornerRadius = 16
        adView.clipsToBounds = true

        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(header)

        let icon = UIImageView()
        icon.tag = CLXNativeAdViewTagIconImageView
        icon.contentMode = .scaleAspectFill
        icon.clipsToBounds = true
        icon.layer.cornerRadius = 8
        icon.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(icon)

        let options = UIView()
        options.tag = CLXNativeAdViewTagOptionsContentView
        options.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(options)

        let titleLabel = UILabel()
        titleLabel.tag = CLXNativeAdViewTagTitleLabel
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.textColor = UIColor(red: 0.2, green: 0.1, blue: 0.0, alpha: 1.0)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(titleLabel)

        let advertiser = UILabel()
        advertiser.tag = CLXNativeAdViewTagAdvertiserLabel
        advertiser.font = .systemFont(ofSize: 11)
        advertiser.textColor = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        advertiser.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(advertiser)

        let body = UILabel()
        body.tag = CLXNativeAdViewTagBodyLabel
        body.font = .systemFont(ofSize: 13)
        body.textColor = UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1.0)
        body.numberOfLines = 2
        body.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(body)

        let media = UIView()
        media.tag = CLXNativeAdViewTagMediaViewContainer
        media.clipsToBounds = true
        media.layer.cornerRadius = 12
        media.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(media)

        let cta = UIButton(type: .system)
        cta.tag = CLXNativeAdViewTagCallToActionButton
        cta.titleLabel?.font = .boldSystemFont(ofSize: 15)
        cta.backgroundColor = .systemOrange
        cta.setTitleColor(.white, for: .normal)
        cta.layer.cornerRadius = 22
        cta.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(cta)

        let pad: CGFloat = 14
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: adView.topAnchor, constant: pad),
            header.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: pad),
            header.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -pad),

            icon.topAnchor.constraint(equalTo: header.topAnchor),
            icon.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            icon.widthAnchor.constraint(equalToConstant: 44),
            icon.heightAnchor.constraint(equalToConstant: 44),
            icon.bottomAnchor.constraint(equalTo: header.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: header.topAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: options.leadingAnchor, constant: -8),

            advertiser.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1),
            advertiser.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            options.topAnchor.constraint(equalTo: header.topAnchor),
            options.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            options.widthAnchor.constraint(equalToConstant: 28),
            options.heightAnchor.constraint(equalToConstant: 28),

            body.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
            body.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: pad),
            body.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -pad),

            media.topAnchor.constraint(equalTo: body.bottomAnchor, constant: 10),
            media.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: pad),
            media.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -pad),
            media.heightAnchor.constraint(equalToConstant: 280),

            cta.topAnchor.constraint(equalTo: media.bottomAnchor, constant: 12),
            cta.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: pad),
            cta.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -pad),
            cta.heightAnchor.constraint(equalToConstant: 44),
            cta.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -pad),
        ])

        return adView
    }

    override func adViewForClickTesting() -> UIView? { nativeAdView }

    // MARK: - Display

    private func displayAdView(_ adView: CLXNativeAdView) {
        nativeAdView?.removeFromSuperview()
        nativeAdView = adView
        adView.translatesAutoresizingMaskIntoConstraints = false
        adContainerView.addSubview(adView)

        NSLayoutConstraint.activate([
            adView.topAnchor.constraint(equalTo: adContainerView.topAnchor),
            adView.leadingAnchor.constraint(equalTo: adContainerView.leadingAnchor),
            adView.trailingAnchor.constraint(equalTo: adContainerView.trailingAnchor),
            adView.bottomAnchor.constraint(equalTo: adContainerView.bottomAnchor)
        ])
    }
}

// MARK: - CLXNativeAdDelegate

extension NativeViewController: CLXNativeAdDelegate {
    func didLoadNativeAd(_ nativeAdView: CLXNativeAdView?, for ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("✅ Native didLoadNativeAd", ad: ad)
        isLoading = false
        receivedCallbacks.insert(.loaded)
        loadedAd = ad

        if activeFlow == .lateBinding {
            preloadedAd = ad
            updateStatusUI(state: .ready)
            updateFlowBanner(text: "Step 1 done — tap 'Bind & Display'", color: .systemOrange)
            showBindButton(true)
            DemoAppLogger.sharedInstance.logMessage("Flow C Step 1: Ad pre-loaded — waiting for bind")
            return
        }

        updateStatusUI(state: .ready)

        if let view = nativeAdView {
            displayAdView(view)
            updateFlowBanner(text: "MANUAL — Custom publisher layout", color: .systemBlue)
        } else if let nativeAd = ad.nativeAd {
            let templateView = CLXNativeAdView(from: nativeAd)
            ensureLoader().renderNativeAdView(templateView, with: ad)
            displayAdView(templateView)
            updateFlowBanner(text: "TEMPLATE — SDK auto-generated view", color: .systemGreen)
        }
    }

    func didFailToLoadNativeAd(forAdUnitIdentifier adUnitId: String, error: CLXError) {
        DemoAppLogger.sharedInstance.logMessage("❌ Native failed (\(adUnitId)) - \(error.localizedDescription)")
        isLoading = false
        updateStatusUI(state: .noAd)
        flowBanner.text = nil

        DispatchQueue.main.async { [weak self] in
            let msg = (error as NSError).detailedDemoDescription
            self?.showAlert(title: "Native Load Failed", message: msg)
        }
    }

    func didClickNativeAd(_ ad: CLXAd) {
        receivedCallbacks.insert(.clicked)
        DemoAppLogger.sharedInstance.logAdEvent("👆 Native didClickNativeAd", ad: ad)
    }

    func didExpireNativeAd(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("⏰ Native didExpireNativeAd", ad: ad)
        resetAdState()
    }

    func didCloseNativeAd(_ ad: CLXAd) {
        DemoAppLogger.sharedInstance.logAdEvent("🚪 Native didCloseNativeAd — user reported/hid ad via AdChoices", ad: ad)
    }
}

// MARK: - CLXAdRevenueDelegate

extension NativeViewController: CLXAdRevenueDelegate {
    func didPayRevenue(for ad: CLXAd) {
        receivedCallbacks.insert(.revenueReceived)
        DemoAppLogger.sharedInstance.logAdEvent("💰 Native didPayRevenueForAd", ad: ad)
    }
}

// MARK: - GradientFadeView

private class GradientFadeView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let gradient = layer as? CAGradientLayer else { return }
        gradient.colors = [UIColor.clear.cgColor,
                           UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 0.9).cgColor]
    }
}
