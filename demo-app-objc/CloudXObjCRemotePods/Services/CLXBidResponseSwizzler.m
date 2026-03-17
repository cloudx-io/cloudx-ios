//
//  CLXBidResponseSwizzler.m
//  CloudXObjCRemotePods
//
//  Swizzles the bid network service to log full bid responses
//  for QA inspection. This is a demo app-only feature.
//

#import "CLXBidResponseSwizzler.h"
#import <objc/runtime.h>
#import <CloudXCore/CloudXCore.h>

// Static flag to track swizzling state
static BOOL _swizzlingEnabled = NO;
static IMP _originalStartAuctionIMP = NULL;
static CLXSimulatedErrorType _simulatedErrorType = CLXSimulatedErrorTypeNone;

// Forward declarations
static void swizzled_startAuctionWithBidRequest(id self, SEL _cmd, NSDictionary *bidRequest, NSString *appKey, NSTimeInterval timeout, NSString *correlationId, void (^completion)(id, NSDictionary *, NSError *));
static id sanitizeForLogging(id obj);

// Keys to collapse (large base64 blobs, tokens, debug data)
static NSSet *_keysToCollapse = nil;

@implementation CLXBidResponseSwizzler

+ (void)enableSwizzling {
    if (_swizzlingEnabled) {
        NSLog(@"[CLXBidResponseSwizzler] Swizzling already enabled");
        return;
    }
    
    // Get the CLXBidNetworkServiceClass
    Class bidNetworkServiceClass = NSClassFromString(@"CLXBidNetworkServiceClass");
    if (!bidNetworkServiceClass) {
        NSLog(@"[CLXBidResponseSwizzler] Could not find CLXBidNetworkServiceClass");
        return;
    }
    
    // Get the selector for the method we want to swizzle
    SEL originalSelector = @selector(startAuctionWithBidRequest:appKey:timeout:correlationId:completion:);
    
    Method originalMethod = class_getInstanceMethod(bidNetworkServiceClass, originalSelector);
    if (!originalMethod) {
        NSLog(@"[CLXBidResponseSwizzler] Could not find startAuctionWithBidRequest:appKey:timeout:correlationId:completion: method");
        return;
    }
    
    // Save the original implementation
    _originalStartAuctionIMP = method_getImplementation(originalMethod);
    
    // Create the new implementation
    IMP swizzledIMP = (IMP)swizzled_startAuctionWithBidRequest;
    
    // Replace the method implementation
    method_setImplementation(originalMethod, swizzledIMP);
    
    _swizzlingEnabled = YES;
    NSLog(@"[CLXBidResponseSwizzler] Swizzling enabled for bid response logging");
}

+ (void)disableSwizzling {
    if (!_swizzlingEnabled || !_originalStartAuctionIMP) {
        NSLog(@"[CLXBidResponseSwizzler] Swizzling not enabled");
        return;
    }
    
    Class bidNetworkServiceClass = NSClassFromString(@"CLXBidNetworkServiceClass");
    if (!bidNetworkServiceClass) {
        return;
    }
    
    SEL originalSelector = @selector(startAuctionWithBidRequest:appKey:timeout:correlationId:completion:);
    Method originalMethod = class_getInstanceMethod(bidNetworkServiceClass, originalSelector);
    
    if (originalMethod) {
        method_setImplementation(originalMethod, _originalStartAuctionIMP);
    }
    
    _originalStartAuctionIMP = NULL;
    _swizzlingEnabled = NO;
    NSLog(@"[CLXBidResponseSwizzler] Swizzling disabled, original behavior restored");
}

+ (BOOL)isSwizzlingEnabled {
    return _swizzlingEnabled;
}

+ (void)setSimulatedErrorType:(CLXSimulatedErrorType)errorType {
    _simulatedErrorType = errorType;
    if (errorType != CLXSimulatedErrorTypeNone) {
        [self enableSwizzling];
    }
    NSLog(@"[CLXBidResponseSwizzler] Simulated error armed: %ld", (long)errorType);
}

+ (CLXSimulatedErrorType)simulatedErrorType {
    return _simulatedErrorType;
}

@end

#pragma mark - Swizzled Method Implementation

/**
 * Swizzled implementation of startAuctionWithBidRequest:appKey:timeout:correlationId:completion:
 * 
 * This intercepts the bid response and logs it when enabled.
 */
static CLXError *createSimulatedError(CLXSimulatedErrorType type) {
    switch (type) {
        case CLXSimulatedErrorTypeHTTP400:
            return [CLXError errorWithHTTPStatusCode:400
                                      serverMessage:@"Invalid request: request.imp[0].ext.prebid.bidder.vungle failed validation.\nplacementId: Does not match minimum length of 1"];
        case CLXSimulatedErrorTypeHTTP500:
            return [CLXError errorWithHTTPStatusCode:500
                                      serverMessage:@"Internal Server Error"];
        case CLXSimulatedErrorTypeNoFill:
            return [CLXError errorWithCode:CLXErrorCodeNoFill
                               description:@"No ad available - simulated no fill"];
        default:
            return nil;
    }
}

static void swizzled_startAuctionWithBidRequest(id self, SEL _cmd, NSDictionary *bidRequest, NSString *appKey, NSTimeInterval timeout, NSString *correlationId, void (^completion)(id, NSDictionary *, NSError *)) {
    
    // Check for armed simulated error — fire once then reset
    CLXSimulatedErrorType armedError = _simulatedErrorType;
    if (armedError != CLXSimulatedErrorTypeNone) {
        _simulatedErrorType = CLXSimulatedErrorTypeNone;
        CLXError *simulatedError = createSimulatedError(armedError);
        CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"QA-ErrorSim"];
        [logger info:[NSString stringWithFormat:@"Injecting simulated error (type=%ld): %@ | reason: %@",
                      (long)armedError,
                      simulatedError.localizedDescription,
                      simulatedError.localizedFailureReason ?: @"(none)"]];
        if (completion) {
            completion(nil, nil, simulatedError);
        }
        return;
    }
    
    // Wrap completion to optionally log the bid response (QA feature)
    void (^wrappedCompletion)(id, NSDictionary *, NSError *) = ^(id parsedResponse, NSDictionary *rawResponse, NSError *error) {
        
        // Check if QA logging is enabled
        BOOL shouldPrintBidResponse = [[NSUserDefaults standardUserDefaults] boolForKey:@"DemoApp.PrintBidResponse"];
        
        if (shouldPrintBidResponse && rawResponse) {
            // Sanitize response - collapse large blobs into placeholders
            id sanitized = sanitizeForLogging(rawResponse);
            
            NSError *jsonError;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:sanitized 
                                                               options:(NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys)
                                                                 error:&jsonError];
            CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"QA-BidResponse"];
            if (jsonData && !jsonError) {
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                [logger verbose:[NSString stringWithFormat:@"FULL BID RESPONSE:\n%@", jsonString]];
            } else {
                [logger verbose:[NSString stringWithFormat:@"FULL BID RESPONSE (raw):\n%@", sanitized]];
            }
        }
        
        // Call original completion
        if (completion) {
            completion(parsedResponse, rawResponse, error);
        }
    };
    
    // Call original implementation with wrapped completion
    typedef void (*OriginalFunction)(id, SEL, NSDictionary *, NSString *, NSTimeInterval, NSString *, void (^)(id, NSDictionary *, NSError *));
    OriginalFunction originalFunc = (OriginalFunction)_originalStartAuctionIMP;
    originalFunc(self, _cmd, bidRequest, appKey, timeout, correlationId, wrappedCompletion);
}

#pragma mark - Sanitization Helper

/**
 * Recursively sanitize objects for logging - collapse large strings and debug data
 */
static id sanitizeForLogging(id obj) {
    // Initialize keys to collapse on first use
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _keysToCollapse = [NSSet setWithObjects:
            // Large base64 blobs
            @"auctionAttestationCoseGzipBase64",
            @"attestation_cose_gzip_base64",
            @"auction_attestation",
            @"bidder_token",
            @"bid_token",
            @"buyeruid",
            // Debug/trace data (very large nested objects)
            @"debug",
            @"httpcalls",
            @"requestbody",
            @"responsebody",
            @"requestheaders",
            // Other large fields
            @"adm",
            @"public_key",
            nil];
    });
    
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *result = [NSMutableDictionary dictionary];
        for (NSString *key in obj) {
            id value = obj[key];
            
            // Check if this key should be collapsed
            if ([_keysToCollapse containsObject:key]) {
                if ([value isKindOfClass:[NSString class]]) {
                    NSUInteger len = [(NSString *)value length];
                    result[key] = [NSString stringWithFormat:@"<collapsed string: %lu chars>", (unsigned long)len];
                } else if ([value isKindOfClass:[NSDictionary class]]) {
                    result[key] = @"<collapsed object>";
                } else if ([value isKindOfClass:[NSArray class]]) {
                    result[key] = [NSString stringWithFormat:@"<collapsed array: %lu items>", (unsigned long)[(NSArray *)value count]];
                } else {
                    result[key] = @"<collapsed>";
                }
            } else {
                // Recursively sanitize
                result[key] = sanitizeForLogging(value);
            }
        }
        return result;
    } else if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *result = [NSMutableArray array];
        for (id item in obj) {
            [result addObject:sanitizeForLogging(item)];
        }
        return result;
    } else {
        // Return primitives as-is
        return obj;
    }
}
