//
//  CloudXCoreCrashManager.swift
//  CloudXCore
//
//  Created by Bryan Boyko on 4/11/25.
//

import Foundation
import Sentry

public class CloudXCoreCrashManager {

    private static var isInitialized = false

    public static func initializeIfNeeded() {
        guard !isInitialized else { return }

        if !SentrySDK.isEnabled {
            // Host app did NOT initialize Sentry — initialize with your DSN
            SentrySDK.start { options in
                options.dsn = "https://87380330dc498909d8671ac625cbc571@o4507176279867392.ingest.us.sentry.io/4509136596828160"
                options.releaseName = "CloudXCore@1.0.0" // Update with real version
                options.enableAutoSessionTracking = true
                options.debug = false

                options.beforeSend = { event in
                    event.tags?["sdk_component"] = "CloudXCore"
                    return event
                }
            }
        } else {
            // Host app already uses Sentry — just tag their events
            SentrySDK.configureScope { scope in
                scope.setTag(value: "CloudXCore", key: "sdk_component")
            }
        }

        isInitialized = true
    }
}
