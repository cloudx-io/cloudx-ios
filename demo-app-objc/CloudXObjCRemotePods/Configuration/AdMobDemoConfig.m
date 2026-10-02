#import "AdMobDemoConfig.h"

@implementation AdMobDemoConfig

+ (NSString *)interstitialAdUnitId {
    static NSString *adUnitId;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *override = [[NSUserDefaults standardUserDefaults] stringForKey:@"DemoApp.AdMobInterstitialAdUnitId"];
        adUnitId = override.length > 0 ? [override copy] : @"ca-app-pub-3940256099942544/4411468910";
    });
    return adUnitId;
}

+ (nullable NSNumber *)manualRevenuePerImpressionUSD {
    static NSNumber *price;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *text = [[NSUserDefaults standardUserDefaults] stringForKey:@"DemoApp.AdMobManualRevenuePerImpressionUSD"];
        if (!text) return;
        NSScanner *scanner = [NSScanner scannerWithString:text];
        double value = 0;
        if ([scanner scanDouble:&value] && scanner.isAtEnd && isfinite(value) && value >= 0) {
            price = @(value);
        }
    });
    return price;
}

@end
