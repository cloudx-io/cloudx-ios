//
//  FullscreenContainerViewController.swift
//  AequusCore
//
//  Created by Aleksandr on 03.06.2022.
//

import UIKit
import WebKit
import SafariServices

enum CloudXDemoAdapterError: Error {
    case invalidAdm
}

protocol FullscreenStaticContainerViewControllerDelegate: AnyObject {
    func closeFullScreenAd()
    func didFailToShow(error: Error)
    func didClickFullAdd()
    func didLoad()
    func didShow()
    func impression()
}

final class FullscreenStaticContainerViewController: UIViewController {
    // MARK: - Properties
    
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(clickClose), for: .touchUpInside)
        let image = UIImage(systemName: "xmark.circle",
                            withConfiguration: UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 14), scale: .large))
        button.setImage(image, for: .normal)
        return button
    }()
    
    private let topConstant: CGFloat = 12
    private let trailingConstant: CGFloat = 12
    private weak var delegate: FullscreenStaticContainerViewControllerDelegate?
    private let webView: WKWebView
    private let adm: String
    private var tracked: Bool = false
    
    // MARK: - Init
    
    init(delegate: FullscreenStaticContainerViewControllerDelegate, adm: String) {
        self.delegate = delegate
        self.webView = WKWebView(frame: CGRect.zero, configuration: WKScriptHelper.shared.fullscreenConfiguration)
        self.adm = adm
        
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .fullScreen
        webView.uiDelegate = self
        webView.navigationDelegate = self
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - ViewController life cycle
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    public func destroy() {
        DispatchQueue.main.async {
            self.webView.removeFromSuperview()
            self.webView.navigationDelegate = nil
            self.webView.uiDelegate = nil
        }
    }
    
    public func loadHTML() {
        DispatchQueue.main.async {
            //fatalError("loadHTML \(self.adm)")
            self.webView.loadHTMLString(self.adm, baseURL: nil)
        }
    }
    
    // MARK: - Setup layout
    
    private func setupUI() {
        [webView, closeButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topConstant),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -trailingConstant)
        ])
    }
    
    // MARK: - Action
    
    @objc private func clickClose() {
        dismiss(animated: true) { [weak self] in
            self?.delegate?.closeFullScreenAd()
        }
    }
}

// MARK: - WKNavigationDelegate

extension FullscreenStaticContainerViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        delegate?.didLoad()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        delegate?.didFailToShow(error: error)
    }
}

// MARK: - WKUIDelegate

extension FullscreenStaticContainerViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            DispatchQueue.main.async {
                guard let url = navigationAction.request.url else { return }
                self.delegate?.didClickFullAdd()
                let config = SFSafariViewController.Configuration()
                config.entersReaderIfAvailable = true
                
                let vc = SFSafariViewController(url: url, configuration: config)
                
                self.present(vc, animated: true)
            }
        }
        
        return nil
    }
}
