import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private weak var emulatorViewController: EmulatorViewController?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let rootViewController = EmulatorViewController()
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()

        self.window = window
        self.emulatorViewController = rootViewController

        if let url = connectionOptions.urlContexts.first?.url {
            rootViewController.handleIncomingURL(url)
            return
        }

        // UI tests can inject a launch deep-link without relying on iOS URL dispatch.
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "-emu_deeplink"), index + 1 < args.count {
            let raw = args[index + 1]
            if let url = URL(string: raw) {
                rootViewController.handleIncomingURL(url)
            }
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        emulatorViewController?.handleIncomingURL(url)
    }
}
