//
//  CloudXAppHarbrConnector.h
//  CloudXAppHarbrConnector
//
//  Umbrella header for the CloudXAppHarbrConnector framework.
//

#import <Foundation/Foundation.h>

// Registration function for static frameworks. Registers the gate with the CloudX SDK.
// Called automatically from +load; also callable manually if the host app does not link with -ObjC.
__attribute__((visibility("default"))) void CloudXAppHarbrConnectorRegister(void);

// Module registration class — its +load self-registers the gate with the CloudX SDK.
@interface CloudXAppHarbrConnector : NSObject
@end

#import "CLXAppHarbrConnector.h"
#import "CLXAppHarbrSDKBridge.h"
#import "CLXAppHarbrConnectorVersion.h"
