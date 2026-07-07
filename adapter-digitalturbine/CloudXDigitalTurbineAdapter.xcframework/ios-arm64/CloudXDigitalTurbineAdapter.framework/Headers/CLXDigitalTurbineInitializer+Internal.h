//
//  CLXDigitalTurbineInitializer+Internal.h
//  CloudXDigitalTurbineAdapter
//

#if __has_include(<CloudXDigitalTurbineAdapter/CLXDigitalTurbineInitializer.h>)
#import <CloudXDigitalTurbineAdapter/CLXDigitalTurbineInitializer.h>
#else
#import "CLXDigitalTurbineInitializer.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/// Init lifecycle state. Reads + writes are serialized through the
/// initializer's serial queue so concurrent callers cannot double-fire the
/// underlying SDK init.
///   - kCLXDTInitStateIdle       no init in flight; first caller will start one
///   - kCLXDTInitStateStarting   init in flight; new callers queue their completion
///   - kCLXDTInitStateCompleted  init resolved; completion fired with cached result
typedef NS_ENUM(NSInteger, CLXDTInitState) {
    kCLXDTInitStateIdle = 0,
    kCLXDTInitStateStarting,
    kCLXDTInitStateCompleted,
};

/// The action `initializeWithParams:` should take for a given input. Kept
/// separate from its side effects (queue hops, SDK calls, completion firing) so
/// the branch selection is a pure function that can be unit-tested directly
/// without driving the third-party SDK singleton.
typedef NS_ENUM(NSInteger, CLXDTInitDecision) {
    kCLXDTInitDecisionReplayCached = 0,   // init already resolved; replay cached result
    kCLXDTInitDecisionQueueCompletion,    // init in flight; queue this completion
    kCLXDTInitDecisionDeferToExisting,    // shared Fyber SDK already up; defer without owning init
    kCLXDTInitDecisionFailInvalidAppID,   // no app id; cannot own an init
    kCLXDTInitDecisionStartInit,          // own the init
};

@interface CLXDigitalTurbineInitializer (Internal)

/// Pure init-state-machine decision. No globals, no IASDKCore, no queue — the
/// inputs fully determine the result. The imperative shell in
/// `initializeWithParams:` gathers the inputs and performs the side effects for
/// the returned decision.
///
/// @param state The current init lifecycle state.
/// @param fyberAlreadyInitialised Whether the shared Fyber SDK is already up
///        (e.g. initialised by a co-resident mediator).
/// @param hasAppID Whether a non-empty app id is available to own an init.
/// @return The action the caller should perform.
+ (CLXDTInitDecision)initDecisionForState:(CLXDTInitState)state
                  fyberAlreadyInitialised:(BOOL)fyberAlreadyInitialised
                                 hasAppID:(BOOL)hasAppID;

@end

NS_ASSUME_NONNULL_END
