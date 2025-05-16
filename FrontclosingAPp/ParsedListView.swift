import SwiftUI

struct ParsedListView: View {
    let sections: [ParsedSection]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(section.name.capitalized).font(.headline)
                        ForEach(section.entries, id: \.label) { pair in
                            HStack {
                                Text(pair.label)
                                Spacer()
                                Text(String(format: "%.2f", pair.value))
                            }
                            .font(.system(.body, design: .monospaced))
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
        }
    }
}
