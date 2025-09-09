//
//  CloudXDemoBanner.swift
//
//
//  Created by bkorda on 01.03.2024.
//

import WebKit
import SafariServices

enum CloudXDemoBannerError: Error {
  case failToLoad
}

final class CloudXDemoBanner: NSObject, AdapterBanner {

  weak var delegate: AdapterBannerDelegate?

  var sdkVersion: String {
    CloudX.shared.sdkVersion
  }

  var bannerView: UIView? {
    banner
  }

  var timeout: Bool = false
  var isReady: Bool = false

  private var scriptHandler = WKScriptHelper()
  private var banner: WKWebView?
  private let type: CloudXBannerType
  private let viewController: UIViewController?
  private let logger = Logger(category: "CloudXBanner")
  private let adm: String?

  init(adm: String?, type: CloudXBannerType, viewController: UIViewController, delegate: AdapterBannerDelegate) {
    self.delegate = delegate
    self.viewController = viewController
    self.type = type
    self.adm = adm
    
    super.init()
  }
  
  func load() {
    guard let adm = adm else {
        logger.error("Demo banner failed to load: No adm content available")
        delegate?.failToLoad(banner: self, error: CloudXDemoBannerError.failToLoad)
        return
    }
    
    DispatchQueue.main.async { [self] in    
      self.banner = WKWebView(frame: CGRect(x: .zero, y: .zero, width: self.type.size.width, height: self.type.size.height), configuration: self.scriptHandler.configuration)
      self.banner?.uiDelegate = self
      self.banner?.navigationDelegate = self
      self.banner?.loadHTMLString(adm, baseURL: nil)
    }
  }

  func destroy() {
      logger.debug("Demo banner destroying")
      if let banner = banner {
          logger.debug("Banner view hierarchy before removal:")
          if let superview = banner.superview {
              logger.debug("Banner has superview: \(Swift.type(of: superview))")
          } else {
              logger.debug("Banner has no superview")
          }
      }
      banner?.removeFromSuperview()
      banner?.uiDelegate = nil
      banner?.navigationDelegate = nil
      banner = nil
      logger.debug("Demo banner destroyed")
  }

}
// MARK: - WKNavigationDelegate

extension CloudXDemoBanner: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        delegate?.didLoad(banner: self)
        delegate?.didShow(banner: self)
        delegate?.impression(banner: self)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        logger.error("Demo banner web view failed to load: \(error.localizedDescription)")
        delegate?.failToLoad(banner: self, error: error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        logger.error("Demo banner web view failed provisional navigation: \(error.localizedDescription)")
        delegate?.failToLoad(banner: self, error: error)
    }
}

// MARK: - WKUIDelegate

extension CloudXDemoBanner: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            DispatchQueue.main.async {
                guard let url = navigationAction.request.url else { return }
                
                self.delegate?.click(banner: self)
                
                let config = SFSafariViewController.Configuration()
                config.entersReaderIfAvailable = true
                
                let vc = SFSafariViewController(url: url, configuration: config)
                self.viewController?.present(vc, animated: true)
            }
        }
        
        return nil
    }
}
