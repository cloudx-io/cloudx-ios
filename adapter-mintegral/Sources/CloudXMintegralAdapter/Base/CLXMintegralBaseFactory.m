#import "CLXMintegralBaseFactory.h"
#import <CloudXCore/CLXLogger.h>

@implementation CLXMintegralBaseFactory

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMintegralBaseFactory"];
    }
    return self;
}

- (NSString *)extractPlacementID:(NSString *)placementIDString {
    if (!placementIDString || placementIDString.length == 0) {
        [self.logger error:@"Empty placement ID provided"];
        return @"";
    }
    
    return placementIDString;
}

- (BOOL)validateBidPayload:(nullable NSString *)bidPayload {
    if (!bidPayload) {
        return YES;
    }
    
    if (bidPayload.length == 0) {
        [self.logger warning:@"Empty bid payload for header bidding"];
        return NO;
    }
    
    return YES;
}

@end

