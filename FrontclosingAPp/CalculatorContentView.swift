import SwiftUI

struct CalculatorContentView: View {
    @State private var denominationcount: [Double: String] = [
        100.00: "", 50.00: "", 20.00: "", 10.00: "", 5.00: "", 2.00: "", 1.00: "", 0.25: "", 0.10: "", 0.05: ""
    ]
    @State private var denominationsbundle: [Double: String] = [1.00: "", 0.25: "", 0.10: "", 0.05: ""]
    @State private var calculatedResultscount: [Double: Double] = [:] // Store calculated results for denomination count
    @State private var calculatedResultsbundle: [Double: Double] = [:] // Store calculated results for denomination bundles
    @State private var totalSum: Double = 0.0 // Store the total sum of all calculated results
    @State private var showResults: Bool = false // ✅ Controls when to show DenominationTableView
    @State private var tableName: String? = nil

    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Denomination Count")) {
                    ForEach(denominationcount.keys.sorted(by: >), id: \.self) { denom in
                        HStack {
                            Text("\(denom, specifier: "%.2f") $")
                                .frame(width: 90, alignment: .leading)
                                .padding(.leading, 5)
                            
                            Spacer()
                            Text(" x ")
                                .frame(width: 20)
                            Spacer()

                            TextField("", text: Binding(
                                get: { self.denominationcount[denom] ?? "" },
                                set: { self.denominationcount[denom] = $0 }
                            ))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                            .multilineTextAlignment(.center)
                            .padding(.trailing, 5)
                            Spacer()
                            Text("=")
                                .frame(width: 10)
                            Spacer()
                            
                            if let result = self.calculatedResultscount[denom], result != 0.0 {
                                TextField(String(format: "%.2f", result), text: .constant(""))
                                    .disabled(true)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 80)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.black)
                                    .padding(.trailing, 5)
                            } else {
                                TextField("", text: .constant(""))
                                    .disabled(true)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 80)
                                    .multilineTextAlignment(.center)
                                    .padding(.trailing, 5)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
                
                Section(header: Text("Denomination Bundles")) {
                    ForEach(denominationsbundle.keys.sorted(by: >), id: \.self) { denom in
                        HStack {
                            Text("Bundles of \(denom, specifier: "%.2f") $")
                                .frame(width: 90, alignment: .leading)
                                .padding(.leading, 5)
                            
                            Spacer()
                            Text("x")
                                .frame(width: 20)
                            Spacer()

                            TextField("", text: Binding(
                                get: { self.denominationsbundle[denom] ?? "" },
                                set: { self.denominationsbundle[denom] = $0 }
                            ))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                            .multilineTextAlignment(.center)
                            .padding(.trailing, 5)
                            Spacer()
                            Text("=")
                                .frame(width: 10)
                            Spacer()
                            
                            if let result = self.calculatedResultsbundle[denom], result != 0.0 {
                                TextField(String(format: "%.2f", result), text: .constant(""))
                                    .disabled(true)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 80)
                                    .multilineTextAlignment(.center)
                                    .padding(.trailing, 5)
                                    .foregroundColor(.black)
                                    
                            } else {
                                TextField("", text: .constant(""))
                                    .disabled(true)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 80)
                                    .multilineTextAlignment(.center)
                                    .padding(.trailing, 5)
                                    .foregroundColor(.black)
                                    
                                }
                        }
                    }
                }
                
                Section(header: Text("Total Sum")) {
                    HStack {
                        Text("Total Sum:")
                            .frame(width: 90, alignment: .leading)
                            .padding(.leading, 5)
                        
                        Spacer()
                        
                        Text(String(format: "%.2f $", totalSum))
                            .frame(width: 150)
                            .foregroundColor(.black)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            
            HStack {
                // ✅ Calculate Button
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
                
                // ✅ View Button (opens modal)
                Button(action: {
                    showTableNameAlert()
                }) {
                    Text("View")
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(BorderlessButtonStyle())
                .buttonStyle(BorderlessButtonStyle())
                .sheet(isPresented: $showResults) {
                    VStack {
                        DenominationTableView(
                            individualDenominationCounts: denominationcount.mapValues { Int($0) ?? 0 },
                            bundleDenominationCounts: denominationsbundle.mapValues { Int($0) ?? 0 },
                            tableTitle: tableName
                        )

                        Button(action: {
                            showResults = false
                        }) {
                            Text("Close")
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding()
                    }
                    .padding()
                }

                // ✅ Reset Button
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
    }

    private func calculate() {
        for (denom, value) in denominationcount {
            if let quantity = Double(value) {
                calculatedResultscount[denom] = denom * quantity
            } else {
                calculatedResultscount[denom] = 0.0
            }
        }
        
        for (denom, value) in denominationsbundle {
            if let quantity = Double(value) {
                calculatedResultsbundle[denom] = bundleMultiplier(for: denom) * quantity
            } else {
                calculatedResultsbundle[denom] = 0.0
            }
        }
        
        totalSum = calculatedResultscount.values.reduce(0, +) + calculatedResultsbundle.values.reduce(0, +)
        dismissKeyboard()
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func reset() {
        denominationcount.keys.forEach { denominationcount[$0] = "" }
        denominationsbundle.keys.forEach { denominationsbundle[$0] = "" }
        calculatedResultscount = [:]
        calculatedResultsbundle = [:]
        totalSum = 0.0
        showResults = false
    }

    private func bundleMultiplier(for denom: Double) -> Double {
        return [1.00: 25, 0.25: 10, 0.10: 5, 0.05: 2][denom] ?? 0
    }
    
    private func showTableNameAlert() {
        let alert = UIAlertController(title: "Enter Table Name", message: "This will be displayed on the top of print slip", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Type Table Name (optional)"
        }

        let continueAction = UIAlertAction(title: "Continue", style: .default) { _ in
            let inputName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            DispatchQueue.main.async {
                self.tableName = inputName?.isEmpty == false ? inputName : nil
                self.showResults = true
            }
        }

        alert.addAction(continueAction) // ✅ Only "Continue" button

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true, completion: nil)
        }
    }

}
