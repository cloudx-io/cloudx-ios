//
//  CLXMobileFuseInitializer.h
//  CloudXMobileFuseAdapter
//

#import <CloudXCore/CLXAdapterInitializationParams.h>
#import <CloudXCore/CLXAdapterInitializer.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMobileFuseInitializer : CLXAdapterInitializer

@property (nonatomic, copy, readonly) NSString *sdkVersion;
@property (nonatomic, copy, readonly) NSString *network;

/**
 * Returns the publisher-declared test mode flag. Bidder-signals requests inherit
 * this on a per-request basis (MobileFuseSDK 1.11+ does not expose a global
 * setter).
 */
+ (BOOL)isTestMode;

/**
 * Returns the cached MobileFuse network SDK version string, falling back to the network SDK
 * version this adapter pins when it has not yet been primed. Never returns an empty string.
 * Never blocks and never hops to the main queue, so it is safe to call from latency-sensitive
 * paths and from arbitrary threads.
 */
+ (NSString *)sdkVersion;

#if defined(DEBUG) || defined(TESTING)
/**
 * Test-only seams. They let unit tests exercise the init FSM and the
 * pending-completion queue without standing up the real MobileFuse SDK
 * (which can race the test's synthetic callbacks in a test runner).
 * Production callers must never invoke these methods.
 */
+ (void)__resetStateForTesting;

// Transitions the FSM to InFlight and enqueues `completion` as if a
// publisher had called -initializeWithParams: while
// init was already pending — but WITHOUT actually invoking
// [MobileFuse initWithDelegate:]. Tests can then drive the queue drain
// deterministically by calling the simulate-* seams below.
+ (void)__primeInFlightWithCompletionForTesting:(CLXAdapterInitializationCompletion)completion;

// Mirror the MobileFuse SDK's success and failure callbacks for tests
// without exposing the IMFInitializationCallbackReceiver conformance
// publicly (which would force every header consumer to import a
// MobileFuse type) and without making tests cast the initializer to
// see the protocol selectors.
- (void)__simulateSdkInitSuccessForTesting;
- (void)__simulateSdkInitFailureForTesting;
#endif

@end

NS_ASSUME_NONNULL_END
