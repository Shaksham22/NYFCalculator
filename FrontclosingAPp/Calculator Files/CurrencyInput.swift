//  CurrencyInput.swift
//  Drop this in your project once and reuse everywhere
import SwiftUI
import Foundation

enum CurrencyInput {
    
    /// Formats a string of digits to two-decimal currency style.
    /// "2345" ➜ "23.45",  "2" ➜ "0.02"
    static func formatDigitsToCurrency(_ digits: String) -> String {
        let filtered = digits.filter(\.isWholeNumber)
        guard let intVal = Int(filtered) else { return "" }
        let asDouble = Double(intVal) / 100.0
        return String(format: "%.2f", asDouble)
    }
    
    /// Convenience helper that builds the `Binding` for a TextField.
    ///
    /// Usage:
    /// ```swift
    /// TextField("Amount",
    ///           text: CurrencyInput.binding(raw: $rawDigits,
    ///                                       value: $formattedText))
    /// ```
    static func binding(raw: Binding<String>,
                        value: Binding<String>) -> Binding<String> {
        Binding<String>(
            get: { Self.formatDigitsToCurrency(raw.wrappedValue) },
            set: { newText in
                raw.wrappedValue = newText.filter(\.isWholeNumber)
                value.wrappedValue = Self.formatDigitsToCurrency(raw.wrappedValue)
            }
        )
    }
}
