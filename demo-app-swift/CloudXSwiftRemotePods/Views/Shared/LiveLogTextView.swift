import UIKit

/**
 * A read-only log that shows every `DemoAppLogger` line as it is written, so an ad flow screen
 * shows what its ad code reports. Keeps the last 500 lines, the same bound as `DemoAppLogger`, so a
 * screen left open through a retry loop cannot grow without limit.
 */
final class LiveLogTextView: UITextView {

    private static let lineLimit = 500

    private var lines: [String] = []
    private var observer: NSObjectProtocol?

    init(accessibilityLabel: String) {
        super.init(frame: .zero, textContainer: nil)
        self.accessibilityLabel = accessibilityLabel
        isEditable = false
        font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 8
        observer = NotificationCenter.default.addObserver(
            forName: DemoAppLogger.didAppendEntry,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let entry = notification.userInfo?[DemoAppLogger.entryUserInfoKey] as? DemoAppLogEntry else { return }
            self?.append("\(entry.formattedTimestamp) \(entry.message)")
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func append(_ line: String) {
        lines.append(line)
        if lines.count > Self.lineLimit {
            lines.removeFirst(lines.count - Self.lineLimit)
        }
        text = lines.joined(separator: "\n")
        scrollRangeToVisible(NSRange(location: text.utf16.count, length: 0))
    }
}
