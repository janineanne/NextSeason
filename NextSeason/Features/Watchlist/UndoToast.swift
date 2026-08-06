//
//  UndoToast.swift
//  NextSeason
//

import SwiftUI

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
            Text(message)
                .font(.subheadline)
                .appSecondaryText()
                .accessibilityFocused($toastFocus, equals: .message)
            Spacer(minLength: 0)
            Button("Undo", action: undoAction)
                .font(.subheadline.weight(.semibold))
                .accessibilityIdentifier(AccessibilityID.Watchlist.undoButton)
                .accessibilityHint("Restores the show to your watchlist")
                .accessibilityFocused($toastFocus, equals: .undo)
            Button("OK", action: confirmAction)
                .font(.subheadline.weight(.semibold))
                .accessibilityIdentifier(AccessibilityID.Watchlist.confirmButton)
                .accessibilityHint("Confirms removal from your watchlist")
        }
    }
}

/// Floating chrome for the undo toast: Liquid Glass on iOS 26+, material below.
private struct UndoToastChromeModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
        } else {
            content
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

/// VoiceOver focus targets for the undo toast.
enum UndoToastFocus: Hashable {
    case message
    case undo
}

extension View {
    /// Presents an undo toast anchored below (or above) the view that triggered removal.
    func watchlistUndoToast(
        isPresented: Bool,
        anchor: CGRect?,
        undoAction: @escaping () -> Void,
        confirmAction: @escaping () -> Void
    ) -> some View {
        modifier(
            WatchlistUndoToastModifier(
                isPresented: isPresented,
                anchor: anchor,
                undoAction: undoAction,
                confirmAction: confirmAction
            )
        )
    }
}

/// Presents the undo toast either bottom-centered (VoiceOver) or position-anchored
/// near the track button that started the removal (sighted layout).
private struct WatchlistUndoToastModifier: ViewModifier {
    let isPresented: Bool
    let anchor: CGRect?
    let undoAction: () -> Void
    let confirmAction: () -> Void

    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceOverRunning
    @AccessibilityFocusState private var toastFocus: UndoToastFocus?

    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    // VoiceOver: fixed bottom placement is more reliable than
                    // GeometryReader + `.position` near a disappearing row.
                    if isVoiceOverRunning {
                        voiceOverToast
                    } else {
                        anchoredToast
                    }
                }
            }
            .animation(.default, value: isPresented)
            .onChange(of: isPresented) { _, presented in
                guard presented else {
                    toastFocus = nil
                    return
                }
                guard isVoiceOverRunning else { return }
                Task { @MainActor in
                    // Let the toast enter the accessibility tree before focusing.
                    try? await Task.sleep(for: .milliseconds(150))
                    guard isPresented else { return }
                    toastFocus = .message

                    // Read the message, then move focus to Undo for quick access.
                    try? await Task.sleep(for: .milliseconds(1_800))
                    guard isPresented else { return }
                    toastFocus = .undo
                }
            }
    }

    /// Bottom-centered layout avoids full-screen `GeometryReader` traps in VoiceOver.
    private var voiceOverToast: some View {
        VStack {
            Spacer()
            toastContent
                .frame(maxWidth: 320)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilitySortPriority(1)
        .zIndex(1)
        .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .bottom)))
    }

    private var anchoredToast: some View {
        GeometryReader { proxy in
            let containerFrame = proxy.frame(in: .global)
            let resolvedAnchor = anchor ?? .zero
            toastContent
                .frame(maxWidth: min(320, proxy.size.width - 32))
                .fixedSize(horizontal: false, vertical: true)
                .position(
                    toastPosition(
                        in: proxy,
                        containerFrame: containerFrame,
                        anchor: resolvedAnchor
                    )
                )
        }
        .allowsHitTesting(true)
        .zIndex(1)
        .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
    }

    private var toastContent: some View {
        UndoToast(
            message: "Removed from watchlist",
            undoAction: undoAction,
            confirmAction: confirmAction,
            toastFocus: $toastFocus
        )
    }
}

/// Centers the toast under (or above) `anchor` in the overlay's local coordinates.
///
/// Converts the button's global frame into the `GeometryReader`'s space, prefers
/// placement below the button when there is room, otherwise flips above, and
/// clamps X so a ~320pt-wide toast stays inset from the edges.
private func toastPosition(
    in proxy: GeometryProxy,
    containerFrame: CGRect,
    anchor: CGRect
) -> CGPoint {
    let toastHeightEstimate: CGFloat = 48
    let spacing: CGFloat = 8

    // Fall back when the trigger has not reported a frame yet. Prefer mid-screen
    // over the bottom edge so the toast does not pull a near-bottom List row
    // into a scroll jump when it appears.
    if anchor.width < 1 || anchor.height < 1 {
        return CGPoint(x: proxy.size.width / 2, y: proxy.size.height * 0.55)
    }

    // Global → local: subtract the overlay container's global origin.
    let localMidX = anchor.midX - containerFrame.minX
    let belowY = anchor.maxY + spacing + toastHeightEstimate / 2 - containerFrame.minY
    let aboveY = anchor.minY - spacing - toastHeightEstimate / 2 - containerFrame.minY

    let y: CGFloat
    // Prefer below the button; flip above when the toast would clip the bottom.
    if belowY + toastHeightEstimate / 2 <= proxy.size.height - 8 {
        y = belowY
    } else {
        y = max(toastHeightEstimate / 2 + 8, aboveY)
    }

    // Keep the toast's horizontal center within [176, width-176] for a 320pt max width.
    let clampedX = min(
        max(localMidX, 16 + 160),
        proxy.size.width - 16 - 160
    )
    return CGPoint(x: clampedX, y: y)
}
