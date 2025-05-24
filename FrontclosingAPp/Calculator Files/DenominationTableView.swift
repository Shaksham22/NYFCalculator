import SwiftUI

struct DenominationTableView: View {
    @EnvironmentObject var userData: UserData
    @State private var alertMessage: String = ""
    @State private var showingAlert: Bool = false
    
    let individualDenominationCounts: [Double: Int]
    let bundleDenominationCounts: [Double: Int]
    var tableTitle: String? = nil
    
    var  isEndDay: Bool = false                 // default keeps old behaviour
    var  salesSummary: (total: Double,
                        midDay: Double,
                        endDay: Double)? = nil

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
            let employeeName = userData.name.isEmpty ? "Admin" : userData.name
            let currentDate  = getCurrentDate()

            let img = ReceiptGenerator.generateReceiptImage(
                employeeName: employeeName,
                currentDate:  currentDate,
                tableTitle:   tableTitle ?? "Denomination Summary",
                individualDenominationCounts: individualDenominationCounts,
                bundleDenominationCounts:     bundleDenominationCounts,
                isEndDay:      isEndDay,
                salesSummary:  salesSummary          // ← nil for Mid-Day
            )

            StarPrinterManager.queueImage(img) { status in
                alertMessage = status
                showingAlert = true
            }
        }// ←–– Here’s the missing brace to close printDenominations()

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
                .padding(.bottom, 5)
            
            ForEach(sortedDenominations, id: \.self) { denom in
                if let count = individualDenominationCounts[denom], count > 0 {
                    HStack {
                        Text("\(denom, specifier: "%.2f") $")
                        Spacer()
                        Text("x \(count)")
                        Spacer()
                        Text(String(format: "%.2f", denom * Double(count)))
                    }
                }

                if let bundleCount = bundleDenominationCounts[denom], bundleCount > 0 {
                    HStack {
                        Text("\(denom, specifier: "%.2f") $")
                        Spacer()
                        Text("x (\(bundleCount))")
                        Spacer()
                        Text(String(format: "%.2f", bundleMultiplier(for: denom) * Double(bundleCount)))
                    }
                }
            }

            Divider().padding(.vertical, 5)

            HStack {
                Text("Total:").bold()
                Spacer()
                Text(String(format: "%.2f", grandTotal)).bold()
            }

            Button("Print") {
                printDenominations()
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
            .padding(.top, 10)
        }
        .padding()
        .alert("Printer Status", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}
