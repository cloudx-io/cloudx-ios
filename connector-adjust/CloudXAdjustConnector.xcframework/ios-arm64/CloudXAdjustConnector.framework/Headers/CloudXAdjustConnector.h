//
//  CloudXAdjustConnector.h
//  CloudXAdjustConnector
//
//  Umbrella header for the CloudXAdjustConnector framework.
//

#import <Foundation/Foundation.h>

// Registration function for static frameworks. Registers the integration with the CloudX SDK.
// Called automatically from +load; also callable manually if the host app does not link with -ObjC.
__attribute__((visibility("default"))) void CloudXAdjustConnectorRegister(void);

// Module registration class — its +load self-registers the integration with the CloudX SDK.
@interface CloudXAdjustConnector : NSObject
@end

#import "CLXAdjustConnector.h"
#import "CLXAdjustConnectorVersion.h"
