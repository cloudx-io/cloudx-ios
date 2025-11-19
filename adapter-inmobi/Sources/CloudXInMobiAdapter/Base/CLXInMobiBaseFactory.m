//
//  CLXInMobiBaseFactory.m
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#import "CLXInMobiBaseFactory.h"
#import <CloudXCore/CLXLogger.h>

@implementation CLXInMobiBaseFactory

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXInMobiBaseFactory"];
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
    // Bid payload is optional (waterfall ads don't need it)
    if (!bidPayload) {
        return YES; // Valid for waterfall
    }
    
    // For header bidding, payload should not be empty
    if (bidPayload.length == 0) {
        [self.logger warn:@"Empty bid payload provided for header bidding"];
        return NO;
    }
    
    return YES;
}

@end

