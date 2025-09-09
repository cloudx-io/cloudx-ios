//
//  CloudXMediumNativeView.swift
//
//
//  Created by bkorda on 10.05.2024.
//

import UIKit

/// A view that displays a small native ad.
public final class CloudXSmallNativeView: UIView, CloudXBaseNativeView {
    
    /// Set title of the native ad.
    public var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    /// Set description of the native ad.
    public var descriptionText: String? {
        didSet {
            descriptionLabel.text = descriptionText
        }
    }
    
    /// Set call to action text of the native ad.
    public var callToActionText: String? {
        didSet {
            callToAction.setTitle(callToActionText, for: .normal)
        }
    }
    
    /// Set app icon of the native ad.
    public var appIcon: UIImage? {
        didSet {
            appIconView.image = appIcon
        }
    }
    
    /// Set main image of the native ad.
    /// - Note: Main image is always nil for small native ad
    public var mainImage: UIImage?
    
    let appIconView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Title"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return label
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Description "
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.numberOfLines = 2
        label.setContentHuggingPriority(.defaultLow, for: .vertical)
        return label
    }()
    
    let callToAction: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Call to action", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 5
        return button
    }()
    
    let closeButton: UIButton = {
        let button = UIButton(type: .close)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    /// Returns cta view that is used to handle tap action.
    public var ctaView: UIView? { callToAction }
    
    /// Returns close button view that is used to handle tap action.
    public var closeButtonView: UIView? { closeButton }
    
    /// Returns description view that is used tho show description of the native ad.
    public var descriptionView: UIView? { descriptionLabel }
    
    /// Returns title view that is used tho show title of the native ad.
    public var titleView: UIView? {
        titleLabel
    }
    
    /// Returns icon view that is used tho show icon of the native ad.
    public var iconView: UIView? { appIconView }
    
    /// Returns main image view that is used tho show main image of the native ad.
    public var mainImageView: UIView? { nil }
    
    /// Set custom media view of the native ad such as video player.
    /// - Note: customMediaView is always nil for small native ads
    public var customMediaView: UIView?
    
    /// Closure that is called when the call to action is tapped.
    public var cta: (() -> Void)?
    
    /// Closure that is called when the call to close action is tapped.
    public var close: (() -> Void)?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init(size: CGSize, hasCloseButton: Bool = false) {
        super.init(frame: CGRect(origin: .zero, size: size))
        setupView(hasCloseButton)
        
        callToAction.addTarget(self, action: #selector(ctaAction), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
    }
    
    func setupView(_ hasCloseButton: Bool) {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stackView.axis = .vertical
        stackView.contentMode = .top
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let adMark = UILabel(frame: .zero)
        adMark.text = "ad"
        adMark.translatesAutoresizingMaskIntoConstraints = false
        adMark.textAlignment = .center
        adMark.backgroundColor = .systemOrange
        adMark.clipsToBounds = true
        adMark.layer.cornerRadius = 3
        
        addSubview(appIconView)
        addSubview(stackView)
        addSubview(callToAction)
        if hasCloseButton {
            addSubview(closeButton)
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            closeButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
        }
        addSubview(adMark)
        
        NSLayoutConstraint.activate([
            adMark.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            adMark.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            adMark.widthAnchor.constraint(equalToConstant: 30),
            
            appIconView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            appIconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            appIconView.widthAnchor.constraint(equalToConstant: 50),
            appIconView.heightAnchor.constraint(equalToConstant: 50),
            
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            stackView.topAnchor.constraint(equalTo: appIconView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: appIconView.trailingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: callToAction.leadingAnchor),
            
            callToAction.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            callToAction.widthAnchor.constraint(equalToConstant: 90),
            callToAction.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            callToAction.heightAnchor.constraint(equalToConstant: 40),
        ])
    }
    
    @objc private func ctaAction() {
        self.cta?()
    }
    
    @objc private func closeAction() {
        self.close?()
    }
}

@available(iOS 17, *)
#Preview {
    let size = CGSize(width: 320, height: 80)
    let view = CloudXSmallNativeView(size: size)
    view.appIcon = UIImage(systemName: "pencil")
    view.backgroundColor = .systemGray6
    
    view.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
        view.widthAnchor.constraint(equalToConstant: size.width),
        view.heightAnchor.constraint(equalToConstant: size.height)
    ])
    
    return view
}
