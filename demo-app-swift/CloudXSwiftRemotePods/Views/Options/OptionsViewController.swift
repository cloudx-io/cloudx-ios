import UIKit

/**
 * Demo-only launch screen that picks which demo flow to enter. It makes no SDK calls.
 * General opens the CloudX integration demo (`AdDemoTabViewController`). First Look
 * (`FirstLookViewController`) demonstrates a CloudX-first interstitial with an AdMob fallback.
 * Arbiter/TPA is a placeholder, so its button is disabled.
 *
 * The screen is replaced as the window's root once a flow is picked, so it only shows again
 * when the app starts from scratch.
 */
final class OptionsViewController: UIViewController {

    private static let backgroundColor = UIColor(red: 0x34 / 255.0, green: 0x5A / 255.0, blue: 0xB5 / 255.0, alpha: 1)
    private static let buttonBackgroundColor = UIColor(red: 0xF6 / 255.0, green: 0xF6 / 255.0, blue: 0xF6 / 255.0, alpha: 1)
    private static let buttonTitleColor = UIColor(red: 0x32 / 255.0, green: 0x32 / 255.0, blue: 0x32 / 255.0, alpha: 1)

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    /**
     * Opens the General demo in `window`, replacing whatever is shown there. Returns the new root
     * so callers can drive it right away: its tabs are already built.
     */
    @discardableResult
    static func openGeneral(in window: UIWindow) -> AdDemoTabViewController {
        let tabViewController = AdDemoTabViewController()
        replaceRoot(of: window, with: tabViewController)
        return tabViewController
    }

    /** Opens the First Look demo in `window`, replacing whatever is shown there. */
    static func openFirstLook(in window: UIWindow) {
        replaceRoot(of: window, with: UINavigationController(rootViewController: FirstLookViewController()))
    }

    private static func replaceRoot(of window: UIWindow, with viewController: UIViewController) {
        viewController.loadViewIfNeeded()
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = viewController
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Self.backgroundColor

        let titleLabel = UILabel()
        titleLabel.text = "CloudX"
        titleLabel.textColor = .white
        titleLabel.font = .boldSystemFont(ofSize: 32)
        titleLabel.textAlignment = .center

        let generalButton = makeButton(title: "General", enabled: true)
        generalButton.addTarget(self, action: #selector(generalTapped), for: .touchUpInside)
        let firstLookButton = makeButton(title: "First Look", enabled: true)
        firstLookButton.addTarget(self, action: #selector(firstLookTapped), for: .touchUpInside)
        let arbiterButton = makeButton(title: "Arbiter/TPA", enabled: false)

        let buttonStack = UIStackView(arrangedSubviews: [generalButton, firstLookButton, arbiterButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = 16

        let stack = UIStackView(arrangedSubviews: [titleLabel, buttonStack])
        stack.axis = .vertical
        stack.spacing = 48
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        // Fill up to 280 points, but always keep 24 points of side margin on narrow screens.
        let preferredWidth = stack.widthAnchor.constraint(equalToConstant: 280)
        preferredWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            preferredWidth,
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24)
        ])
    }

    @objc private func generalTapped() {
        guard let window = view.window else { return }
        DemoAppLogger.sharedInstance.logMessage("Opening the General demo")
        Self.openGeneral(in: window)
    }

    @objc private func firstLookTapped() {
        guard let window = view.window else { return }
        DemoAppLogger.sharedInstance.logMessage("Opening the First Look demo")
        Self.openFirstLook(in: window)
    }

    private func makeButton(title: String, enabled: Bool) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.setTitleColor(Self.buttonTitleColor, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 20)
        button.backgroundColor = Self.buttonBackgroundColor
        button.layer.cornerRadius = 8
        button.isEnabled = enabled
        button.alpha = enabled ? 1 : 0.5
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
        return button
    }
}
