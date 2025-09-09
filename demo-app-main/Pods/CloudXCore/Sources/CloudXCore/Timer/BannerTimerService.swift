//
//  BannerTimerService.swift
//  
//
//  Created by bkorda on 06.03.2024.
//

import UIKit

final class BannerTimerService {
    
    private var timeCounter: TimeInterval = 0
    private var timer: BackgroundTimer = BackgroundTimer.scheduleRepeatingTimer(timeInterval: 1, queueLabel: "com.cloudx.ads.service.timer.banner")
    private var completionBlock: (() -> Void)?
    private var needToResume: Bool = false
    
    init() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedFromBackground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    deinit {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        timer.suspend()
    }
    
    func startCountDown(deadline: TimeInterval, completion: @escaping () -> Void) {
        timeCounter = 0
        completionBlock = completion
        needToResume = true
        timer.eventHandler = { [weak self] in
            guard let `self` = self else { return }
            self.timeCounter += 1
            if self.timeCounter > deadline {
                self.timer.suspend()
                self.needToResume = false
                completion()
            }
        }
        timer.resume()
    }
    
    @objc private func appMovedToBackground() {
        timer.suspend()
    }
    
    @objc private  func appMovedFromBackground() {
        if needToResume {
            timer.resume()
        }
    }
    
    func stop() {
        timer.suspend()
    }
    
}
