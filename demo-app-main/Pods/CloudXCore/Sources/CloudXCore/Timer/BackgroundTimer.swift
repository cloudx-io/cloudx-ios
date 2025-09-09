//
//  BackgroundTimer.swift
//  
//
//  Created by bkorda on 06.03.2024.
//

import UIKit

final class BackgroundTimer {
    
    private enum State {
        case suspended
        case resumed
    }
    
    // MARK: - Private properties
    
    private let timeInterval: TimeInterval
    private let queue: DispatchQueue
    private lazy var timer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        if isRepeating {
            timer.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval)
        } else {
            timer.schedule(deadline: .now() + self.timeInterval)
        }
        timer.setEventHandler(handler: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.eventHandler?()
        })
        return timer
    }()
    
    private var state: State = .suspended
    private var isRepeating = false
    
    // MARK: - Public properties
    
    var eventHandler: (() -> Void)?
    
    // MARK: - Life Cycle
    
    static func scheduleRepeatingTimer(timeInterval: TimeInterval, queueLabel: String) -> BackgroundTimer {
        return BackgroundTimer(timeInterval: timeInterval, queueLabel: queueLabel, isRepeating: true)
    }
    
    static func scheduleTimer(timeInterval: TimeInterval, queueLabel: String) -> BackgroundTimer {
        return BackgroundTimer(timeInterval: timeInterval, queueLabel: queueLabel, isRepeating: true)
    }
    
    private init(timeInterval: TimeInterval, queueLabel: String, isRepeating: Bool) {
        self.queue = DispatchQueue(label: queueLabel, attributes: .concurrent)
        self.timeInterval = timeInterval
        self.isRepeating = isRepeating
    }
    
    deinit {
        timer.setEventHandler {}
        timer.cancel()
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        resume()
        eventHandler = nil
    }
    
    //MARK: - Public methods
    
    func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        timer.resume()
    }
    
    func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer.suspend()
    }
    
}
