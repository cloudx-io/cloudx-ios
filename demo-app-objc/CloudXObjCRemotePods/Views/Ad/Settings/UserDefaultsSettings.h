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
@property (nonatomic, copy) NSString *bannerPlacement;
@property (nonatomic, copy) NSString *mrecPlacement;
@property (nonatomic, copy) NSString *interstitialPlacement;
@property (nonatomic, copy) NSString *rewardedPlacement;
@property (nonatomic, copy) NSString *nativeSmallPlacement;
@property (nonatomic, copy) NSString *nativeMediumPlacement;
@property (nonatomic, copy) NSString *consentString;
@property (nonatomic, copy) NSString *usPrivacyString;
@property (nonatomic, assign) BOOL userTargeting;

+ (instancetype)sharedSettings;

@end
