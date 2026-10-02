import CloudXCore
import GoogleMobileAds
import Foundation

/**
 * Brings up both SDKs for a demo flow that loads CloudX and AdMob side by side. Google Mobile Ads
 * starts right away. CloudX initializes after the App Tracking Transparency answer, so its first
 * requests carry that answer.
 *
 * `onStatus` receives the combined "CloudX: … | AdMob: …" line whenever either part changes.
 * `onCloudXSettled` is called once: true when CloudX initialized, false when it failed or did not
 * answer within 15 s. An answer after the timeout only updates the status line.
 */
final class DemoSdkStartup {

    private static let initializationTimeout: TimeInterval = 15

    private let onStatus: (String) -> Void
    private let onCloudXSettled: (Bool) -> Void
    private var cloudXStatus = "CloudX: Initializing"
    private var adMobStatus = "AdMob: Initializing"
    private var timeoutWork: DispatchWorkItem?
    private var settled = false

    init(onStatus: @escaping (String) -> Void, onCloudXSettled: @escaping (Bool) -> Void) {
        self.onStatus = onStatus
        self.onCloudXSettled = onCloudXSettled
    }

    deinit {
        timeoutWork?.cancel()
    }

    func start() {
        publishStatus()
        startAdMob()
        AppTrackingPermission.request { [weak self] in
            self?.initializeCloudX()
        }
    }

    /*
     * Loads do not wait for this. Google asks apps to wait for the completion handler only when they
     * use AdMob mediation, which these flows do not.
     */
    private func startAdMob() {
        MobileAds.shared.start { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.adMobStatus = "AdMob: Ready"
                self.publishStatus()
            }
        }
    }

    private func initializeCloudX() {
        let config = CLXDemoConfigManager.sharedManager.currentConfig
        if !config.hashedUserId.isEmpty {
            CloudXCore.shared.setHashedUserID(config.hashedUserId)
        }
        DemoAppLogger.sharedInstance.logMessage("Initializing CloudX SDK")

        let timeoutWork = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.cloudXStatus = "CloudX: No response, AdMob only"
            self.publishStatus()
            self.settle(cloudXAvailable: false)
        }
        self.timeoutWork = timeoutWork
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.initializationTimeout, execute: timeoutWork)

        let initConfig = CLXInitializationConfiguration.configuration(appKey: config.appKey)
        CloudXCore.shared.initialize(with: initConfig) { [weak self] sdkConfig, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.timeoutWork?.cancel()
                self.timeoutWork = nil
                if sdkConfig != nil {
                    DemoAppLogger.sharedInstance.logMessage("CloudX SDK initialized")
                    self.cloudXStatus = self.settled ? "CloudX: Initialized late, AdMob only" : "CloudX: Initialized"
                    self.publishStatus()
                    self.settle(cloudXAvailable: true)
                } else {
                    let message = error?.localizedDescription ?? "Unknown error"
                    DemoAppLogger.sharedInstance.logMessage("CloudX SDK initialization failed: \(message)")
                    self.cloudXStatus = "CloudX: Failed (\(message))"
                    self.publishStatus()
                    self.settle(cloudXAvailable: false)
                }
            }
        }
    }

    private func settle(cloudXAvailable: Bool) {
        if settled { return }
        settled = true
        onCloudXSettled(cloudXAvailable)
    }

    private func publishStatus() {
        onStatus("\(cloudXStatus) | \(adMobStatus)")
    }
}
