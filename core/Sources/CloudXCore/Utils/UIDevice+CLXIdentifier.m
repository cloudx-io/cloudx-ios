#import <CloudXCore/UIDevice+CLXIdentifier.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

@implementation UIDevice (Identifier)

+ (NSString *)deviceIdentifier {
    static NSString *identifier = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct utsname systemInfo;
        uname(&systemInfo);
        identifier = @(systemInfo.machine);
    });
    return identifier;
}

@end
