//
//  MockServer.swift
//  CloudXDemo
//
//  Created by Bohdan Korda on 29.03.23
//

import Foundation
import Swifter

class MockServer {
    static let shared = MockServer()
    static let url = Bundle.main.object(forInfoDictionaryKey: "CONFIG_ENDPOINT") as? String ?? "http://localhost:6657"

    private let server = HttpServer()
    @Service
    private var settings: Settings
    private static let defaultMockServerPort: UInt16 = UInt16(url.suffix(4))!
    public private(set) var isMockServerInitialized = false
    public private(set) var enabled: Bool {
        willSet {
            if newValue {
                print("[MockServer] Mock service is enabled")
                self.registerHandlers()
            } else {
                print("[MockServer] Mock service is disabled")
                self.unregisterHandlers()
            }
        }
    }

    private init() {
        enabled = false
        enabled = self.settings.mockLocalServer
        
        // We have to manually enable the handleres initially
        if enabled { // TODO: Enable only specific handlers
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("[MockServer] Mock service is enabled")
                self.registerHandlers()
            }
        }
        
        NotificationCenter.default.on(event: .mockSdkInit) { [self] notification in
            enabled = notification.isTrue ? true : false
        }

        do {
            try start()
        } catch {
            print("[MockServer] Failed to start mock server: \(error)")
        }
    }

    private func notifyFailure() {
        self.isMockServerInitialized = false
        NotificationCenter.default.post(event: .mockServerStatus, value: false)
    }

    private func notifySuccess() {
        self.isMockServerInitialized = true
        NotificationCenter.default.post(event: .mockServerStatus, value: true)
    }

    func start() throws {
        print("[MockServer] Starting mock server on port [\(MockServer.defaultMockServerPort)]")
        try server.start(MockServer.defaultMockServerPort)
        server.GET["/local/health"] = { request in
            return HttpResponse.ok(.text("ok"))
        }

        DispatchQueue.global(qos: .background).async {
            self.waitForServerLoad(timeout: 10)
        }
    }

    private func waitForServerLoad(timeout: TimeInterval = 10) {
        print("[MockServer] Waiting for server load...")

        let url = URL(string: "\(MockServer.url)/local/health")!
        let timeoutTime = DispatchTime.now() + timeout
        let semaphore = DispatchSemaphore(value: 0)

        var successDetected = false

        while DispatchTime.now() < timeoutTime && !successDetected {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                    successDetected = true
                    print("[MockServer] Server is up and running")
                    self.notifySuccess()
                }
                semaphore.signal()
            }
            task.resume()

            // If the request takes longer than the timeout's remainder to finish, this will continue anyway
            _ = semaphore.wait(timeout: timeoutTime)
            Thread.sleep(forTimeInterval: 0.1)
        }

        if !successDetected {
            print("[MockServer] Failed")
            notifyFailure()
        }
    }

    func getServerState() -> HttpServerIO.HttpServerIOState {
        return server.state
    }

    func stop() {
        print("[MockServer] Stopping mock server")
        server.stop()
        //        mockDelegate?.mockServerStopped(self)
    }
    
    func registerHandlers() {
        if settings.mockLocalServer {
            self.registerInitializeHandler()
            self.loadAuctionsResponseHandler()
        }
    }
    
    func unregisterHandlers() {
        if !settings.mockLocalServer {
            self.unregisterInitializeHandler()
        }
    }

    func registerInitializeHandler() {
        print("[MockServer] Registering handler for POST [/]")
        server.POST["/"] = { request in
            var responseData = Data()
            if let data = try? Data(contentsOf: Bundle.main.url(forResource: "init", withExtension: "json")!) {
                responseData = data
            }
            return HttpResponse.ok(.data(responseData, contentType: "application/json"))
        }
    }
    func unregisterInitializeHandler() {
        print("[MockServer] Unregistering handler for GET [/init]")
        server.GET["/init"] = nil
    }

    func loadAuctionsResponseHandler() {
        print("[MockServer] Loading handler for POST [/openrtb2/auction]")

        server.POST["/openrtb2/auction"] = { request in
            //            Thread.sleep(forTimeInterval: 6)
            var bidResponse: Data!
            let body = String(bytes: request.body, encoding: .ascii)!  // TODO: Handle force unwrap
            let n = Int.random(in: 0...10)
            if body.contains("\"h\":50") {
                print("[MockServer] Serving banner bid response")
                if n % 2 == 0 {
                    bidResponse = try! Data(contentsOf: Bundle.main.url(forResource: "bid-res-banner-admanager", withExtension: "json")!)
                } else {
                    bidResponse = try! Data(contentsOf: Bundle.main.url(forResource: "bid-res-banner", withExtension: "json")!)
                }
                
                bidResponse = try! Data(contentsOf: Bundle.main.url(forResource: "bid-res-banner-mintegral", withExtension: "json")!)
            } else if body.contains("\"reward\":1") {
                print("[MockServer] Serving rewarded bid response")
                if n % 2 == 0 {
                    bidResponse = try! Data(contentsOf: Bundle.main.url(forResource: "bid-res-rewarded-admanager", withExtension: "json")!)
                } else {
                    bidResponse = try! Data(contentsOf: Bundle.main.url(forResource: "bid-res-rewarded", withExtension: "json")!)
                }
                bidResponse = try! Data(contentsOf: Bundle.main.url(forResource: "bid-res-rewarded-mintegral", withExtension: "json")!)
            } else if body.contains("\"instl\":1") {
                print("[MockServer] Serving interstitial bid response")
                if n % 2 == 0 {
                    bidResponse = try! Data(contentsOf: Bundle.main.url(forResource: "bid-res-interstitial-admanager", withExtension: "json")!)
                } else {
                    bidResponse = try! Data(contentsOf: Bundle.main.url(forResource: "bid-res-interstitial", withExtension: "json")!)
                }
                
                bidResponse = try! Data(contentsOf: Bundle.main.url(forResource: "bid-res-interstitial-mintegral", withExtension: "json")!)
            } else if body.contains("\"native\"") {
                print("[MockServer] Serving native bid response")
                if n % 2 == 0 {
                    bidResponse = try! Data(contentsOf: Bundle.main.url(forResource: "bid-res-native-admanager", withExtension: "json")!)
                } else {
                    bidResponse = try! Data(contentsOf: Bundle.main.url(forResource: "bid-res-native", withExtension: "json")!)
                }
                
                bidResponse = try! Data(contentsOf: Bundle.main.url(forResource: "bid-res-native-mintegral", withExtension: "json")!)
            } else {
                print("[MockServer] Invalid ad type")
            }
            return HttpResponse.ok(.data(bidResponse))
        }
    }

}
