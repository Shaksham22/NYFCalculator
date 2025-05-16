import SwiftUI

struct CustomTabBarView: View {
    @Binding var selectedIndex: Int

    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(icon: "desktopcomputer", title: "Sales Calculator", index: 0, selectedIndex: $selectedIndex)
            Divider().frame(height: 30)
            TabBarButton(icon: "archivebox", title: "General Calculator", index: 1, selectedIndex: $selectedIndex)
            Divider().frame(height: 30)
            TabBarButton(icon: "percent", title: "Tax Calculator", index: 2, selectedIndex: $selectedIndex)
            Divider().frame(height: 30)
            TabBarButton(icon: "doc.text.viewfinder", title: "DSR Scanner", index: 3, selectedIndex: $selectedIndex)
        }
        .frame(height: 60)
        .background(Color(UIColor.systemGray6))
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let index: Int
    @Binding var selectedIndex: Int

    var body: some View {
        Button(action: {
            selectedIndex = index
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                Text(title)
                    .font(.caption2)
            }
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity)
            .foregroundColor(selectedIndex == index ? .blue : .gray)
        }
    }
}
