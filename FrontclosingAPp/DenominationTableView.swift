import SwiftUI

struct DenominationTableView: View {
    @State private var alertMessage: String = ""
    @State private var showingAlert: Bool = false
    
    // MARK: - Properties
    let individualDenominationCounts: [Double: Int]
    let bundleDenominationCounts: [Double: Int]
    var sectionTitle: String? = nil  // ✅ Optional title

    /// Combine keys from both dictionaries and sort them in descending order.
    private var sortedDenominations: [Double] {
        let keys = Set(individualDenominationCounts.keys).union(bundleDenominationCounts.keys)
        return keys.sorted(by: >)
    }
    
    /// Provide a default title if none is passed
    private var displayedTitle: String {
        sectionTitle ?? "Denomination Summary"
    }
    
    /// A helper to get the bundle multiplier for a given denomination.
    private func bundleMultiplier(for denom: Double) -> Double {
        switch denom {
        case 1.00: return 25
        case 0.25: return 10
        case 0.10: return 5
        case 0.05: return 2
        default: return 0  // For denominations without bundle support, no multiplier.
        }
    }
    
    /// Computed property to get the grand total of all denominations (individual + bundles)
    private var grandTotal: Double {
        var total = 0.0
        
        for denom in sortedDenominations {
            if let count = individualDenominationCounts[denom], count > 0 {
                total += denom * Double(count)
            }
            if let bundleCount = bundleDenominationCounts[denom], bundleCount > 0 {
                total += bundleMultiplier(for: denom) * Double(bundleCount)
            }
        }
        
        return total
    }

    // Function to format and send the data to the printer
    private func printDenominations() {
        let employeeName = "Admin"
        let currentDate = getCurrentDate()

        var denominationData: [(Double, Int)] = []

        for denom in sortedDenominations {
            if let count = individualDenominationCounts[denom], count > 0 {
                denominationData.append((denom, count))
            }
            if let bundleCount = bundleDenominationCounts[denom], bundleCount > 0 {
                let totalBundleValue = Int(bundleMultiplier(for: denom)) * bundleCount
                denominationData.append((denom, totalBundleValue))
            }
        }

        // ✅ Send data to the printer
        StarPrinterManager.printReceipt(
                    employeeName: employeeName,
                    currentDate: currentDate,
                    individualDenominationCounts: individualDenominationCounts,
                    bundleDenominationCounts: bundleDenominationCounts
                ) { result in
                    alertMessage = result
                    showingAlert = true
                }
            }

    /// Helper function to fetch the current date in a formatted way
    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: Date())
    }

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(displayedTitle) // ✅ Uses default or provided title
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center) // ✅ Centers the text horizontally
                .multilineTextAlignment(.center) // ✅ Ensures proper centering for multi-line titles
                .padding(.bottom, 5)
            
            ForEach(sortedDenominations, id: \.self) { denom in
                if let count = individualDenominationCounts[denom], count > 0 {
                    HStack {
                        Text("\(denom, specifier: "%.2f") $")
                            .frame(width: 90, alignment: .leading)
                            .padding(.leading, 5)
                        
                        Text(" x ")
                            .frame(width: 20)
                        
                        Text("\(count)")
                            .frame(width: 40, alignment: .center)
                        
                        Text("=")
                            .frame(width: 10)
                        
                        let individualTotal = denom * Double(count)
                        Text(String(format: "%.2f", individualTotal))
                            .frame(width: 80, alignment: .trailing)
                    }
                }

                if let bundleCount = bundleDenominationCounts[denom], bundleCount > 0 {
                    HStack {
                        Text("\(denom, specifier: "%.2f") $")
                            .frame(width: 90, alignment: .leading)
                            .padding(.leading, 5)
                        
                        Text(" x ")
                            .frame(width: 20)
                        
                        Text("(\(bundleCount))")
                            .frame(width: 40, alignment: .center)
                        
                        Text("=")
                            .frame(width: 10)
                        
                        let bundleTotal = bundleMultiplier(for: denom) * Double(bundleCount)
                        Text(String(format: "%.2f", bundleTotal))
                            .frame(width: 80, alignment: .trailing)
                    }
                }
            }

            Divider()
                .padding(.vertical, 5)
            
            // MARK: - Total
            HStack {
                Text("Total:")
                    .bold()
                Spacer()
                Text(String(format: "%.2f", grandTotal))
                    .bold()
            }
            
            // MARK: - Print Button
            Button(action: {
                printDenominations()
            }) {
                Text("Print")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding()
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Printer Status"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
