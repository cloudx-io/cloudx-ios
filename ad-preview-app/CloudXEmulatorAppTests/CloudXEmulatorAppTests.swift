import XCTest
@testable import CloudXAdPreview

final class CloudXAdPreviewTests: XCTestCase {

    func testDeepLinkParser_RequiresAppKey() {
        let parser = DeepLinkParser()
        let url = URL(string: "cloudxemulator://load?ad_unit_id=abc")!

        let result = parser.parse(url)

        XCTAssertEqual(result, .failure(.missingAppKey))
    }

    func testDeepLinkParser_PrefersAdUnitIdAndAppliesDefaults() {
        let parser = DeepLinkParser()
        let url = URL(string: "cloudxemulator://load?app_key=test_key&ad_unit_id=unitA&placement=unitB")!

        let result = parser.parse(url)

        switch result {
        case .failure:
            XCTFail("Expected parser success")
        case .success(let request):
            XCTAssertEqual(request.appKey, "test_key")
            XCTAssertEqual(request.adUnitId, "unitA")
            XCTAssertEqual(request.format, .banner)
            XCTAssertEqual(request.env, .production)
        }
    }

    func testDeepLinkParser_NormalizesFormatAndEnvironment() {
        let parser = DeepLinkParser()
        let url = URL(string: "cloudxemulator://load?app_key=abc&placement=p1&format=unknown&env=staging")!

        let result = parser.parse(url)

        switch result {
        case .failure:
            XCTFail("Expected parser success")
        case .success(let request):
            XCTAssertEqual(request.format, .banner)
            XCTAssertEqual(request.env, .staging)
        }
    }

    func testDeepLinkParser_CollectsOnlyAllowlistedOverrides() {
        let parser = DeepLinkParser()
        let url = URL(string: "cloudxemulator://load?app_key=abc&placement=p1&bundle_id=com.test&geo_country=US&bid_price_overrides=meta:1.20,vungle:0.95&unknown_key=ignore")!

        let result = parser.parse(url)

        switch result {
        case .failure:
            XCTFail("Expected parser success")
        case .success(let request):
            XCTAssertEqual(request.overrides["bundle_id"], "com.test")
            XCTAssertEqual(request.overrides["geo_country"], "US")
            XCTAssertEqual(request.overrides["bid_price_overrides"], "meta:1.20,vungle:0.95")
            XCTAssertNil(request.overrides["unknown_key"])
        }
    }

    func testNeedsInitializationDecision() {
        let request = DeepLinkLoadRequest(
            appKey: "keyA",
            adUnitId: "adA",
            format: .banner,
            env: .production,
            overrides: [:]
        )

        XCTAssertTrue(EmulatorLogic.needsInitialization(
            sdkInitialized: false,
            initializedAppKey: nil,
            initializedEnv: nil,
            request: request
        ))

        XCTAssertFalse(EmulatorLogic.needsInitialization(
            sdkInitialized: true,
            initializedAppKey: "keyA",
            initializedEnv: .production,
            request: request
        ))

        XCTAssertTrue(EmulatorLogic.needsInitialization(
            sdkInitialized: true,
            initializedAppKey: "keyB",
            initializedEnv: .production,
            request: request
        ))
    }

    func testResolvePostInitLoadDelay_InvalidAndClamped() {
        let invalid = EmulatorLogic.resolvePostInitLoadDelay(rawValue: "abc")
        XCTAssertEqual(invalid.delayMs, 3000)
        XCTAssertEqual(invalid.diagnostic, .invalid(value: "abc", fallbackMs: 3000))

        let clamped = EmulatorLogic.resolvePostInitLoadDelay(rawValue: "50000")
        XCTAssertEqual(clamped.delayMs, 10000)
        XCTAssertEqual(clamped.diagnostic, .clamped(requestedMs: 50000, appliedMs: 10000))

        let exact = EmulatorLogic.resolvePostInitLoadDelay(rawValue: "750")
        XCTAssertEqual(exact.delayMs, 750)
    }

    func testRetryableFirstLoadErrorCodes() {
        XCTAssertTrue(EmulatorLogic.isRetryableFirstLoadError(code: 101))
        XCTAssertTrue(EmulatorLogic.isRetryableFirstLoadError(code: 302))
        XCTAssertTrue(EmulatorLogic.isRetryableFirstLoadError(code: 601))
        XCTAssertTrue(EmulatorLogic.isRetryableFirstLoadError(code: 609))
        XCTAssertTrue(EmulatorLogic.isRetryableFirstLoadError(code: 610))
        XCTAssertFalse(EmulatorLogic.isRetryableFirstLoadError(code: 999))
    }

    func testEventMapper_MapsAdLoadFailedTimeoutAsWarn() {
        let event = EventMapper.map(event: "ad_load_failed", data: ["error": "Network timeout occurred"], now: Date(timeIntervalSince1970: 0))

        XCTAssertEqual(event.category, .error)
        XCTAssertEqual(event.severity, .warn)
        XCTAssertEqual(event.title, "Ad load failed")
    }

    func testEventTimelineStore_CollapsesDuplicatesWithin300ms() {
        let store = EventTimelineStore()
        store.appendMapped(event: "sdk_initialized", data: ["app_key": "abc"], now: Date(timeIntervalSince1970: 1.000))
        store.appendMapped(event: "sdk_initialized", data: ["app_key": "abc"], now: Date(timeIntervalSince1970: 1.200))

        XCTAssertEqual(store.allEvents.count, 1)
        XCTAssertEqual(store.allEvents.first?.duplicateCount, 2)
    }

    func testEventTimelineStore_EnforcesRetentionCap300() {
        let store = EventTimelineStore()

        for index in 0..<305 {
            store.appendMapped(
                event: "custom_event_\(index)",
                data: ["idx": index],
                now: Date(timeIntervalSince1970: TimeInterval(index))
            )
        }

        XCTAssertEqual(store.allEvents.count, 300)
        XCTAssertEqual(store.allEvents.first?.details["idx"], "5")
        XCTAssertEqual(store.allEvents.last?.details["idx"], "304")
    }

    func testEventTimelineStore_FilteredEventsReturnsNewestFirst() {
        let store = EventTimelineStore()
        store.appendMapped(event: "custom_event_old", data: ["idx": 1], now: Date(timeIntervalSince1970: 1))
        store.appendMapped(event: "custom_event_new", data: ["idx": 2], now: Date(timeIntervalSince1970: 2))

        let filtered = store.filteredEvents()

        XCTAssertEqual(filtered.count, 2)
        XCTAssertEqual(filtered.first?.details["idx"], "2")
        XCTAssertEqual(filtered.last?.details["idx"], "1")
    }

    func testExportFormatLineShape() {
        let mapped = EventMapper.map(
            event: "ad_loaded",
            data: ["format": "banner", "placement": "unitA"],
            now: Date(timeIntervalSince1970: 0)
        )

        let details = mapped.details.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
        let line = "\(mapped.timestampLabel) | \(mapped.severity.rawValue) | \(mapped.category.rawValue) | \(mapped.title) | \(details)"

        XCTAssertTrue(line.contains("| SUCCESS | AD_LIFECYCLE | Ad loaded |"))
        XCTAssertTrue(line.contains("ad_unit=unitA"))
        XCTAssertTrue(line.contains("format=banner"))
    }
}
