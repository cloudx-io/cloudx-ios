//
//  MockInitService.swift
//  CloudXCore
//
//  Created by bkorda on 08.02.2024.
//

import Foundation

let mockRequest =
  """
  {
      "bundle" : "com.cloudx.demo.app",
      "os" : "iOS",
      "osVersion" : "17.3",
      "model" : "iPhone 15 Pro",
      "vendor" : "Apple",
      "ifa" : "adfadf-sdfsdf-dfsdf",
      "ifv" : "adfadf-sdfsdf-dfsdf",
      "sdkVersion" : "0.0.1",
      "dnt": false
  }
  """

let mockResponse =
  """
    {
        "preCacheSize": 5,
        "auctionEndpointURL": "https://ads.cloudx.io/openrtb2/auction",
        "eventTrackingURL": "https://ads.cloudx.io/events",
        "metricsEndpointURL": "https://ads.cloudx.io/metrics",
        "sessionID": "5fbfba7699b56fae4854f04f",
        "bidders": [
            {
                "initData": {
                    "reportingApiID": "25351f24bc1f22a860934cd726e625e5",
                    "appID": "5fbfba7699b56fae4854f04f"
                },
                "networkName": "TestVastNetwork"
            },
            {
                "initData": {
                    "reportingApiID": "25351f24bc1f22a860934cd726e625e5",
                    "appID": "5fbfba7699b56fae4854f04f"
                },
                "networkName": "Mockery"
            }
        ],
        "placements": [
            {
                "id": "123",
                "name": "defaultBanner",
                "bidResponseTimeoutMs": 500,
                "adLoadTimeoutMs" : 1000,
                "bannerRefreshRateMs": 15,
                "type": "BANNER"
            },
            {
                "id": "1234",
                "name": "defaulInterstitial",
                "bidResponseTimeoutMs": 500,
                "adLoadTimeoutMs" : 1000,
                "type": "INTERSTITIAL"
            }
        ]
    }
  """

class MockInitService: InitService {

  func initSDK(appKey: String) async throws -> SDKConfig.Response {
    let data = mockResponse.data(using: .utf8)!
    guard let sdkConfig = try? JSONDecoder().decode(SDKConfig.Response.self, from: data) else {
      throw CloudXError.failToInitSDK
    }
    //sleep(2)
    return sdkConfig
  }

}
