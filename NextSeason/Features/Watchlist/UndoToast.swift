//
//  UndoToast.swift
//  NextSeason
//

import SwiftUI

/// Confirmation toast shown after removing a show from the watchlist.
struct UndoToast: View {
    let message: String
    let undoAction: () -> Void
    let confirmAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(message)
                .font(.subheadline)
                .appSecondaryText()
            Spacer(minLength: 0)
            Button("Undo", action: undoAction)
                .font(.subheadline.weight(.semibold))
                .accessibilityIdentifier(AccessibilityID.Watchlist.undoButton)
            Button("OK", action: confirmAction)
                .font(.subheadline.weight(.semibold))
                .accessibilityIdentifier(AccessibilityID.Watchlist.confirmButton)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

extension View {
    /// Presents an undo toast anchored below (or above) the view that triggered removal.
    func watchlistUndoToast(
        isPresented: Bool,
        anchor: CGRect?,
        undoAction: @escaping () -> Void,
        confirmAction: @escaping () -> Void
    ) -> some View {
        overlay {
            if isPresented {
                GeometryReader { proxy in
                    let containerFrame = proxy.frame(in: .global)
                    let resolvedAnchor = anchor ?? .zero
                    UndoToast(
                        message: "Removed from watchlist",
                        undoAction: undoAction,
                        confirmAction: confirmAction
                    )
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
        }
        .animation(.default, value: isPresented)
    }
}

private func toastPosition(
    in proxy: GeometryProxy,
    containerFrame: CGRect,
    anchor: CGRect
) -> CGPoint {
    let toastHeightEstimate: CGFloat = 48
    let spacing: CGFloat = 8

    // Fall back when the trigger button has not reported a frame yet.
    if anchor.width < 1 || anchor.height < 1 {
        return CGPoint(x: proxy.size.width / 2, y: proxy.size.height - toastHeightEstimate)
    }

    let localMidX = anchor.midX - containerFrame.minX
    let belowY = anchor.maxY + spacing + toastHeightEstimate / 2 - containerFrame.minY
    let aboveY = anchor.minY - spacing - toastHeightEstimate / 2 - containerFrame.minY

    let y: CGFloat
    if belowY + toastHeightEstimate / 2 <= proxy.size.height - 8 {
        y = belowY
    } else {
        y = max(toastHeightEstimate / 2 + 8, aboveY)
    }

    let clampedX = min(
        max(localMidX, 16 + 160),
        proxy.size.width - 16 - 160
    )
    return CGPoint(x: clampedX, y: y)
}
