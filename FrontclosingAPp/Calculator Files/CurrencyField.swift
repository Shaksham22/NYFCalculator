// CurrencyField.swift
import SwiftUI

/// A TextField that stores only digits but **shows** `#.##` live.
struct CurrencyField: View {
    /// Raw digits the user is typing, e.g. "2345"
    @Binding var digits: String
    /// The formatted string you actually use elsewhere, e.g. "23.45"
    @Binding var value: String

    var body: some View {
        ZStack(alignment: .trailing) {
            // ‼️ Overlay that the user sees
            Text(value.isEmpty ? "0.00" : value)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 6)

            // ‼️ Invisible field that receives input
            TextField("", text: $digits)
                .keyboardType(.numberPad)
                .foregroundColor(.clear)   // hide raw digits
                .opacity(0.01)             // keep caret & tap area
                .onChange(of: digits) { newDigits in
                    value = CurrencyInput.formatDigitsToCurrency(newDigits)
                }
        }
        .textFieldStyle(.roundedBorder)
    }
}
