//
//  QuickLookPreview.swift
//  Nutrix
//
//  Created by Antigravity on 26/5/26.
//

import SwiftUI
import QuickLook

struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let containerVC = QuickLookContainerViewController(url: url, onDismiss: onDismiss)
        let navController = UINavigationController(rootViewController: containerVC)
        
        // Configure navigation bar appearance to match modern iOS styling
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        navController.navigationBar.standardAppearance = appearance
        navController.navigationBar.scrollEdgeAppearance = appearance
        
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

class QuickLookContainerViewController: UIViewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    
    // MARK: - Properties
    let url: URL
    let onDismiss: () -> Void
    let previewController = QLPreviewController()
    
    // MARK: - Initializers
    init(url: URL, onDismiss: @escaping () -> Void) {
        self.url = url
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // Set up QuickLook preview controller as a child view controller
        previewController.dataSource = self
        previewController.delegate = self
        
        addChild(previewController)
        view.addSubview(previewController.view)
        previewController.view.frame = view.bounds
        previewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        previewController.didMove(toParent: self)
        
        // Set document filename as title
        title = url.lastPathComponent
        
        // Set left navigation item to close the modal
        let closeButton = UIBarButtonItem(title: "Đóng", style: .plain, target: self, action: #selector(dismissSelf))
        navigationItem.leftBarButtonItem = closeButton
        
        // Set right navigation item to trigger iOS share sheet
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareFile))
        navigationItem.rightBarButtonItem = shareButton
    }
    
    // MARK: - Actions
    @objc private func dismissSelf() {
        onDismiss()
    }
    
    @objc private func shareFile() {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // Popover support for iPads
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(activityVC, animated: true)
    }
    
    // MARK: - QLPreviewControllerDataSource
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return url as NSURL
    }
}
