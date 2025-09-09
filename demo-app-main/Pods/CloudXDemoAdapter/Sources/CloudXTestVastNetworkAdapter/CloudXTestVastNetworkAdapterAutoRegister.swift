// This file ensures the demo adapter (testbidder) is automatically registered with the CloudXCore SDK
// when the module is loaded, regardless of integration method (SPM, CocoaPods, etc).
//
// Why is this needed?
// - Without this, the host app would have to manually register the adapter or reference a symbol to force module loading.
// - This pattern guarantees the adapter is always available to the SDK, as soon as it is linked.
//
// How does it work?
// - The static property 'register' runs its block when the module is loaded.
// - The @objc class with a load() method ensures eager loading for Objective-C runtime as well.

import Foundation
import CloudXCore

public class CloudXTestVastNetworkAdapterAutoRegister: NSObject {
    // This static property is initialized when the module is loaded.
    public static let register: Void = {
//        AdapterFactoryResolver.shared.register(
//            network: "testbidder",
//            initializer: CloudXTestVastNetworkInitializer.createInstance(),
//            bannerFactory: CloudXTestVastNetworkBannerFactory.createInstance(),
//            interstitialFactory: CloudXTestVastNetworkInterstitialFactory.createInstance(),
//            rewardedFactory: CloudXTestVastNetworkRewardedFactory.createInstance(),
//            nativeFactory: CloudXTestVastNetworkNativeFactory.createInstance()
//        )
        return ()
    }()
}

#if !SWIFT_PACKAGE
// This ensures registration also happens when loaded by the Objective-C runtime (e.g., in mixed projects).
//@objc public class CloudXTestVastNetworkAdapterObjC: NSObject {
//    @objc public override class func load() {
//        _ = CloudXTestVastNetworkAdapterAutoRegister.register
//    }
//}
#endif 
