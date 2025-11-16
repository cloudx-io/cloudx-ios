//
//  CloudXMolocoAdapter.h
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double CloudXMolocoAdapterVersionNumber;
FOUNDATION_EXPORT const unsigned char CloudXMolocoAdapterVersionString[];

// Registration function for static frameworks
__attribute__((visibility("default"))) void CloudXMolocoAdapterRegister(void);

// Public headers
#import "CLXMolocoInitializer.h"
#import "CLXMolocoBidTokenSource.h"
#import "CLXMolocoErrorHandler.h"
#import "CLXMolocoBaseFactory.h"

// Ad Format Factories
#import "CLXMolocoInterstitialFactory.h"
#import "CLXMolocoBannerFactory.h"
#import "CLXMolocoRewardedFactory.h"
#import "CLXMolocoNativeFactory.h"

