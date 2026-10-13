/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^CLXAdapterNetworkRequestStartHandler)(NSError * _Nullable * _Nullable error);

CLX_PUBLIC_ADAPTER
@interface CLXAdapterLoadParams : NSObject

/**
 * @brief Creates load parameters that allow a participating adapter to atomically
 * claim the vendor-request start boundary.
 * @param networkRequestStartHandler Handler invoked immediately before the vendor
 * request. Return @c NO to reject the request locally without invoking the vendor.
 * @return Initialized load parameters.
 */
- (instancetype)initWithNetworkRequestStartHandler:(nullable CLXAdapterNetworkRequestStartHandler)networkRequestStartHandler NS_DESIGNATED_INITIALIZER;

/**
 * @brief Claims permission to invoke the vendor load operation.
 * @param error Receives the original Core validation error, if available. Closed
 * or previously granted gates may return NO without an error.
 * @return @c YES when the adapter may invoke the vendor immediately.
 * @discussion Call after local preflight, immediately before invoking the vendor.
 * Permission commits this candidate's vendor request. A subsequent Waterfall
 * failure is terminal and cannot advance ranking. Core may deny a canceled,
 * timed-out, superseded, or completed candidate, or one whose Waterfall readiness,
 * configuration revision, or local generation changed before commitment.
 * A Core denial is final and notifies Core without requiring an adapter callback.
 * Participating adapters must not invoke the vendor after denial. Repeat calls
 * cannot grant a second request, including retries after denial; a denied gate
 * retains its original Core error. Closed/previously granted gates return NO.
 * This synchronous method may be called from any thread. Core synchronizes only
 * commitment state; lifecycle callbacks run on main outside Core locks. Invoke
 * the vendor on its required thread after this method returns YES.
 * Parameters created with @c -init or a nil handler preserve legacy behavior:
 * every call returns YES and Core does not impose a start gate.
 */
- (BOOL)tryStartNetworkRequestWithError:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
