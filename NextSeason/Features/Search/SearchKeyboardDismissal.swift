//
//  SearchKeyboardDismissal.swift
//  NextSeason
//

import SwiftUI

/// Dismisses the keyboard but keeps the query visible in the search field.
func collapseSearchKeyboard(dismissSearch: DismissSearchAction) {
    dismissSearch()
    KeyboardEditing.dismissEditing()
}

/// Nav-bar `.searchable` often ignores `scrollDismissesKeyboard`; drag is a reliable fallback.
struct SearchScrollKeyboardDismissGesture: ViewModifier {
    @Binding var isScrollDismissingKeyboard: Bool
    let dismissSearch: DismissSearchAction

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            DragGesture(minimumDistance: 8, coordinateSpace: .local)
                .onChanged { value in
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
