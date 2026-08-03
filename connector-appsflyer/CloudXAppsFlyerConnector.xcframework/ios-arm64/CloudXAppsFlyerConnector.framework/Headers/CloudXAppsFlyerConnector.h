//
//  CloudXAppsFlyerConnector.h
//  CloudXAppsFlyerConnector
//
//  Umbrella header for the CloudXAppsFlyerConnector framework.
//

#import <Foundation/Foundation.h>

// Registration function for static frameworks. Registers the integration with the CloudX SDK.
// Called automatically from +load; also callable manually if the host app does not link with -ObjC.
__attribute__((visibility("default"))) void CloudXAppsFlyerConnectorRegister(void);

// Module registration class — its +load self-registers the integration with the CloudX SDK.
@interface CloudXAppsFlyerConnector : NSObject
@end

#import "CLXAppsFlyerConnector.h"
#import "CLXAppsFlyerConnectorVersion.h"
