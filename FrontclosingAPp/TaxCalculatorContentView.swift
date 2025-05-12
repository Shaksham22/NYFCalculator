import SwiftUI

struct TaxCalculatorContentView: View {
    @State private var inputValue: String = ""
    @State private var isCalculatingFromSubtotal = true
    
    // Computed property that calculates the conversion based on the mode.
    var computedResult: String {
        if let value = Double(inputValue) {
            if isCalculatingFromSubtotal {
                // When input is the subtotal, compute total (including 13% tax)
                return String(format: "%.2f", value * 1.13)
            } else {
                // When input is the total, compute the original subtotal
                return String(format: "%.2f", value / 1.13)
            }
        }
        return ""
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("TAX CALCULATOR")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.leading)
            
            // Toggle between Subtotal -> Total and Total -> Subtotal
            Toggle(isOn: $isCalculatingFromSubtotal) {
                Text(isCalculatingFromSubtotal ? "Calculate Total from Subtotal" : "Calculate Subtotal from Total")
            }
            .padding()
            
            Divider()
            
            // Input Field (always bound to inputValue)
            TextField(isCalculatingFromSubtotal ? "Enter Subtotal" : "Enter Total", text: $inputValue)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(height: 40)
                .padding(.horizontal)
            
            Divider()
            
            // Display the computed value
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
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .padding()
        // Add swipe gesture to dismiss keyboard
        .gesture(
            DragGesture().onChanged { gesture in
                if gesture.translation.height > 0 {
                    dismissKeyboard()
                }
            }
        )
    }
    
    // Function to dismiss the keyboard
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct TaxCalculatorContentView_Previews: PreviewProvider {
    static var previews: some View {
        TaxCalculatorContentView()
    }
}
