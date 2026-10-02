import UIKit

/** The layout the ad flow screens share: status lines, a live log that fills the middle and a Show button. */
enum DemoFlowLayout {

    static func makeStatusLabel() -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.numberOfLines = 0
        return label
    }

    /** The button starts disabled; the screen enables it once its ad controller exists. */
    static func makeShowButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("Show Interstitial", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.isEnabled = false
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }

    /** Stacks `views` top to bottom inside the safe area of `view`, 12 points from each edge. */
    static func install(_ views: [UIView], in view: UIView) {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }
}
