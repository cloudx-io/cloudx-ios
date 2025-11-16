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

- (long long)extractPlacementID:(NSString *)placementIDString {
    if (!placementIDString || placementIDString.length == 0) {
        [self.logger error:@"Empty placement ID provided"];
        return 0;
    }
    
    long long placementID = [placementIDString longLongValue];
    
    if (placementID <= 0) {
        [self.logger error:[NSString stringWithFormat:@"Invalid placement ID: %@", placementIDString]];
        return 0;
    }
    
    return placementID;
}

- (BOOL)validateBidPayload:(nullable NSString *)bidPayload {
    if (!bidPayload) {
        return YES; // Valid for waterfall
    }
    
    if (bidPayload.length == 0) {
        [self.logger warning:@"Empty bid payload for header bidding"];
        return NO;
    }
    
    return YES;
}

@end

