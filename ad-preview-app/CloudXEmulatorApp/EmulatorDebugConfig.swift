import Foundation
import CloudXCore

enum EmulatorDebugConfig {
    private static let bundleOverrideKey = "CLXCore_bundle_config"

    static func setBundleOverride(_ bundleOverride: String?) {
        let normalized = bundleOverride?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let normalized, !normalized.isEmpty {
            UserDefaults.standard.set(normalized, forKey: bundleOverrideKey)
        } else {
            UserDefaults.standard.removeObject(forKey: bundleOverrideKey)
        }

        UserDefaults.standard.synchronize()
    }

    static func setEnvironment(_ environment: EmulatorEnvironment) {
        CLXURLProvider.setEnvironment(environment.urlProviderEnvironment)
    }

    static func deinitializeSDK() {
        CloudXCore.shared.resetForEmulator()
    }
}

private extension CloudXCore {
    func resetForEmulator() {
        CLXDIContainer.shared().reset()
        _ = perform(NSSelectorFromString("resetForTesting"))
    }
}
