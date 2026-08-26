//
//  CLXGamAdFormat.h
//  CloudXGAMPrebid
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** Ad formats surfaced through the GAM prebid integration. */
typedef NS_ENUM(NSInteger, CLXGamAdFormat) {
    CLXGamAdFormatInterstitial,
    CLXGamAdFormatRewarded,
    CLXGamAdFormatBanner,
    CLXGamAdFormatMREC,
    CLXGamAdFormatNative,
};

/** Wire name for a format, matching the Android `GamAdFormat.name` strings. */
FOUNDATION_EXPORT NSString *CLXGamAdFormatWireName(CLXGamAdFormat format);

NS_ASSUME_NONNULL_END
