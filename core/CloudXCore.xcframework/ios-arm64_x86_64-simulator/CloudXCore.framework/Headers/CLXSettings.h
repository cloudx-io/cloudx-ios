#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXSettings : NSObject

+ (instancetype)sharedInstance;

// MARK: - IFA Configuration

/// Retrieves the Identifier for Advertising (IFA) based on a priority system.
/// Priority: UserDefaults override > Real device IDFA > Placeholder (if no IDFA available)
- (NSString *)getIFA;

// MARK: - Location Controls

/// Whether the SDK is permitted to include IP-derived coordinates in bid requests.
/// Default is YES (backward compatible). When NO, lat/lon are omitted from bid requests.
@property (nonatomic, assign) BOOL locationSharingEnabled;

@end

NS_ASSUME_NONNULL_END
