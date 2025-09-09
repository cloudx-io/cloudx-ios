//
//  CloudXDSPBanner.swift
//
//
//  Created by bkorda on 06.03.2024.
//

import WebKit
import SafariServices
import CloudXCore

class CloudXDSPBanner: NSObject, AdapterBanner {
    weak var delegate: CloudXCore.AdapterBannerDelegate?
    
    var timeout: Bool = false
    
    var bannerView: UIView? {
        webView
    }
    
    var sdkVersion: String { CloudX.shared.sdkVersion }
    
    private let adm: String
    private let viewController: UIViewController
    private let type: CloudXBannerType
    private let hasClosedButton: Bool
    
    private var webView: WKWebView?
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .close)
          button.translatesAutoresizingMaskIntoConstraints = false
          return button
       }()
    
    init(adm: String, hasClosedButton: Bool, type: CloudXBannerType, viewController: UIViewController, delegate: AdapterBannerDelegate?) {
        self.delegate = delegate
        self.type = type
        self.adm = adm
        self.viewController = viewController
        self.hasClosedButton = hasClosedButton
        
        super.init()
    }
    
    func load() {
        DispatchQueue.main.async {
            let webView = WKWebView(frame: CGRect(x: .zero, y: .zero, width: self.type.size.width, height: self.type.size.height), configuration: WKScriptHelper.shared.bannerConfiguration)
            webView.uiDelegate = self
            webView.navigationDelegate = self
            webView.scrollView.isScrollEnabled = false
            webView.loadHTMLString(self.adm, baseURL: nil)
            if #available(iOS 16.4, *) {
                webView.isInspectable = true
            }
            
            if self.hasClosedButton {
                self.closeButton.addTarget(self, action: #selector(self.closeBanner), for: .touchUpInside)
                webView.addSubview(self.closeButton)
                
                NSLayoutConstraint.activate([
                    webView.trailingAnchor.constraint(equalTo: self.closeButton.trailingAnchor),
                    webView.topAnchor.constraint(equalTo: self.closeButton.topAnchor),
                ])
            }
            
            self.webView = webView
        }
    }
    
    func destroy() {
        webView?.removeFromSuperview()
        webView?.uiDelegate = nil
        webView?.navigationDelegate = nil
        webView = nil
    }
    
    @objc func closeBanner(sender: UIButton) {
        destroy()
        delegate?.closedByUserAction(banner: self)
    }

}

// MARK: - WKNavigationDelegate

extension CloudXDSPBanner: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        delegate?.didLoad(banner: self)
        delegate?.didShow(banner: self)
        delegate?.impression(banner: self)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        delegate?.failToLoad(banner: self, error: error)
    }
}

// MARK: - WKUIDelegate

extension CloudXDSPBanner: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            DispatchQueue.main.async {
                guard let url = navigationAction.request.url else { return }
                
                self.delegate?.click(banner: self)
                
                let config = SFSafariViewController.Configuration()
                config.entersReaderIfAvailable = true
                
                let vc = SFSafariViewController(url: url, configuration: config)
                self.viewController.present(vc, animated: true)
            }
        }
        
        return nil
    }
}

