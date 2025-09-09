//
//  WKScripHelper.swift
//  AequusCore
//
//  Created by Aleksandr on 03.06.2022.
//

import WebKit

final class WKScriptHelper {
    
    static let shared = WKScriptHelper()
    
    public lazy var bannerConfiguration: WKWebViewConfiguration = {
        let userContentController: WKUserContentController = WKUserContentController()
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        userContentController.addUserScript(getZoomDisableScript())
        userContentController.addUserScript(marginFixScript())
        return configuration
    }()
    
    public lazy var fullscreenConfiguration: WKWebViewConfiguration = {
        let userContentController: WKUserContentController = WKUserContentController()
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        userContentController.addUserScript(marginFixScript())
        return configuration
    }()
    
    private init() { }
    
    private func getZoomDisableScript() -> WKUserScript {
        let source: String = "var meta = document.createElement('meta');meta.setAttribute('name', 'viewport');meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');document.getElementsByTagName('head')[0].appendChild(meta);"
        return WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }
    
    private func marginFixScript() -> WKUserScript {
        let cssString = "body { margin: 0px }"
        let jstring = "var style = document.createElement('style'); style.innerHTML = '\(cssString)'; document.head.appendChild(style)"
        return WKUserScript(source: jstring, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }
}
