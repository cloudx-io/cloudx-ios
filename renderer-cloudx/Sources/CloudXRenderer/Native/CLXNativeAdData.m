//
//  CloudXNativeAdData.m
//  CloudXTestVastNetworkAdapter
//
//

#import "CLXNativeAdData.h"
#import <CloudXCore/CLXLogger.h>

@interface CloudXNativeAdData ()

@property (nonatomic, strong) NSString *mainImgURL;
@property (nonatomic, strong) NSString *appIconURL;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *descriptionText;
@property (nonatomic, strong) NSString *sponsored;
@property (nonatomic, strong) NSString *rating;
@property (nonatomic, strong) NSString *ctatext;
@property (nonatomic, strong) NSString *ctaLink;
@property (nonatomic, assign) CLXNativeTemplate nativeAdType;

@end

@implementation CloudXNativeAdData

+ (nullable instancetype)parseFromJSON:(NSString *)jsonString {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CloudXNativeAdData"];
    [logger debug:@"[CloudXNativeAdData] parseFromJSON called"];
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    if (!jsonData) {
        [logger error:@"[CloudXNativeAdData] Failed to convert jsonString to NSData."];
        return nil;
    }
    
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (error || ![json isKindOfClass:[NSDictionary class]]) {
        [logger error:[NSString stringWithFormat:@"[CloudXNativeAdData] JSON parsing error: %@", error]];
        return nil;
    }
    
    NSDictionary *nativeDict = json[@"native"];
    if (![nativeDict isKindOfClass:[NSDictionary class]]) {
        [logger error:@"[CloudXNativeAdData] 'native' key not found or not a dictionary."];
        return nil;
    }
    
    CloudXNativeAdData *adData = [[CloudXNativeAdData alloc] init];
    [adData parseFromDictionary:nativeDict];
    [logger info:@"[CloudXNativeAdData] Successfully parsed ad data."];
    return adData;
}

- (void)parseFromDictionary:(NSDictionary *)nativeDict {
    NSArray *assets = nativeDict[@"assets"];
    if (![assets isKindOfClass:[NSArray class]]) {
        return;
    }
    
    // Parse main image URL
    for (NSDictionary *asset in assets) {
        if ([asset isKindOfClass:[NSDictionary class]]) {
            NSNumber *assetId = asset[@"id"];
            if ([assetId integerValue] == 3) { // main image
                NSDictionary *img = asset[@"img"];
                if ([img isKindOfClass:[NSDictionary class]]) {
                    self.mainImgURL = img[@"url"];
                }
                break;
            }
        }
    }
    
    // Parse app icon URL
    for (NSDictionary *asset in assets) {
        if ([asset isKindOfClass:[NSDictionary class]]) {
            NSNumber *assetId = asset[@"id"];
            if ([assetId integerValue] == 1) { // icon
                NSDictionary *img = asset[@"img"];
                if ([img isKindOfClass:[NSDictionary class]]) {
                    self.appIconURL = img[@"url"];
                }
                break;
            }
        }
    }
    
    // Parse title
    for (NSDictionary *asset in assets) {
        if ([asset isKindOfClass:[NSDictionary class]]) {
            NSDictionary *title = asset[@"title"];
            if ([title isKindOfClass:[NSDictionary class]]) {
                self.title = title[@"text"];
                break;
            }
        }
    }
    
    // Parse description
    for (NSDictionary *asset in assets) {
        if ([asset isKindOfClass:[NSDictionary class]]) {
            NSNumber *assetId = asset[@"id"];
            if ([assetId integerValue] == 2) { // description
                NSDictionary *data = asset[@"data"];
                if ([data isKindOfClass:[NSDictionary class]]) {
                    self.descriptionText = data[@"value"];
                }
                break;
            }
        }
    }
    
    // Parse sponsored
    for (NSDictionary *asset in assets) {
        if ([asset isKindOfClass:[NSDictionary class]]) {
            NSNumber *assetId = asset[@"id"];
            if ([assetId integerValue] == 1) { // sponsored
                NSDictionary *data = asset[@"data"];
                if ([data isKindOfClass:[NSDictionary class]]) {
                    self.sponsored = data[@"value"];
                }
                break;
            }
        }
    }
    
    // Parse rating
    for (NSDictionary *asset in assets) {
        if ([asset isKindOfClass:[NSDictionary class]]) {
            NSNumber *assetId = asset[@"id"];
            if ([assetId integerValue] == 3) { // rating
                NSDictionary *data = asset[@"data"];
                if ([data isKindOfClass:[NSDictionary class]]) {
                    self.rating = data[@"value"];
                }
                break;
            }
        }
    }
    
    // Parse CTA text
    for (NSDictionary *asset in assets) {
        if ([asset isKindOfClass:[NSDictionary class]]) {
            NSNumber *assetId = asset[@"id"];
            if ([assetId integerValue] == 12) { // cta text
                NSDictionary *data = asset[@"data"];
                if ([data isKindOfClass:[NSDictionary class]]) {
                    self.ctatext = data[@"value"];
                }
                break;
            }
        }
    }
    
    // Parse CTA link
    NSDictionary *link = nativeDict[@"link"];
    if ([link isKindOfClass:[NSDictionary class]]) {
        self.ctaLink = link[@"url"];
    } else {
        // Fallback to asset link
        for (NSDictionary *asset in assets) {
            if ([asset isKindOfClass:[NSDictionary class]]) {
                NSDictionary *assetLink = asset[@"link"];
                if ([assetLink isKindOfClass:[NSDictionary class]]) {
                    self.ctaLink = assetLink[@"url"];
                    break;
                }
            }
        }
    }
    
    // Determine native ad type
    BOOL hasVideo = NO;
    BOOL hasMainImage = NO;
    
    for (NSDictionary *asset in assets) {
        if ([asset isKindOfClass:[NSDictionary class]]) {
            if (asset[@"video"]) {
                hasVideo = YES;
            }
            NSNumber *assetId = asset[@"id"];
            if ([assetId integerValue] == 3 && asset[@"img"]) {
                hasMainImage = YES;
            }
        }
    }
    
    CLXNativeTemplate template = CLXNativeTemplateMedium;
    if (hasVideo || hasMainImage) {
        template = CLXNativeTemplateMedium;
    } else {
        template = CLXNativeTemplateSmall;
    }
}

@end 