import UIKit

class AdDemoTabViewController: UIViewController {
    private var currentViewController: UIViewController?
    private let segmentedControl: UISegmentedControl
    private let containerView = UIView()
    
    private lazy var viewControllers: [UIViewController] = {
        return [
            InitViewController(),
            BannerViewController(),
            MRECViewController(),
            InterstitialViewController(),
            RewardedViewController(),
            NativeViewController()
        ]
    }()
    
    init() {
        let items = ["Init", "Banner", "MREC", "Interstitial", "Rewarded", "Native"]
        segmentedControl = UISegmentedControl(items: items)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        segmentedControl.selectedSegmentIndex = 0
        updateSelectedViewController(0)
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Configure segmented control
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        
        // Configure container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(segmentedControl)
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            containerView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        updateSelectedViewController(sender.selectedSegmentIndex)
    }
    
    private func updateSelectedViewController(_ index: Int) {
        // Remove current view controller
        currentViewController?.willMove(toParent: nil)
        currentViewController?.view.removeFromSuperview()
        currentViewController?.removeFromParent()
        
        // Add new view controller
        let newViewController = viewControllers[index]
        addChild(newViewController)
        newViewController.view.frame = containerView.bounds
        containerView.addSubview(newViewController.view)
        newViewController.didMove(toParent: self)
        currentViewController = newViewController
        
        // Setup constraints for the new view
        newViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newViewController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            newViewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            newViewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            newViewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
} 