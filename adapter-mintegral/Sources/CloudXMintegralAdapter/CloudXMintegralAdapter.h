#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double CloudXMintegralAdapterVersionNumber;
FOUNDATION_EXPORT const unsigned char CloudXMintegralAdapterVersionString[];

__attribute__((visibility("default"))) void CloudXMintegralAdapterRegister(void);

// Adapter registration class
@interface CloudXMintegralAdapter : NSObject
@end

#import "CLXMintegralInitializer.h"
#import "CLXMintegralBidTokenSource.h"
#import "CLXMintegralErrorHandler.h"
#import "CLXMintegralBaseFactory.h"
#import "CLXMintegralInterstitialFactory.h"
#import "CLXMintegralBannerFactory.h"
#import "CLXMintegralRewardedFactory.h"
