#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXSDKConfigRequestFormat : NSObject
@property (nonatomic, assign) NSInteger w;
@property (nonatomic, assign) NSInteger h;
@end

@interface CLXSDKConfigRequestBanner : NSObject
@property (nonatomic, strong) NSArray<CLXSDKConfigRequestFormat *> *format;
@end

@interface CLXSDKConfigRequestImp : NSObject
@property (nonatomic, copy) NSString *id;
@property (nonatomic, strong, nullable) CLXSDKConfigRequestBanner *banner;
@end

@interface CLXSDKConfigRequest : NSObject

@property (nonatomic, copy) NSString *bundle;
@property (nonatomic, copy) NSString *os;
@property (nonatomic, copy) NSString *osVersion;
@property (nonatomic, copy) NSString *model;
@property (nonatomic, copy) NSString *vendor;
@property (nonatomic, copy) NSString *ifa;
@property (nonatomic, copy) NSString *ifv;
@property (nonatomic, copy) NSString *sdkVersion;
@property (nonatomic, assign) BOOL dnt;
@property (nonatomic, strong) NSArray<CLXSDKConfigRequestImp *> *imp;
@property (nonatomic, copy) NSString *id;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *urlParams;

- (NSDictionary *)json;

@end

NS_ASSUME_NONNULL_END 