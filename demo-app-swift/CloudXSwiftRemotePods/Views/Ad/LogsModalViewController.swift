import UIKit

class LogsModalViewController: UIViewController {
    
    private var scrollView: UIScrollView!
    private var stackView: UIStackView!
    private var titleLabel: UILabel!
    private var closeButton: UIButton!
    private var clearButton: UIButton!
    private let modalTitle: String
    
    init(title: String?) {
        self.modalTitle = title ?? "Logs"
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        refreshLogs()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshLogs()
        scrollToBottom()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Container view
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Header view
        let headerView = UIView()
        headerView.backgroundColor = .systemGray6
        headerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(headerView)
        
        // Title label
        titleLabel = UILabel()
        titleLabel.text = modalTitle
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        // Close button
        closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 16)
        closeButton.addTarget(self, action: #selector(closeModal), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(closeButton)
        
        // Clear button
        clearButton = UIButton(type: .system)
        clearButton.setTitle("Clear", for: .normal)
        clearButton.titleLabel?.font = .systemFont(ofSize: 16)
        clearButton.setTitleColor(.systemRed, for: .normal)
        clearButton.addTarget(self, action: #selector(clearLogs), for: .touchUpInside)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(clearButton)
        
        // Scroll view
        scrollView = UIScrollView()
        scrollView.backgroundColor = .systemBackground
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(scrollView)
        
        // Stack view for logs
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Container view - fill the safe area completely
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Header view
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 50),
            
            // Title label
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // Close button
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // Clear button
            clearButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            clearButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Stack view
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    func refreshLogs() {
        // Clear existing log views
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        let logs = DemoAppLogger.sharedInstance.getAllLogs()
        
        if logs.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No logs available"
            emptyLabel.textColor = .systemGray
            emptyLabel.font = .systemFont(ofSize: 14)
            emptyLabel.textAlignment = .center
            emptyLabel.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview(emptyLabel)
            return
        }
        
        for logEntry in logs {
            let logView = createLogView(for: logEntry)
            stackView.addArrangedSubview(logView)
        }
    }
    
    private func createLogView(for logEntry: DemoAppLogEntry) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 4
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add margin around the log entry
        let marginView = UIView()
        marginView.backgroundColor = .clear
        marginView.translatesAutoresizingMaskIntoConstraints = false
        marginView.addSubview(containerView)
        
        // Timestamp label
        let timestampLabel = UILabel()
        timestampLabel.text = logEntry.formattedTimestamp
        timestampLabel.font = .monospacedSystemFont(ofSize: 10, weight: .medium)
        timestampLabel.textColor = .systemBlue
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(timestampLabel)
        
        // Message label
        let messageLabel = UILabel()
        messageLabel.text = logEntry.message
        messageLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        messageLabel.textColor = .label
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            // Container view within margin view
            containerView.topAnchor.constraint(equalTo: marginView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: marginView.leadingAnchor, constant: 12),
            containerView.trailingAnchor.constraint(equalTo: marginView.trailingAnchor, constant: -12),
            containerView.bottomAnchor.constraint(equalTo: marginView.bottomAnchor, constant: -4),
            
            // Timestamp label
            timestampLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
            timestampLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            timestampLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            // Message label
            messageLabel.topAnchor.constraint(equalTo: timestampLabel.bottomAnchor, constant: 2),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4)
        ])
        
        return marginView
    }
    
    private func scrollToBottom() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let bottomOffset = CGPoint(x: 0, y: self.scrollView.contentSize.height - self.scrollView.bounds.height + self.scrollView.contentInset.bottom)
            if bottomOffset.y > 0 {
                self.scrollView.setContentOffset(bottomOffset, animated: true)
            }
        }
    }
    
    @objc private func closeModal() {
        dismiss(animated: true)
    }
    
    @objc private func clearLogs() {
        DemoAppLogger.sharedInstance.clearLogs()
        refreshLogs()
    }
}