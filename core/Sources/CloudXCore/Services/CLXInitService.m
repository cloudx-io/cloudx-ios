#import <CloudXCore/CLXInitService.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXLogger.h>

@interface CLXLiveInitService : NSObject <CLXInitService>
@property (nonatomic, strong) CLXLogger *logger;
@end 