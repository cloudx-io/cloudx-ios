#import "AppTrackingPermission.h"
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import "DemoAppLogger.h"

@implementation AppTrackingPermission

+ (void)requestWithCompletion:(nullable void (^)(void))completion {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            switch (status) {
                case ATTrackingManagerAuthorizationStatusAuthorized:
                    [[DemoAppLogger sharedInstance] logMessage:@"App Tracking authorized"];
                    break;
                case ATTrackingManagerAuthorizationStatusDenied:
                    [[DemoAppLogger sharedInstance] logMessage:@"App Tracking denied"];
                    break;
                case ATTrackingManagerAuthorizationStatusNotDetermined:
                    [[DemoAppLogger sharedInstance] logMessage:@"App Tracking not determined"];
                    break;
                case ATTrackingManagerAuthorizationStatusRestricted:
                    [[DemoAppLogger sharedInstance] logMessage:@"App Tracking restricted"];
                    break;
                default:
                    break;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion();
            });
        }];
    });
}

@end
