import AppTrackingTransparency
import Foundation

/** The App Tracking Transparency request, shared by the demo flows that load ads. */
enum AppTrackingPermission {

    /**
     * Asks for tracking authorization after a short delay, so the prompt lands on a screen that is
     * already visible, logs the answer and then calls `completion` on the main queue. When the
     * answer is already known iOS reports it without a prompt and `completion` still runs.
     */
    static func request(completion: (() -> Void)?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    DemoAppLogger.sharedInstance.logMessage("App Tracking authorized")
                case .denied:
                    DemoAppLogger.sharedInstance.logMessage("App Tracking denied")
                case .notDetermined:
                    DemoAppLogger.sharedInstance.logMessage("App Tracking not determined")
                case .restricted:
                    DemoAppLogger.sharedInstance.logMessage("App Tracking restricted")
                @unknown default:
                    break
                }
                DispatchQueue.main.async { completion?() }
            }
        }
    }
}
