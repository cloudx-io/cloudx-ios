//
//  BaseAdViewController.swift
//  CloudXDemo
//
//  Created by bkorda on 01.03.2024.
//

import UIKit
import CloudXCore
import ToastView
import AppTrackingTransparency

class BaseAdViewController: UIViewController {
		
		let settings: Settings = UserDefaultsSettings()
		
		enum StatusButtonPhase {
				case `init`
				case progress
				case done
				case failure
		}

    override func viewDidLoad() {
        super.viewDidLoad()
				
				self.tabBarController?.tabBar.items?.last?.image = UIImage(systemName: "gear")
				self.tabBarController?.tabBar.items?.last?.selectedImage = UIImage(systemName: "gear")
				
				setupStatusButton(phase: .`init`)
				appConfigModel = defaultConfigModel
		
    }
		
		override func viewWillAppear(_ animated: Bool) {
				super.viewWillAppear(animated)
				
				if CloudX.shared.isInitialised {
						setupStatusButton(phase: .done)
				}
		}
		
		override func viewDidAppear(_ animated: Bool) {
				super.viewDidAppear(animated)
				
//				ATTrackingManager.requestTrackingAuthorization { status in
//						switch status {
//						case .authorized:
//								LogStorageClass.shared.addLog(type: .info, prefix: "Tracking", message: "Authorized")
//						case .denied:
//								LogStorageClass.shared.addLog(type: .info, prefix: "Tracking", message: "Denied")
//						case .notDetermined:
//								LogStorageClass.shared.addLog(type: .info, prefix: "Tracking", message: "Not determined")
//						case .restricted:
//								LogStorageClass.shared.addLog(type: .info, prefix: "Tracking", message: "Restricted")
//						@unknown default:
//								LogStorageClass.shared.addLog(type: .info, prefix: "Tracking", message: "Unknown")
//						}
//				}
		}
	
	private func normalizeAndHashUserID() -> String {
		var finalString = ""
		guard let userId = settings.userId else { return finalString }
		if settings.hashAlgo == "sha256" {
			finalString = HashService.hash256(string: userId.lowercased())
		} else {
			finalString = HashService.hashmd5(string: userId.lowercased())
		}
		
		return finalString
	}
		
		@objc func initSDK() {
				ATTrackingManager.requestTrackingAuthorization { status in
						print("Tracking authorization status: \(status)")
				}
				setupStatusButton(phase: .progress)

				Task {
					do {
						LogStorageClass.shared.addLog(type: .info, prefix: "SDK", message: "Starting initialization with \(settings.appKey), and userID: \(settings.hashedUserId)")
						
						_ = try await CloudX.shared.initSDK(appKey: settings.appKey, hashedUserID: settings.hashedUserId ?? "")
						setupStatusButton(phase: .done)
						
						LogStorageClass.shared.addLog(type: .info, prefix: "SDK", message: "BidRequest Endpoints: \(CloudX.shared.logsData["endpointData"] ?? "")")
						
						SDKinitialized()
						
						if let dict = settings.keyValues as? [String: String] {
							CloudX.shared.useKeyValues(userDictionary: dict)
						}
						
						
						if settings.hashedUserId == nil {
							let time = settings.userIdMiliseconds > 0 ? settings.userIdMiliseconds : 1000
							let interval = Double(time / 1000)
							_ = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { timer in
								LogStorageClass.shared.addLog(type: .info, prefix: "SDK", message: "Send hashed user id \(self.normalizeAndHashUserID()), after: \(interval)")
								CloudX.shared.provideUserDetails(hashedUserID: self.normalizeAndHashUserID())
								
							}
						}
						
						let largeConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold, scale: .large)
						let image = UIImage(systemName: "checkmark.circle", withConfiguration: largeConfig)
						ToastPresenter.show(title: "SDK initialized successfully",
											icon: image,
											origin: self.view)
						LogStorageClass.shared.addLog(type: .success, prefix: "SDK", message: "Initialized successfully")
					} catch {
								print("Failt to init SDK")
								LogStorageClass.shared.addLog(type: .error, prefix: "SDK", message: "Fail to initialize")
								setupStatusButton(phase: .failure)
						}
				}
		}
		
		private func setupStatusButton(phase: StatusButtonPhase) {
				switch phase {
				case .`init`:
						let button = UIBarButtonItem(title: "Init SDK", style: .plain, target: self, action: #selector(initSDK))
						button.accessibilityIdentifier = "ButtonInitSDK"
						self.navigationItem.rightBarButtonItem = button
				case .progress:
						let activityIndicator = UIActivityIndicatorView(style: .medium)
						activityIndicator.accessibilityIdentifier = "SDKInitInProgress"
						activityIndicator.startAnimating()
						self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
				case .done:
						let largeConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .large)
						let image = UIImage(systemName: "checkmark.circle", withConfiguration: largeConfig)
						let imageView = UIImageView(image: image)
						imageView.tintColor = .green
						imageView.accessibilityIdentifier = "InitSDKCompleted"
						self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: imageView)
				case .failure:
						let largeConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .large)
						let button = UIBarButtonItem(image:  UIImage(systemName: "x.circle", withConfiguration: largeConfig), style: .plain, target: self, action: #selector(initSDK))
						button.tintColor = .red
						button.accessibilityIdentifier = "ButtonInitSDKRetry"
						self.navigationItem.rightBarButtonItem = button
				}
		}
		
		func SDKinitialized() {
				fatalError("Needs to be overrided")
		}

}
