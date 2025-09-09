//
//  CloudXNativeAdData.h
//  CloudXTestVastNetworkAdapter
//
//  Created by bkorda on 09.05.2024.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CloudXNativeAdData : NSObject

@property (nonatomic, strong, readonly) NSString *mainImgURL;
@property (nonatomic, strong, readonly) NSString *appIconURL;
@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) NSString *descriptionText;
@property (nonatomic, strong, readonly) NSString *sponsored;
@property (nonatomic, strong, readonly) NSString *rating;
@property (nonatomic, strong, readonly) NSString *ctatext;
@property (nonatomic, strong, readonly) NSString *ctaLink;
@property (nonatomic, assign, readonly) CLXNativeTemplate nativeAdType;

+ (nullable instancetype)parseFromJSON:(NSString *)jsonString;

@end

NS_ASSUME_NONNULL_END 