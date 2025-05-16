import SwiftUI

struct TaxCalculatorContentView: View {
    @State private var inputValue: String = ""
    @State private var isCalculatingFromSubtotal = true
    @FocusState private var isInputFocused: Bool

    var computedResult: String {
        if let value = Double(inputValue) {
            return isCalculatingFromSubtotal ?
                String(format: "%.2f", value * 1.13) :
                String(format: "%.2f", value / 1.13)
        }
        return ""
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text("TAX CALCULATOR")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.leading)

                // Toggle Mode
                Toggle(isOn: $isCalculatingFromSubtotal) {
                    Text(isCalculatingFromSubtotal ? "Calculate Total from Subtotal" : "Calculate Subtotal from Total")
                }
                .padding()

                Divider()

                // Input Field
                TextField(isCalculatingFromSubtotal ? "Enter Subtotal" : "Enter Total", text: $inputValue)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(height: 40)
                    .padding(.horizontal)
                    .focused($isInputFocused)

                Divider()

                // Result Display
                HStack {
                    Text(isCalculatingFromSubtotal ? "Total (including tax):" : "Subtotal (before tax):")
                        .font(.title3)
                    Spacer()
                    Text(computedResult)
                        .font(.title3)
                        .padding(.trailing)
                }
                .padding()

                Divider()

                // Clear Button
                Button(action: {
                    inputValue = ""
                    isInputFocused = false
                }) {
                    Text("Clear")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .padding()
        .onTapGesture {
            isInputFocused = false // dismiss keyboard on tap outside
        }
    }
}
