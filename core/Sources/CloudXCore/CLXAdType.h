//
//  CLXAdType.h
//  CloudXCore
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Enumeration of all supported ad types in the CloudX SDK
 */
typedef NS_ENUM(NSInteger, CLXAdType) {
    CLXAdTypeInterstitial = 0,
    CLXAdTypeRewarded = 1,
    CLXAdTypeBanner = 2,
    CLXAdTypeMrec = 3,
    CLXAdTypeNative = 4
};

NS_ASSUME_NONNULL_END
