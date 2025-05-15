import SwiftUI

// 1) A simple SwiftUI view that just renders your generated image
struct ReceiptGeneratorPreviewView: View {
    // sample data
    let individual: [Double: Int] = [100: 2, 50: 1, 20: 3, 0.05: 4]
    let bundle:     [Double: Int] = [0.10: 5,   0.05: 2]

    var body: some View {
        // generate the UIImage ONCE
        let img = ReceiptGenerator.generateReceiptImage(
            employeeName:                  "Jane Doe",
            currentDate:                   "May 13, 2025",
            tableTitle:                    "Denomination Preview",
            individualDenominationCounts:  individual,
            bundleDenominationCounts:      bundle,
            width:                         350  // you can tweak this in preview
        )

        // show it
        ScrollView {
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .padding()
        }
        .background(Color(white: 0.95))
    }
}

// 2) The PreviewProvider that Xcode picks up
struct ReceiptGeneratorPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light and dark modes
            ReceiptGeneratorPreviewView()
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.light)

            ReceiptGeneratorPreviewView()
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.dark)
        }
    }
}
