//
//  UserDefaultsSettings.h
//  CloudXObjCRemotePods
//
//  Created by Xenoss on 15.09.2025.
//

#import <Foundation/Foundation.h>

@interface UserDefaultsSettings : NSObject

@property (nonatomic, copy) NSString *appKey;
@property (nonatomic, copy) NSString *SDKinitURL;
@property (nonatomic, copy) NSString *bannerAdUnitId;
@property (nonatomic, copy) NSString *mrecAdUnitId;
@property (nonatomic, copy) NSString *interstitialAdUnitId;
@property (nonatomic, copy) NSString *rewardedAdUnitId;
@property (nonatomic, copy) NSString *nativeSmallAdUnitId;
@property (nonatomic, copy) NSString *nativeMediumAdUnitId;
@property (nonatomic, copy) NSString *consentString;
@property (nonatomic, copy) NSString *usPrivacyString;
@property (nonatomic, copy) NSString *hashedUserId;
@property (nonatomic, assign) BOOL userTargeting;

+ (instancetype)sharedSettings;

@end
