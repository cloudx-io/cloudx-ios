//
//  CloudXSingularConnector.h
//  CloudXSingularConnector
//
//  Umbrella header for the CloudXSingularConnector framework.
//

#import <Foundation/Foundation.h>

// Registration function for static frameworks. Registers the integration with the CloudX SDK.
// Called automatically from +load; also callable manually if the host app does not link with -ObjC.
__attribute__((visibility("default"))) void CloudXSingularConnectorRegister(void);

// Module registration class — its +load self-registers the integration with the CloudX SDK.
@interface CloudXSingularConnector : NSObject
@end

#import "CLXSingularConnector.h"
#import "CLXSingularConnectorVersion.h"
