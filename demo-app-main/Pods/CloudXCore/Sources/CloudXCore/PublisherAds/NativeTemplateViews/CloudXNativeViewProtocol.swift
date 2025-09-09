//
//  CloudXNativeViewProtocol.swift
//
//
//  Created by bkorda on 10.05.2024.
//

import UIKit

/// A protocol that defines the properties of a native ad view template.
public protocol CloudXBaseNativeView {
    
    /// Native ad title.
    var title: String? { get set }
    
    /// Native ad description.
    var descriptionText: String? { get set }
    
    /// Native ad call to action text.
    var callToActionText: String? { get set }
    
    /// Native ad app icon.
    var appIcon: UIImage? { get set }
    
    /// Native ad main image.
    var mainImage: UIImage? { get set }
    
    /// Closure to be called when the call to action is tapped.
    var cta: (() -> Void)? { get set }
    
    /// Closure that is called when the call to close action is tapped.
    var close: (() -> Void)? { get set }
    
    /// Call to action view object.
    var ctaView: UIView? { get }
    
    /// Call to close action view object.
    var closeButtonView: UIView? { get }
    
    /// Title view object.
    var titleView: UIView? { get }
    
    /// Description view object.
    var descriptionView: UIView? { get }
    
    /// App icon view object.
    var iconView: UIView? { get }
    
    /// Main image view object.
    var mainImageView: UIView? { get }
    
    /// Custom media view object.
    var customMediaView: UIView? { get set }
}
