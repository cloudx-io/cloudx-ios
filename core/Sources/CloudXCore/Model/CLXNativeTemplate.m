#import <CloudXCore/CLXNativeTemplate.h>

@implementation CLXNativeTemplateHelper

+ (CGSize)sizeForTemplate:(CLXNativeTemplate)templateType {
    switch (templateType) {
        case CLXNativeTemplateMedium:
            return CGSizeMake(320, 250);
        case CLXNativeTemplateSmall:
            return CGSizeMake(320, 90);
        case CLXNativeTemplateSmallWithCloseButton:
            return CGSizeMake(320, 90);
        case CLXNativeTemplateMediumWithCloseButton:
            return CGSizeMake(320, 250);
    }
}

+ (NSString *)stringValueForTemplate:(CLXNativeTemplate)templateType {
    switch (templateType) {
        case CLXNativeTemplateSmall:
            return @"small";
        case CLXNativeTemplateMedium:
            return @"medium";
        case CLXNativeTemplateSmallWithCloseButton:
            return @"smallWithCloseButton";
        case CLXNativeTemplateMediumWithCloseButton:
            return @"mediumWithCloseButton";
    }
}

+ (CLXNativeTemplate)templateFromString:(NSString *)string {
    if ([string isEqualToString:@"small"]) {
        return CLXNativeTemplateSmall;
    } else if ([string isEqualToString:@"medium"]) {
        return CLXNativeTemplateMedium;
    } else if ([string isEqualToString:@"smallWithCloseButton"]) {
        return CLXNativeTemplateSmallWithCloseButton;
    } else if ([string isEqualToString:@"mediumWithCloseButton"]) {
        return CLXNativeTemplateMediumWithCloseButton;
    }
    return CLXNativeTemplateSmall; // Default
}

+ (NSDictionary *)nativeAdRequirementsForTemplate:(CLXNativeTemplate)templateType {
    // Create the native ad requirements dictionary based on Swift NativeAdRequirements
    NSMutableDictionary *requirements = [NSMutableDictionary dictionary];
    requirements[@"ver"] = @"1.2";
    requirements[@"context"] = @1; // content
    requirements[@"privacy"] = @1;
    
    // Create assets array
    NSMutableArray *assets = [NSMutableArray array];
    
    // App icon asset (ID: 2)
    NSDictionary *appIconAsset = @{
        @"id": @2,
        @"required": @1,
        @"img": @{
            @"type": @1, // icon
            @"wmin": @1,
            @"hmin": @1
        }
    };
    [assets addObject:appIconAsset];
    
    // Title asset (ID: 7)
    NSDictionary *titleAsset = @{
        @"id": @7,
        @"required": @1,
        @"title": @{
            @"len": @25
        }
    };
    [assets addObject:titleAsset];
    
    // Sponsored text asset (ID: 4)
    NSDictionary *sponsoredAsset = @{
        @"id": @4,
        @"required": @0,
        @"data": @{
            @"type": @1, // sponsored
            @"len": @30
        }
    };
    [assets addObject:sponsoredAsset];
    
    // Description text asset (ID: 5)
    NSDictionary *descriptionAsset = @{
        @"id": @5,
        @"required": @0,
        @"data": @{
            @"type": @2, // desc
            @"len": @90
        }
    };
    [assets addObject:descriptionAsset];
    
    // Rating asset (ID: 6)
    NSDictionary *ratingAsset = @{
        @"id": @6,
        @"required": @1,
        @"data": @{
            @"type": @3, // rating
            @"len": @10
        }
    };
    [assets addObject:ratingAsset];
    
    // CTA asset (ID: 3)
    NSDictionary *ctaAsset = @{
        @"id": @3,
        @"required": @1,
        @"data": @{
            @"type": @12, // ctatext
            @"len": @15
        }
    };
    [assets addObject:ctaAsset];
    
    // Add main image and video for medium templates
    if (templateType == CLXNativeTemplateMedium || templateType == CLXNativeTemplateMediumWithCloseButton) {
        // Main image asset (ID: 1)
        NSDictionary *mainImageAsset = @{
            @"id": @1,
            @"required": @1,
            @"img": @{
                @"type": @3, // main
                @"wmin": @1,
                @"hmin": @1
            }
        };
        [assets addObject:mainImageAsset];
        
        // Video asset (ID: 8)
        NSDictionary *videoAsset = @{
            @"id": @8,
            @"required": @0,
            @"video": @{
                @"mimes": @[@"video/mp4", @"video/quicktime"],
                @"minduration": @1,
                @"maxduration": @30,
                @"protocols": @[@2, @3, @5, @6, @7, @8]
            }
        };
        [assets addObject:videoAsset];
    }
    
    requirements[@"assets"] = assets;
    
    // Create event trackers
    NSArray *eventTrackers = @[
        @{
            @"event": @1, // impression
            @"methods": @[@1] // img
        },
        @{
            @"event": @2, // viewableMRC50
            @"methods": @[@1] // img
        },
        @{
            @"event": @3, // viewableMRC100
            @"methods": @[@1] // img
        },
        @{
            @"event": @4, // viewableVideo50
            @"methods": @[@1] // img
        }
    ];
    requirements[@"eventtrackers"] = eventTrackers;
    
    return [requirements copy];
}

@end 