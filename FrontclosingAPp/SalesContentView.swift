import SwiftUI

struct SalesContentView: View {
    @State private var totalSales: String = ""
    @State private var midDaySales: String = ""
    @State private var denominations: [Double: String] = [
        100.00: "", 50.00: "", 20.00: "", 10.00: "", 5.00: "", 2.00: "", 1.00: "", 0.25: "", 0.10: "", 0.05: ""
    ]
    @State private var allocatedX: [Double: Int] = [:]
    @State private var remainingDenominations: [Double: Int] = [:]
    @State private var message: String = ""
    @State private var showResults: Bool = false
    @State private var endDaySale: Double = 0.0
    @State private var remainingSum: Double = 0.0

    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    var body: some View {
        VStack {
            Form {
                // MARK: - Sales Information Section
                Section(header: Text("Sales Information")) {
                    HStack {
                        Text("Total Sales")
                        Spacer()
                        TextField("Total Sales", text: $totalSales)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 150)
                    }
                    HStack {
                        Text("Mid-Day Sales")
                        Spacer()
                        TextField("Mid-Day Sales", text: $midDaySales)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 150)
                    }
                    HStack {
                        Text("End Day Sale")
                        Spacer()
                        TextField("", text: .constant(String(format: "%.2f", endDaySale)))
                            .disabled(true)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.black)
                            .frame(width: 150)
                    }
                }

                // MARK: - Denominations Input Section
                Section(header: Text("Denominations")) {
                    ForEach(denominations.keys.sorted(by: >), id: \.self) { denom in
                        HStack {
                            Text("\(denom, specifier: "%.2f") $")
                            Spacer()
                            TextField("", text: Binding(
                                get: { self.denominations[denom] ?? "" },
                                set: { self.denominations[denom] = $0 }
                            ))
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 150)
                        }
                    }
                }
                
                // MARK: - Results Sections (Using DenominationTableView)
                if showResults {
                    // Allocated Denominations for Bank Deposit
                    DenominationTableView(
                        individualDenominationCounts: allocatedX,
                        bundleDenominationCounts: [:], // or pass the actual bundle dictionary if available
                        sectionTitle: "Bank Deposit Money"
                    )

                    // Remaining Denominations for Till
                    DenominationTableView(
                        individualDenominationCounts: remainingDenominations,
                        bundleDenominationCounts: [:], // or pass the actual bundle dictionary if available
                        sectionTitle: "Till Money"
                    )
                }
                // MARK: - Message Display
                Text(message)
                    .padding()
                    .foregroundColor(messageColor())
            }
            .scrollDismissesKeyboard(.interactively)
            
            // MARK: - Action Buttons
            HStack {
                Button(action: {
                    self.calculate()
                }) {
                    Text("Calculate")
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Button(action: {
                    self.reset()
                }) {
                    Text("Reset")
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding()
        .onAppear {
            self.endDaySale = self.calculateEndDaySale()
        }
    }

    // MARK: - Calculation Function
    private func calculate() {
        let totalSalesValue = Double(totalSales) ?? 0.0
        let midDaySalesValue = Double(midDaySales) ?? 0.0
        endDaySale = totalSalesValue - midDaySalesValue
        
        var denominationsCopy = denominations.mapValues { Int($0) ?? 0 }
        var allocated: [Double: Int] = [:]
        var remainingX = endDaySale

        for denom in denominationsCopy.keys.sorted(by: >) {
            while denominationsCopy[denom]! > 0 && remainingX >= denom {
                denominationsCopy[denom]! -= 1
                allocated[denom, default: 0] += 1
                remainingX -= denom
                remainingX = round(remainingX * 100) / 100  // To avoid floating point precision issues
            }
        }

        allocatedX = allocated

        if remainingX > 0 {
            message = "Not enough denominations to allocate for the end closing. Remaining amount: $\(String(format: "%.2f", remainingX)) cannot be calculated."
            remainingSum = remainingX
        } else {
            remainingDenominations = denominationsCopy
            remainingSum = calculate_remaining(denominationsCopy)

            if remainingSum == 100 {
                message = "Remaining amount sums to exactly $100"
            } else if remainingSum > 100 {
                message = "Till Amount is more by $\(String(format: "%.2f", remainingSum - 100))"
            } else {
                message = "Till Amount is less by $\(String(format: "%.2f", 100 - remainingSum))"
            }
            
            // Dismiss the keyboard after calculation
            dismissKeyboard()
            
            // Show results after calculation
            showResults = true
        }
    }

    // MARK: - Dismiss Keyboard Function
    private func dismissKeyboard() {
        // Dismiss the keyboard by sending a resignFirstResponder action
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Calculate Remaining Sum
    private func calculate_remaining(_ denominations: [Double: Int]) -> Double {
        return denominations.reduce(0) { $0 + $1.key * Double($1.value) }
    }

    // MARK: - Reset Function
    private func reset() {
        totalSales = ""
        midDaySales = ""
        denominations = [
            100.00: "", 50.00: "", 20.00: "", 10.00: "", 5.00: "", 2.00: "", 1.00: "", 0.25: "", 0.10: "", 0.05: ""
        ]
        allocatedX = [:]
        remainingDenominations = [:]
        message = ""
        showResults = false
        endDaySale = 0.0
        remainingSum = 0.0
        
        // Dismiss the keyboard on reset
        dismissKeyboard()
    }
    
    // MARK: - Calculate End Day Sale
    private func calculateEndDaySale() -> Double {
        let totalSalesValue = Double(totalSales) ?? 0.0
        let midDaySalesValue = Double(midDaySales) ?? 0.0
        return totalSalesValue - midDaySalesValue
    }

    // MARK: - Message Color based on remainingSum
    private func messageColor() -> Color {
        if remainingSum == 100 {
            return .green
        } else if remainingSum > 100 {
            return .blue
        } else {
            return .red
        }
    }
}

struct SalesContentView_Previews: PreviewProvider {
    static var previews: some View {
        SalesContentView()
    }
}
