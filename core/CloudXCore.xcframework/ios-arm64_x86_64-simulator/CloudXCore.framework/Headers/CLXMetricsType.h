/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXMetricsType.h
 * @brief Metrics type constants matching Android's sealed classes exactly
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Network call metrics types
 * Matches Android's sealed class Network(typeCode: String) : MetricsType(typeCode)
 */
extern NSString * const CLXMetricsTypeNetworkSdkInit;      // "network_call_sdk_init_req"
extern NSString * const CLXMetricsTypeNetworkGeoApi;       // "network_call_geo_req"
extern NSString * const CLXMetricsTypeNetworkBidRequest;   // "network_call_bid_req"
extern NSString * const CLXMetricsTypeNetworkTimeout;      // "network_call_timeout"
extern NSString * const CLXMetricsTypeNetworkAdapterLoad;  // "network_call_adapter_load"
extern NSString * const CLXMetricsTypeNetworkTimeToFirstAd; // "network_call_time_to_first_ad"

/**
 * Method call metrics types
 * Matches Android's sealed class Method(typeCode: String) : MetricsType(typeCode)
 */
extern NSString * const CLXMetricsTypeMethodSdkInit;           // "method_init"
extern NSString * const CLXMetricsTypeMethodCreateBanner;     // "method_create_banner"
extern NSString * const CLXMetricsTypeMethodCreateInterstitial; // "method_create_interstitial"
extern NSString * const CLXMetricsTypeMethodCreateAppOpen;    // "method_create_app_open"
extern NSString * const CLXMetricsTypeMethodCreateRewarded;   // "method_create_rewarded"
extern NSString * const CLXMetricsTypeMethodCreateMrec;       // "method_create_mrec"
extern NSString * const CLXMetricsTypeMethodCreateNative;     // "method_create_native"
extern NSString * const CLXMetricsTypeMethodSetHashedUserId;  // "method_set_hashed_user_id"
extern NSString * const CLXMetricsTypeMethodSetUserKeyValues; // "method_set_user_key_values"
extern NSString * const CLXMetricsTypeMethodSetAppKeyValues;  // "method_set_app_key_values"
extern NSString * const CLXMetricsTypeMethodBannerRefresh;    // "method_banner_refresh"
extern NSString * const CLXMetricsTypeMethodSetHasUserConsent; // "method_set_has_user_consent"
extern NSString * const CLXMetricsTypeMethodSetDoNotSell;     // "method_set_do_not_sell"

/**
 * Renderer metrics types
 *
 * In-process renderer counters that surface security and stability events.
 * Reported through `CLXRendererTelemetryFacade` (resolved at the call site to
 * the singleton `CLXMetricsTelemetryTracker`) — each metric is its own
 * named constant so dashboards can split them, and each emission carries a
 * structured `CLXRendererTelemetryContext` (auction / bid / ad-unit / format)
 * + `reason` field for grouping. Keep payload semantics aligned across SDKs
 * where applicable. Legacy renderer counters retain their `method_*` prefix
 * for wire-format stability with the previous transport.
 */
extern NSString * const CLXMetricsTypeRendererNavigationDenied;  // "method_renderer_navigation_denied"
extern NSString * const CLXMetricsTypeRendererMRAIDCloseRejected; // "method_renderer_mraid_close_rejected"
extern NSString * const CLXMetricsTypeRendererMRAIDCustomCloseIgnored; // "method_renderer_mraid_custom_close_ignored"
extern NSString * const CLXMetricsTypeRendererMRAIDUnloadRejected; // "method_renderer_mraid_unload_rejected"
extern NSString * const CLXMetricsTypeRendererMRAIDOpenDenied;    // "method_renderer_mraid_open_denied"
extern NSString * const CLXMetricsTypeRendererBridgeRejected;     // "method_renderer_bridge_rejected"

extern NSString * const CLXMetricsTypeRendererHTMLLoad;           // "renderer_html_load_ms"
extern NSString * const CLXMetricsTypeRendererVideoTTFF;          // "renderer_video_ttff_ms"
extern NSString * const CLXMetricsTypeRendererSecurityRedirectBlocked; // "renderer_security_redirect_blocked"
extern NSString * const CLXMetricsTypeRendererSecuritySchemeBlocked;   // "renderer_security_scheme_blocked"
extern NSString * const CLXMetricsTypeRendererSecurityBridgeFlood;     // "renderer_security_bridge_flood"
extern NSString * const CLXMetricsTypeRendererSecurityPayloadRejected; // "renderer_security_payload_rejected"
extern NSString * const CLXMetricsTypeRendererBlankRenderDetected;     // "renderer_blank_render_detected"
extern NSString * const CLXMetricsTypeRendererVisualBlankDetected;     // "renderer_visual_blank_detected"
extern NSString * const CLXMetricsTypeRendererVideoStart;              // "renderer_video_start"
extern NSString * const CLXMetricsTypeRendererVideoComplete;           // "renderer_video_complete"
extern NSString * const CLXMetricsTypeRendererVideoSkip;               // "renderer_video_skip"
extern NSString * const CLXMetricsTypeRendererVideoError;              // "renderer_video_error"
extern NSString * const CLXMetricsTypeRendererVideoBuffering;          // "renderer_video_buffering_ms"
extern NSString * const CLXMetricsTypeRendererHeavyAdDetected;         // "renderer_heavy_ad_detected"
extern NSString * const CLXMetricsTypeRendererWebViewCreate;           // "renderer_webview_create_ms"
extern NSString * const CLXMetricsTypeRendererCreativeSize;            // "renderer_creative_size_bytes"
extern NSString * const CLXMetricsTypeRendererViewableTime;            // "renderer_viewable_time_ms"
extern NSString * const CLXMetricsTypeRendererOMIDSessionFailure;      // "renderer_omid_session_failure"
extern NSString * const CLXMetricsTypeRendererOMIDVideoNoVerification; // "renderer_omid_video_no_verification"
extern NSString * const CLXMetricsTypeRendererDuplicateImpression;     // "renderer_duplicate_impression"
extern NSString * const CLXMetricsTypeRendererMRAIDExpand;             // "renderer_mraid_expand"
extern NSString * const CLXMetricsTypeRendererMRAIDResize;             // "renderer_mraid_resize"
extern NSString * const CLXMetricsTypeRendererMRAIDExpandError;        // "renderer_mraid_expand_error"
extern NSString * const CLXMetricsTypeRendererMRAIDResizeError;        // "renderer_mraid_resize_error"
extern NSString * const CLXMetricsTypeRendererClickLatency;            // "renderer_click_latency_ms"
extern NSString * const CLXMetricsTypeRendererClickBlocked;            // "renderer_click_blocked"
extern NSString * const CLXMetricsTypeRendererClickDestination;        // "renderer_click_destination"
// Clickthrough resolved no App Store identity (reason "no_app_id") or the
// product sheet failed to load (reason "load_failed") and the click was
// served by the openURL: fallback instead. This counter is the production
// dataset for the sheet-only (strict) decision: it measures exactly the
// clicks strict mode would drop.
extern NSString * const CLXMetricsTypeRendererStoreKitFallback;        // "renderer_storekit_fallback"
extern NSString * const CLXMetricsTypeRendererVASTUnfiredEvent;        // "renderer_vast_unfired_event"
/// VAST tracking pixel dropped. The reason field carries the drop reason —
/// the wire vocabulary is `https_required` / `url_length_exceeded` /
/// `invalid_url` / `disallowed_scheme` (rejected pre-flight at fire time) plus
/// `http_failure` (transport error / non-2xx reported post-request), for
/// cross-platform parity with Android's `renderer_vast_tracker_dropped`
/// (CXD-2414 hardened tracker). One emit per drop; not gated by the dedupe set
/// (the dedupe is for "fired once" — drops don't count toward the fired-once
/// invariant).
extern NSString * const CLXMetricsTypeRendererVASTTrackerDropped;      // "renderer_vast_tracker_dropped"

// Creative-rejection diagnostics for the open creative pool. The renderer can
// receive arbitrary VAST; these surface *why* a creative was rejected so a
// silent render failure becomes an attributable one.
//
// `renderer_vast_parse_error` — the VAST document could not be turned into a
// usable response. The reason field carries the cause: `empty_vast` (no ADM),
// `oversize_adm` (ADM/body over the size cap), `malformed_xml` (XML parse
// failure), `version_unsupported` (VAST version outside 2.0-4.3), `no_ad`
// (parsed but no usable <Ad>). Wrapper/network resolution failures do NOT
// emit this metric — they carry their VAST code via renderer_vast_error_code.
extern NSString * const CLXMetricsTypeRendererVASTParseError;          // "renderer_vast_parse_error"
// `renderer_vast_error_code` — the standard VAST error code mapped at the
// failure chokepoint, carried in the reason field as the decimal code
// (e.g. "303"). Fires for every VAST load failure, so the reason histogram is
// the full VAST error-code distribution.
extern NSString * const CLXMetricsTypeRendererVASTErrorCode;           // "renderer_vast_error_code"
// `renderer_no_compatible_media` — the VAST parsed but no playable media file
// matched the device. The reason field carries the cause: `no_linear_creative`,
// `no_supported_media` (incl. VPAID-only, IAB 403), `invalid_media_url`.
extern NSString * const CLXMetricsTypeRendererNoCompatibleMedia;       // "renderer_no_compatible_media"
// `renderer_unsupported_format` — a CloudX-rendered (embedded renderer) bid was
// dropped through the waterfall because the embedded renderer cannot serve its
// ad type or declared crtype. The reason field carries the cause:
// `native` (no embedded native renderer), `rewarded_<crtype>` for a non-VAST
// rewarded bid (e.g. `rewarded_html`, `rewarded_none` — rewarded supports VAST
// only), or `crtype_<value>` for an unsupported declared crtype. This is the
// observability surface for formats intentionally not served by the embedded
// renderer; a non-zero rate quantifies the dropped traffic that a future
// renderer would need to cover.
extern NSString * const CLXMetricsTypeRendererUnsupportedFormat;       // "renderer_unsupported_format"
extern NSString * const CLXMetricsTypeRendererLoadSuccess;             // "renderer_load_success"
extern NSString * const CLXMetricsTypeRendererLoadFailed;              // "renderer_load_failed"
extern NSString * const CLXMetricsTypeRendererRenderSuccess;           // "renderer_render_success"
extern NSString * const CLXMetricsTypeRendererRenderFailed;            // "renderer_render_failed"
extern NSString * const CLXMetricsTypeRendererWebViewCrash;            // "renderer_webview_crash"
extern NSString * const CLXMetricsTypeRendererJSError;                 // "renderer_js_error"
extern NSString * const CLXMetricsTypeRendererVideoFirstQuartile;      // "renderer_video_first_quartile"
extern NSString * const CLXMetricsTypeRendererVideoMidpoint;           // "renderer_video_midpoint"
extern NSString * const CLXMetricsTypeRendererVideoThirdQuartile;      // "renderer_video_third_quartile"
extern NSString * const CLXMetricsTypeRendererTimeToCloseEnabled;      // "renderer_time_to_close_enabled_ms"
extern NSString * const CLXMetricsTypeRendererTimeToDismiss;           // "renderer_time_to_dismiss_ms"
extern NSString * const CLXMetricsTypeRendererMemoryDelta;             // "renderer_memory_delta_bytes"
extern NSString * const CLXMetricsTypeRendererMemoryWarning;           // "renderer_memory_warning"
extern NSString * const CLXMetricsTypeRendererHTMLDownload;            // "renderer_html_download_ms"
extern NSString * const CLXMetricsTypeRendererHTMLPaint;               // "renderer_html_paint_ms"
extern NSString * const CLXMetricsTypeRendererVASTWrapperResolution;   // "renderer_vast_wrapper_resolution_ms"
extern NSString * const CLXMetricsTypeRendererVASTWrapperDepth;        // "renderer_vast_wrapper_depth"
extern NSString * const CLXMetricsTypeRendererMRAIDExpandDuration;     // "renderer_mraid_expand_ms"
extern NSString * const CLXMetricsTypeRendererMRAIDResizeDuration;     // "renderer_mraid_resize_ms"
extern NSString * const CLXMetricsTypeRendererMRAIDOpenWithoutGesture; // "renderer_mraid_open_without_gesture"
extern NSString * const CLXMetricsTypeRendererRedirectAttemptCount;    // "renderer_redirect_attempt_count"
extern NSString * const CLXMetricsTypeRendererNavigationTotalCount;    // "renderer_navigation_total_count"
extern NSString * const CLXMetricsTypeRendererExcessiveCPUDetected;    // "renderer_excessive_cpu_detected"
extern NSString * const CLXMetricsTypeRendererSecurityMRAIDOpenBlocked; // "renderer_security_mraid_open_blocked"
extern NSString * const CLXMetricsTypeRendererVerificationNotExecuted; // "renderer_verification_not_executed"
extern NSString * const CLXMetricsTypeRendererSubresourceFailure;      // "renderer_subresource_failure"
extern NSString * const CLXMetricsTypeRendererCreativeReady;           // "renderer_creative_ready"
extern NSString * const CLXMetricsTypeRendererViewabilitySummary;      // "renderer_viewability_summary"
extern NSString * const CLXMetricsTypeRendererStuckLoad;               // "renderer_stuck_load"
extern NSString * const CLXMetricsTypeRendererStuckReady;              // "renderer_stuck_ready"
extern NSString * const CLXMetricsTypeRendererStuckImpression;         // "renderer_stuck_impression"
extern NSString * const CLXMetricsTypeRendererStuckClose;              // "renderer_stuck_close"
extern NSString * const CLXMetricsTypeRendererCloseBeforeImpression;   // "renderer_close_before_impression"
extern NSString * const CLXMetricsTypeRendererDoubleShow;              // "renderer_double_show"
extern NSString * const CLXMetricsTypeRendererLongBuffering;           // "renderer_long_buffering"
extern NSString * const CLXMetricsTypeRendererMediaLoadFailure;        // "renderer_media_load_failure"
extern NSString * const CLXMetricsTypeRendererEndCardShown;            // "renderer_end_card_shown"
extern NSString * const CLXMetricsTypeRendererEndCardFailure;          // "renderer_end_card_failure"
extern NSString * const CLXMetricsTypeRendererCompanionFallback;       // "renderer_companion_fallback"
extern NSString * const CLXMetricsTypeRendererDECFallback;             // "renderer_dec_fallback"

// OMID session-creation failure paths. Each phase emits its own constant so
// dashboards can split the rate by reason without an additional payload field.
extern NSString * const CLXMetricsTypeRendererOMIDActivationFailed;    // "method_renderer_omid_activation_failed"
extern NSString * const CLXMetricsTypeRendererOMIDPartnerMissing;      // "method_renderer_omid_partner_missing"
extern NSString * const CLXMetricsTypeRendererOMIDConfigurationFailed; // "method_renderer_omid_configuration_failed"
extern NSString * const CLXMetricsTypeRendererOMIDContextFailed;       // "method_renderer_omid_context_failed"
extern NSString * const CLXMetricsTypeRendererOMIDSessionFailed;       // "method_renderer_omid_session_failed"
extern NSString * const CLXMetricsTypeRendererOMIDAdEventsFailed;      // "method_renderer_omid_ad_events_failed"
extern NSString * const CLXMetricsTypeRendererOMIDMediaEventsFailed;   // "method_renderer_omid_media_events_failed"

// Per-impression OMID fire failure. Emitted from the renderer when the
// viewability tracker hits the MRC threshold but OMID's impressionOccurred
// call fails. didTrackAdViewImpression: still fires; this metric is the system of
// record for the OMID side dropping the impression.
extern NSString * const CLXMetricsTypeRendererOMIDImpressionFireFailure; // "method_renderer_omid_impression_fire_failure"

// CLXCoreRendererAdView dealloc with no terminal delegate callback observed.
// This means the renderer was released before didLoadAdView: or failToLoad:
// reached the publisher - a leak from the publisher's perspective.
extern NSString * const CLXMetricsTypeRendererBannerLeak; // "method_renderer_banner_leak"

/**
 * Fullscreen lifecycle metrics (M2.2+)
 *
 * Per-format counterparts to CLXMetricsTypeRendererBannerLeak. Emitted when a
 * fullscreen renderer dealloc occurs without a terminal delegate callback
 * (leak) or when -presentViewController:animated:completion: completes after
 * teardown (present_failed). Reward-side constants are reserved for the
 * follow-up rewarded renderer PR; CLXRendererMetricAuditTests guards against
 * premature emission.
 */
extern NSString * const CLXMetricsTypeFullscreenInterstitialLeak;          // "fullscreen_interstitial_leak"
extern NSString * const CLXMetricsTypeFullscreenAppOpenLeak;               // "fullscreen_app_open_leak"
extern NSString * const CLXMetricsTypeFullscreenRewardedLeak;              // "fullscreen_rewarded_leak"
// present_failed counters fire from the format subclass's
// notifyDidFailToShowWithError: override and UNDERCOUNT relative to the generic
// `renderer_render_failed`: the destroyed-during-present path inside
// CLXCoreFullscreenRenderer.showFromViewController:'s completion block records
// renderer_render_failed directly and never invokes notify*, so the two
// surfaces are not strict supersets. Use renderer_render_failed for the total.
extern NSString * const CLXMetricsTypeFullscreenInterstitialPresentFailed; // "fullscreen_interstitial_present_failed"
extern NSString * const CLXMetricsTypeFullscreenAppOpenPresentFailed;      // "fullscreen_app_open_present_failed"
extern NSString * const CLXMetricsTypeFullscreenRewardedPresentFailed;     // "fullscreen_rewarded_present_failed"
extern NSString * const CLXMetricsTypeFullscreenRewardEarned;              // "fullscreen_reward_earned"
extern NSString * const CLXMetricsTypeFullscreenRewardForfeit;             // "fullscreen_reward_forfeit"

/**
 * Utility class for metrics type validation and categorization
 */
@interface CLXMetricsType : NSObject

/**
 * Check if a metric type is a network call type
 */
+ (BOOL)isNetworkCallType:(NSString *)metricType;

/**
 * Check if a metric type is a method call type
 */
+ (BOOL)isMethodCallType:(NSString *)metricType;

/**
 * Check if a metric type is a renderer metric type
 */
+ (BOOL)isRendererType:(NSString *)metricType;

/**
 * Get all network call types
 */
+ (NSArray<NSString *> *)allNetworkCallTypes;

/**
 * Get all method call types
 */
+ (NSArray<NSString *> *)allMethodCallTypes;

/**
 * Get all renderer metric types
 */
+ (NSArray<NSString *> *)allRendererTypes;

/**
 * Validate that a metric type is known
 */
+ (BOOL)isValidMetricType:(NSString *)metricType;

@end

NS_ASSUME_NONNULL_END
