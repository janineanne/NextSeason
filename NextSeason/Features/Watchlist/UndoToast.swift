//
//  UndoToast.swift
//  NextSeason
//

import SwiftUI
import UIKit

/// Confirmation toast shown after removing a show from the watchlist (Undo / OK).
struct UndoToast: View {
    let message: String
    let undoAction: () -> Void
    let confirmAction: () -> Void
    @AccessibilityFocusState.Binding var toastFocus: UndoToastFocus?

    var body: some View {
        toastContents
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .modifier(UndoToastChromeModifier())
    }

    private var toastContents: some View {
        HStack(spacing: 12) {
            Image(systemName: "trash.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.accent)
                .accessibilityHidden(true)

            Text(message)
                .font(.subheadline)
                .appPrimaryText()
                .accessibilityFocused($toastFocus, equals: .message)

            Spacer(minLength: 0)

            Button("Undo", action: undoAction)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.accent)
                .modifier(UndoToastActionHitTargetModifier())
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityID.Watchlist.undoButton)
                .accessibilityHint("Restores the show to your watchlist")
                .accessibilityFocused($toastFocus, equals: .undo)

            Button("OK", action: confirmAction)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .modifier(UndoToastActionHitTargetModifier())
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityID.Watchlist.confirmButton)
                .accessibilityHint("Confirms removal from your watchlist")
        }
    }
}

/// Extra padding + explicit content shape so plain-text Undo/OK stay easy to hit.
private struct UndoToastActionHitTargetModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
    }
}

/// Floating chrome for the undo toast: Liquid Glass on iOS 26+, tinted surface below.
///
/// Deliberately non-interactive glass: `.interactive()` on this container can
/// claim the touch for the glass highlight and never deliver it to Undo/OK,
/// which leaves the toast up until the removal timer expires.
private struct UndoToastChromeModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppColor.accent.opacity(0.1))
                }
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
        } else {
            content
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppColor.surface)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(AppColor.accent.opacity(0.12))
                        }
                }
                .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        }
    }
}

/// Brief slide-up + fade when the toast appears after a row removal.
extension AnyTransition {
    fileprivate static var undoToastEntrance: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(y: 10)),
            removal: .opacity
        )
    }
}

/// VoiceOver focus targets for the undo toast.
enum UndoToastFocus: Hashable {
    case message
    case undo
}

extension View {
    /// Presents an undo toast above the tab bar after a watchlist removal.
    func watchlistUndoToast(
        isPresented: Bool,
        undoAction: @escaping () -> Void,
        confirmAction: @escaping () -> Void
    ) -> some View {
        modifier(
            WatchlistUndoToastModifier(
                isPresented: isPresented,
                undoAction: undoAction,
                confirmAction: confirmAction
            )
        )
    }
}

/// Presents the undo toast above the tab bar. VoiceOver focus and timing stay
/// VoiceOver-specific in `onChange`; layout is the same with VoiceOver off.
private struct WatchlistUndoToastModifier: ViewModifier {
    let isPresented: Bool
    let undoAction: () -> Void
    let confirmAction: () -> Void

    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceOverRunning
    @AccessibilityFocusState private var toastFocus: UndoToastFocus?
    /// Distance from the home-indicator-safe bottom to the top of the tab bar.
    @State private var tabBarClearance: CGFloat = 49

    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    aboveTabBarToast
                }
            }
            .background {
                TabBarClearanceReader(clearance: $tabBarClearance)
            }
            .animation(.easeOut(duration: 0.2), value: isPresented)
            .onChange(of: isPresented) { _, presented in
                guard presented else {
                    toastFocus = nil
                    return
                }
                guard isVoiceOverRunning else { return }
                Task { @MainActor in
                    // Accessibility workaround: without a short wait VoiceOver
                    // focuses Undo immediately and skips the status message.
                    // Let the toast enter the tree, then focus the status first.
                    try? await Task.sleep(for: .milliseconds(150))
                    guard isPresented else { return }
                    toastFocus = .message

                    // After the status has had time to be read aloud, move focus
                    // to Undo for quick access.
                    try? await Task.sleep(for: .milliseconds(1_800))
                    guard isPresented else { return }
                    toastFocus = .undo
                }
            }
    }

    /// Bottom-centered, just above the tab bar. Full-screen overlay has no
    /// background and is not itself an accessibility element, so empty space
    /// stays pass-through for touch and VoiceOver. Do not apply
    /// `.accessibilityHidden(true)` on this container — that hides the toast.
    private var aboveTabBarToast: some View {
        VStack {
            Spacer()
            toastContent
                .frame(maxWidth: 320)
                .padding(.horizontal, AppSpacing.screen)
            Color.clear
                .frame(height: tabBarClearance + AppSpacing.tight)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilitySortPriority(1)
        .zIndex(1)
        .transition(.undoToastEntrance)
    }

    private var toastContent: some View {
        UndoToast(
            message: String(localized: "Removed from watchlist"),
            undoAction: undoAction,
            confirmAction: confirmAction,
            toastFocus: $toastFocus
        )
    }
}

/// Reads how far the tab bar extends above the home-indicator safe area so the
/// toast can sit just above it from an overlay on the tab root.
private struct TabBarClearanceReader: UIViewControllerRepresentable {
    @Binding var clearance: CGFloat

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.isHidden = true
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Hop out of the representable update so measuring the tab bar does not
        // publish `@State` during the current view pass.
        Task { @MainActor in
            await Task.yield()
            guard let measured = Self.measuredClearance(from: uiViewController) else { return }
            guard abs(measured - clearance) > 0.5 else { return }
            clearance = measured
        }
    }

    private static func measuredClearance(from controller: UIViewController) -> CGFloat? {
        guard let tabBar = controller.tabBarController?.tabBar else { return nil }
        let window = tabBar.window ?? controller.view.window
        guard let window else { return nil }
        let tabBarFrame = tabBar.convert(tabBar.bounds, to: window)
        let safeAreaBottomY = window.bounds.maxY - window.safeAreaInsets.bottom
        return max(0, safeAreaBottomY - tabBarFrame.minY)
    }
}
