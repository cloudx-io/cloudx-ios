#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CLXNativeTemplate) {
    CLXNativeTemplateSmall = 0,
    CLXNativeTemplateMedium,
    CLXNativeTemplateSmallWithCloseButton,
    CLXNativeTemplateMediumWithCloseButton,
    CLXNativeTemplateDefault = CLXNativeTemplateMedium
};

@interface CLXNativeTemplateHelper : NSObject

+ (NSDictionary *)nativeAdRequirementsForTemplate:(CLXNativeTemplate)templateType;

@end

NS_ASSUME_NONNULL_END 