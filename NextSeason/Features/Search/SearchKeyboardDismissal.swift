//
//  SearchKeyboardDismissal.swift
//  NextSeason
//

import SwiftUI

/// Search-field keyboard helpers used by `SearchView`.
///
/// `.searchable` keeps the query in the nav bar when the keyboard goes away;
/// we still need an explicit dismiss because system scroll-to-dismiss is
/// unreliable with that placement. Call sites: submit / “search” actions use
/// `collapseSearchKeyboard`; result lists use the drag gesture modifier.

/// Collapses the keyboard without clearing the query.
///
/// `dismissSearch()` is the SwiftUI searchable action; `KeyboardEditing` is a
/// UIKit fallback that resigns first responder when searchable alone is not enough.
func collapseSearchKeyboard(dismissSearch: DismissSearchAction) {
    dismissSearch()
    KeyboardEditing.dismissEditing()
}

/// Dismisses the keyboard when the user starts scrolling a search results list.
///
/// Nav-bar `.searchable` often ignores `scrollDismissesKeyboard`, so this adds a
/// `simultaneousGesture` drag: once vertical movement exceeds a small threshold,
/// collapse once per gesture (`isScrollDismissingKeyboard` latches until finger up)
/// without blocking the list’s own scroll.
struct SearchScrollKeyboardDismissGesture: ViewModifier {
    @Binding var isScrollDismissingKeyboard: Bool
    let dismissSearch: DismissSearchAction

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            DragGesture(minimumDistance: 8, coordinateSpace: .local)
                .onChanged { value in
                    // One dismiss per drag; ignore tiny jitters before threshold.
                    guard !isScrollDismissingKeyboard else { return }
                    guard abs(value.translation.height) > 4 else { return }
                    isScrollDismissingKeyboard = true
                    collapseSearchKeyboard(dismissSearch: dismissSearch)
                }
                .onEnded { _ in
                    isScrollDismissingKeyboard = false
                }
        )
    }
}

extension View {
    /// Applies `SearchScrollKeyboardDismissGesture` to a scrollable search surface.
    func searchScrollKeyboardDismissGesture(
        isScrollDismissingKeyboard: Binding<Bool>,
        dismissSearch: DismissSearchAction
    ) -> some View {
        modifier(
            SearchScrollKeyboardDismissGesture(
                isScrollDismissingKeyboard: isScrollDismissingKeyboard,
                dismissSearch: dismissSearch
            )
        )
    }
}
