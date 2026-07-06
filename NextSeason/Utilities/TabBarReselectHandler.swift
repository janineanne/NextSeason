//
//  TabBarReselectHandler.swift
//  NextSeason
//

import SwiftUI
import UIKit

/// Detects when the user re-taps an already-selected tab bar item.
///
/// SwiftUI `TabView` does not surface reselection, so a minimal UIKit bridge
/// is used for behaviors such as popping a nested navigation stack.
struct TabBarReselectHandler: UIViewControllerRepresentable {
    let tabIndex: Int
    let onReselect: @MainActor () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(tabIndex: tabIndex, onReselect: onReselect)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        context.coordinator.hostingController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.tabIndex = tabIndex
        context.coordinator.onReselect = onReselect
        context.coordinator.installDelegateIfNeeded()
    }

    final class Coordinator: NSObject, UITabBarControllerDelegate {
        var tabIndex: Int
        var onReselect: @MainActor () -> Void
        let hostingController = UIViewController()
        private var lastSelectedIndex: Int?

        init(tabIndex: Int, onReselect: @escaping @MainActor () -> Void) {
            self.tabIndex = tabIndex
            self.onReselect = onReselect
            super.init()
            hostingController.view.isHidden = true
        }

        func installDelegateIfNeeded() {
            DispatchQueue.main.async { [weak self] in
                guard let self, let tabBarController = self.hostingController.tabBarController else { return }
                tabBarController.delegate = self
            }
        }

        func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
            let selectedIndex = tabBarController.selectedIndex
            defer { lastSelectedIndex = selectedIndex }

            guard selectedIndex == tabIndex, lastSelectedIndex == tabIndex else { return }

            Task { @MainActor in
                onReselect()
            }
        }
    }
}
