//
//  WKScriptHelper.swift
//
//
//  Created by bkorda on 01.03.2024.
//

import WebKit

struct WKScriptHelper {

  public lazy var configuration: WKWebViewConfiguration = {
    let userContentController: WKUserContentController = WKUserContentController()
    let configuration = WKWebViewConfiguration()
    configuration.userContentController = userContentController
    userContentController.addUserScript(zoomDisableScript)
    return configuration
  }()

  private var zoomDisableScript: WKUserScript = {
    let source: String =
      "var meta = document.createElement('meta');meta.setAttribute('name', 'viewport');meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');document.getElementsByTagName('head')[0].appendChild(meta);"
    return WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
  }()
}
