// TabBarHider.swift
import SwiftUI

struct TabBarHider: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear { UITabBar.appearance().isHidden = true }
            .onDisappear { UITabBar.appearance().isHidden = false }
    }
}
extension View {
    func hideTabBar() -> some View { self.modifier(TabBarHider()) }
}
