import SwiftUI

struct DenominationTableView: View {
    @EnvironmentObject var userData: UserData // 🔧 Add this line
    @State private var alertMessage: String = ""
    @State private var showingAlert: Bool = false
    
    let individualDenominationCounts: [Double: Int]
    let bundleDenominationCounts: [Double: Int]
    var tableTitle: String? = nil

    private var sortedDenominations: [Double] {
        let keys = Set(individualDenominationCounts.keys).union(bundleDenominationCounts.keys)
        return keys.sorted(by: >)
    }

    private var displayedTitle: String {
        tableTitle ?? "Denomination Summary"
    }

    private func bundleMultiplier(for denom: Double) -> Double {
        switch denom {
        case 1.00: return 25
        case 0.25: return 10
        case 0.10: return 5
        case 0.05: return 2
        default: return 0
        }
    }

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

    private func printDenominations() {
        let employeeName = userData.name.isEmpty ? "Admin" : userData.name // 🔧 Updated
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
        print("🖨️ Printing with title: \(tableTitle ?? "nil")")

        StarPrinterManager.printReceipt(
            employeeName: employeeName,
            currentDate: currentDate,
            tableTitle: tableTitle ?? "Denomination Summary",
            individualDenominationCounts: individualDenominationCounts,
            bundleDenominationCounts: bundleDenominationCounts
        ) { result in
            alertMessage = result
            showingAlert = true
        }
    }

    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(displayedTitle)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .padding(.bottom, 5)
            
            ForEach(sortedDenominations, id: \.self) { denom in
                if let count = individualDenominationCounts[denom], count > 0 {
                    HStack {
                        Text("\(denom, specifier: "%.2f") $")
                            .frame(width: 90, alignment: .leading)
                            .padding(.leading, 5)
                        Text(" x ").frame(width: 20)
                        Text("\(count)").frame(width: 40, alignment: .center)
                        Text("=").frame(width: 10)
                        Text(String(format: "%.2f", denom * Double(count)))
                            .frame(width: 80, alignment: .trailing)
                    }
                }

                if let bundleCount = bundleDenominationCounts[denom], bundleCount > 0 {
                    HStack {
                        Text("\(denom, specifier: "%.2f") $")
                            .frame(width: 90, alignment: .leading)
                            .padding(.leading, 5)
                        Text(" x ").frame(width: 20)
                        Text("(\(bundleCount))").frame(width: 40, alignment: .center)
                        Text("=").frame(width: 10)
                        Text(String(format: "%.2f", bundleMultiplier(for: denom) * Double(bundleCount)))
                            .frame(width: 80, alignment: .trailing)
                    }
                }
            }

            Divider().padding(.vertical, 5)

            HStack {
                Text("Total:").bold()
                Spacer()
                Text(String(format: "%.2f", grandTotal)).bold()
            }

            Button(action: { printDenominations() }) {
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
            Alert(title: Text("Printer Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}
