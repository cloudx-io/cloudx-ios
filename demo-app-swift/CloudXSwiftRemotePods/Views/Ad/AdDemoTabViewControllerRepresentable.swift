import SwiftUI

struct AdDemoTabViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> AdDemoTabViewController {
        return AdDemoTabViewController()
    }
    
    func updateUIViewController(_ uiViewController: AdDemoTabViewController, context: Context) {
        // No updates needed
    }
} 