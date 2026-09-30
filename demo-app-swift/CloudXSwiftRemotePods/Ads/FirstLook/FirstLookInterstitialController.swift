import Foundation

/** The network that supplied an interstitial in this First Look pass. */
enum FirstLookSource: CustomStringConvertible {
    case cloudX
    case adMob

    var description: String {
        switch self {
        case .cloudX: return "CLOUDX"
        case .adMob: return "ADMOB"
        }
    }
}

/** Events from either interstitial SDK, with the source attached. */
enum FirstLookEvent {
    case loaded(FirstLookSource)
    case loadFailed(FirstLookSource, message: String)
    case shown(FirstLookSource)
    case showFailed(FirstLookSource, message: String)
    case closed(FirstLookSource)
    case clicked(FirstLookSource)
}

/** A one-use fullscreen ad source. The owning screen releases it through `dispose()`. */
protocol FirstLookInterstitialSource: AnyObject {
    var onEvent: ((FirstLookEvent) -> Void)? { get set }
    var isReady: Bool { get }
    func load()
    func show()
    func dispose()
}

/**
 * Gives CloudX the first load attempt. AdMob loads only after CloudX fails or is unavailable.
 * A new `load()` after an ad closes starts a new CloudX-first pass.
 *
 * Pass nil for `cloudX` when CloudX initialization failed, so every load goes straight to AdMob.
 * Both sources report on the main queue, so `onEvent` is called there too.
 */
final class FirstLookInterstitialController {

    private let cloudX: FirstLookInterstitialSource?
    private let adMob: FirstLookInterstitialSource
    private let onEvent: (FirstLookEvent) -> Void
    private var loading: FirstLookSource?
    private var showing: FirstLookSource?
    private var disposed = false

    init(
        cloudX: FirstLookInterstitialSource?,
        adMob: FirstLookInterstitialSource,
        onEvent: @escaping (FirstLookEvent) -> Void
    ) {
        self.cloudX = cloudX
        self.adMob = adMob
        self.onEvent = onEvent
        cloudX?.onEvent = { [weak self] event in self?.handleEvent(event) }
        adMob.onEvent = { [weak self] event in self?.handleEvent(event) }
    }

    var readySource: FirstLookSource? {
        if disposed || showing != nil { return nil }
        if cloudX?.isReady == true { return .cloudX }
        if adMob.isReady { return .adMob }
        return nil
    }

    func load() {
        if disposed || showing != nil || loading != nil || readySource != nil { return }

        if let cloudX = cloudX {
            loading = .cloudX
            cloudX.load()
        } else {
            loadAdMob()
        }
    }

    /** Returns the selected source, or nil when the app should continue without an ad. */
    func show() -> FirstLookSource? {
        guard let source = readySource else { return nil }
        showing = source
        switch source {
        case .cloudX: cloudX?.show()
        case .adMob: adMob.show()
        }
        return source
    }

    func dispose() {
        if disposed { return }
        disposed = true
        cloudX?.onEvent = nil
        adMob.onEvent = nil
        cloudX?.dispose()
        adMob.dispose()
    }

    private func loadAdMob() {
        if disposed || adMob.isReady { return }
        loading = .adMob
        adMob.load()
    }

    private func handleEvent(_ event: FirstLookEvent) {
        if disposed { return }

        switch event {
        case .loaded(let source):
            guard loading == source else { return }
            loading = nil
            onEvent(event)
        case .loadFailed(let source, _):
            guard loading == source else { return }
            loading = nil
            if source == .cloudX {
                loadAdMob()
            } else {
                onEvent(event)
            }
        case .showFailed(let source, _):
            guard showing == source else { return }
            if source == .cloudX && adMob.isReady {
                showing = .adMob
                adMob.show()
            } else {
                showing = nil
                onEvent(event)
            }
        case .closed(let source):
            guard showing == source else { return }
            showing = nil
            onEvent(event)
        case .shown(let source), .clicked(let source):
            if showing == source { onEvent(event) }
        }
    }
}
