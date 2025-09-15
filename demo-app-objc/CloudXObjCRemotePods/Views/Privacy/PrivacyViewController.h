//
//  PrivacyViewController.h
//  CloudXObjCRemotePods
//
//  Created by CloudX on 2025-09-06.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, GPPTestScenario) {
    GPPTestScenarioATTDenied = 0,
    GPPTestScenarioGPPAbsent,
    GPPTestScenarioGPPCCPAConsent,
    GPPTestScenarioGPPCCPAOptOut,
    GPPTestScenarioGPPNonUS,
    GPPTestScenarioGPPUSNonCalifornia,
    GPPTestScenarioCOPPAFlagged,
    GPPTestScenarioCustomGPP,
    GPPTestScenarioGeoInfo,
    GPPTestScenarioDeviceFields,
    GPPTestScenarioPublisherAPI
};

@interface PrivacyViewController : UIViewController

@end

NS_ASSUME_NONNULL_END
