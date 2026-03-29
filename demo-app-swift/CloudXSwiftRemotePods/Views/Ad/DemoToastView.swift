import UIKit

/// Non-blocking dropdown toast for surfacing errors and informational messages.
/// Slides down from the top of the screen, auto-dismisses after a few seconds.
/// Tapping the toast presents a detail popup with the full message.
/// Supports queueing — multiple toasts display sequentially without overlap.
final class DemoToastView: UIView {

    private static var toastQueue: [() -> Void] = []
    private static var isShowingToast = false
    private static var isDismissing = false

    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let fullMessage: String
    private weak var hostViewController: UIViewController?
    private var topConstraint: NSLayoutConstraint?

    private static let displayDuration: TimeInterval = 4.0
    private static let animationDuration: TimeInterval = 0.3
    private static let horizontalPadding: CGFloat = 16
    private static let internalPadding: CGFloat = 12
    private static let cornerRadiusValue: CGFloat = 12

    // MARK: - Public API

    static func show(in viewController: UIViewController, title: String, message: String) {
        DispatchQueue.main.async {
            let showBlock = {
                isShowingToast = true
                presentToast(in: viewController, title: title, message: message)
            }

            if isShowingToast {
                toastQueue.append(showBlock)
            } else {
                showBlock()
            }
        }
    }

    // MARK: - Presentation

    private static func presentToast(in viewController: UIViewController,
                                     title: String,
                                     message: String) {
        let toast = DemoToastView(title: title, message: message, host: viewController)

        let container = viewController.view.window ?? viewController.view!
        container.addSubview(toast)

        toast.translatesAutoresizingMaskIntoConstraints = false

        // Anchor to the window's top + safe area inset manually to avoid layout engine ambiguity
        var safeTop = container.safeAreaInsets.top
        if safeTop < 20 { safeTop = 59 } // Dynamic Island fallback
        let top = toast.topAnchor.constraint(equalTo: container.topAnchor, constant: -120)
        toast.topConstraint = top

        NSLayoutConstraint.activate([
            top,
            toast.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: horizontalPadding),
            toast.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -horizontalPadding)
        ])

        container.layoutIfNeeded()

        // Slide to just below the hardware safe area (notch / Dynamic Island) with 4pt breathing room
        top.constant = safeTop + 4
        UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut,
            animations: { container.layoutIfNeeded() },
            completion: { _ in toast.scheduleAutoDismiss() }
        )
    }

    // MARK: - Init

    private init(title: String, message: String, host: UIViewController) {
        self.fullMessage = message
        self.hostViewController = host
        super.init(frame: .zero)
        setupUI(title: title, message: message)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI Setup

    private func setupUI(title: String, message: String) {
        backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 0.95)
        layer.cornerRadius = Self.cornerRadiusValue
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        layer.shadowOpacity = 0.3
        clipsToBounds = false

        let accentBar = UIView()
        accentBar.backgroundColor = .systemOrange
        accentBar.layer.cornerRadius = 1.5
        accentBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(accentBar)

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        messageLabel.text = message
        messageLabel.font = .systemFont(ofSize: 12, weight: .regular)
        messageLabel.textColor = UIColor(white: 0.85, alpha: 1)
        messageLabel.numberOfLines = 2
        messageLabel.lineBreakMode = .byTruncatingTail
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageLabel)

        let tapHint = UILabel()
        tapHint.text = "Tap for details"
        tapHint.font = .systemFont(ofSize: 10, weight: .medium)
        tapHint.textColor = UIColor(white: 0.6, alpha: 1)
        tapHint.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tapHint)

        NSLayoutConstraint.activate([
            accentBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.internalPadding),
            accentBar.topAnchor.constraint(equalTo: topAnchor, constant: Self.internalPadding),
            accentBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.internalPadding),
            accentBar.widthAnchor.constraint(equalToConstant: 3),

            titleLabel.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: tapHint.leadingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: Self.internalPadding),

            messageLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.internalPadding),
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.internalPadding),

            tapHint.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.internalPadding),
            tapHint.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor)
        ])

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toastTapped)))

        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(dismissAnimated as () -> Void))
        swipeUp.direction = .up
        addGestureRecognizer(swipeUp)
    }

    // MARK: - Dismiss

    private func scheduleAutoDismiss() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.displayDuration) { [weak self] in
            guard let self, self.superview != nil, !Self.isDismissing else { return }
            self.dismissAnimated()
        }
    }

    @objc private func toastTapped() {
        guard !Self.isDismissing else { return }

        let host = hostViewController
        let msg = fullMessage
        let title = titleLabel.text ?? ""

        dismissAnimated { [weak host] in
            guard let host else { return }
            let detail = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            detail.addAction(.init(title: "OK", style: .default))
            host.present(detail, animated: true)
        }
    }

    @objc private func dismissAnimated() {
        dismissAnimated(completion: nil)
    }

    private func dismissAnimated(completion: (() -> Void)?) {
        guard !Self.isDismissing else { return }
        Self.isDismissing = true

        topConstraint?.constant = -120
        UIView.animate(
            withDuration: Self.animationDuration,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                self.superview?.layoutIfNeeded()
                self.alpha = 0
            },
            completion: { _ in
                Self.isDismissing = false
                self.removeFromSuperview()
                completion?()
                Self.dequeueNext()
            }
        )
    }

    private static func dequeueNext() {
        isShowingToast = false
        guard !toastQueue.isEmpty else { return }
        let next = toastQueue.removeFirst()
        next()
    }
}
