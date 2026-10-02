import Foundation

/**
 * The retry policy of the ad flows after a failed load or show: 2 s, 4 s, 8 s and so on up to 60 s,
 * started over by `reset()` after the next successful load. A fixed short delay would turn
 * sustained no-fill into a tight request loop against the ad networks. Main queue only.
 */
final class RetryScheduler {

    private static let baseDelay: TimeInterval = 2
    private static let maxDelay: TimeInterval = 60
    private static let maxShift = 5

    private var work: DispatchWorkItem?
    private var count = 0

    deinit {
        work?.cancel()
    }

    /** True while a scheduled retry has not run yet. */
    var isPending: Bool { work != nil }

    /** Runs `action` after the next backoff delay, replacing a pending retry, and returns the delay in seconds. */
    func schedule(_ action: @escaping () -> Void) -> Int {
        let delay = min(Self.baseDelay * TimeInterval(1 << count), Self.maxDelay)
        count = min(count + 1, Self.maxShift)
        work?.cancel()
        let newWork = DispatchWorkItem { [weak self] in
            self?.work = nil
            action()
        }
        work = newWork
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newWork)
        return Int(delay)
    }

    /** Cancels a pending retry and starts the next failure over at the base delay. */
    func reset() {
        work?.cancel()
        work = nil
        count = 0
    }
}
