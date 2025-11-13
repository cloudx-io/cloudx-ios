//
// NSError+DemoDescription.h
// CloudXObjCRemotePods
//
// Category for providing detailed, user-friendly error descriptions in the demo app
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSError (DemoDescription)

/**
 * Returns a detailed, user-friendly error description suitable for display in alerts.
 * Includes error code, domain, description, and relevant userInfo details.
 * 
 * @return Formatted multi-line error description
 */
- (NSString *)detailedDemoDescription;

@end

NS_ASSUME_NONNULL_END

