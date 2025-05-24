import SwiftUI
import UIKit   // for dismissKeyboard()

struct SalesContentView: View {
    // ───── End-Day / Mid-Day toggle ─────
    private enum CalcMode: String, CaseIterable, Identifiable {
        case endDay = "End Day"
        case midDay = "Mid Day"
        var id: Self { self }
    }
    @State private var calcMode: CalcMode = .endDay

    // ───────────────────────────── Inputs ─────────────────────────────
    @State private var totalSales: String = ""
    @State private var midDaySales: String = ""
    @State private var denominations: [Double: String] = [
        100.00: "", 50.00: "", 20.00: "", 10.00: "",
          5.00: "",  2.00: "",  1.00: "",  0.25: "",
          0.10: "",  0.05: ""
    ]

    // ─────────────────────── Computed / Results ───────────────────────
    @State private var allocatedX:            [Double: Int] = [:]
    @State private var remainingDenominations:[Double: Int] = [:]
    @State private var endDaySale:            Double        = 0.0
    @State private var remainingSum:          Double        = 0.0

    // ───────────────────────── UI State ───────────────────────────────
    @State private var message:     String = ""
    @State private var showResults: Bool   = false

    // Split / Generate mode
    private enum SplitMode { case normal, split100, generated100 }
    @State private var splitMode: SplitMode = .normal

    // ───────────────────────── Number Formatter ───────────────────────
    private let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()

    // ───────────────────────────── View ───────────────────────────────
    var body: some View {
        VStack {
            Form {
                // ── 0. Mode picker ────────────────────────────────────────
                Section {
                    Picker("Mode", selection: $calcMode) {
                        ForEach(CalcMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // ── 1. Sales Info ───────────────────────────────────────
                Section(header: Text("Sales Information")) {
                    HStack {
                        Text("Total Sales")
                        Spacer()
                        TextField("Total Sales", text: $totalSales)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 150)
                    }

                    // only show Mid-Day in End Day mode
                    if calcMode == .endDay {
                        HStack {
                            Text("Mid-Day Sales")
                            Spacer()
                            TextField("Mid-Day Sales", text: $midDaySales)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 150)
                        }
                    }

                    HStack {
                        Text("End Day Sale")
                        Spacer()
                        TextField(
                            "",
                            text: .constant(String(format: "%.2f", endDaySale))
                        )
                        .disabled(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 150)
                    }
                }

                // ── 2. Denomination Inputs ───────────────────────────
                Section(header: Text("Denominations")) {
                    ForEach(denominations.keys.sorted(by: >), id: \.self) { denom in
                        HStack {
                            Text(String(format: "%.2f", denom) + " $")
                            Spacer()
                            TextField(
                                "",
                                text: Binding(
                                    get: { self.denominations[denom] ?? "" },
                                    set: { self.denominations[denom] = $0 }
                                )
                            )
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 150)
                        }
                    }
                }

                // ── 3. Results Section(s) ─────────────────────────────
                if showResults {
                    // 3-a. Bank deposit table
                    DenominationTableView(
                        individualDenominationCounts: allocatedX,
                        bundleDenominationCounts: [:],
                        tableTitle: calcMode == .midDay
                            ? "Mid Day Deposit"
                            : "Bank Deposit Money",
                        isEndDay: calcMode == .endDay,
                        salesSummary: calcMode == .endDay
                            ? (total: Double(totalSales) ?? 0,
                               midDay: Double(midDaySales) ?? 0,
                               endDay: endDaySale)
                            : nil
                    )

                    // 3-b. Till money
                    switch splitMode {
                    case .normal:
                        DenominationTableView(
                            individualDenominationCounts: remainingDenominations,
                            bundleDenominationCounts: [:],
                            tableTitle: "Till Money"
                        )
                    case .split100:
                        let (first100, remainder) = computeSplitDistributions()
                        DenominationTableView(
                            individualDenominationCounts: first100,
                            bundleDenominationCounts: [:],
                            tableTitle: "Till: First $100"
                        )
                        DenominationTableView(
                            individualDenominationCounts: remainder,
                            bundleDenominationCounts: [:],
                            tableTitle: "Till: Remainder"
                        )
                    case .generated100:
                        let generated = computeGeneratedDistribution()
                        DenominationTableView(
                            individualDenominationCounts: generated,
                            bundleDenominationCounts: [:],
                            tableTitle: "Till – Generated to $100"
                        )
                    }

                    // 3-c. Action button(s)
                    Group {
                        if splitMode == .normal {
                            if remainingSum > 100 {
                                Button("Split Till Money") { splitMode = .split100 }
                            } else if remainingSum < 100 {
                                Button("Generate to $100") { splitMode = .generated100 }
                            }
                        } else {
                            Button("Revert") { splitMode = .normal }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }

                // 3-d. Status message
                if !message.isEmpty {
                    Text(message)
                        .padding()
                        .foregroundColor(messageColor())
                }
            }
            .scrollDismissesKeyboard(.interactively)

            // ── 4. Bottom buttons ───────────────────────────────────
            HStack(spacing: 12) {
                Button("Calculate") { calculate() }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                Button("Reset") { reset() }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 8)
        }
        .padding()
        .onAppear { endDaySale = calculateEndDaySale() }
        .onChange(of: calcMode) { newMode in
            if newMode == .midDay {
                midDaySales = ""
            }
        }
    }

    // ─────────────────────── Core Calculation ────────────────────────
    private func calculate() {
        let total = Double(totalSales) ?? 0
        let mid = (calcMode == .endDay)
            ? Double(midDaySales) ?? 0
            : 0
        endDaySale = total - mid

        // … rest of your unchanged logic …
        var avail = denominations.mapValues { Int($0) ?? 0 }
        var allocated: [Double:Int] = [:]
        var remaining = endDaySale

        for denom in avail.keys.sorted(by: >) {
            while avail[denom]! > 0, remaining >= denom {
                avail[denom]! -= 1
                allocated[denom, default: 0] += 1
                remaining -= denom
                remaining = (remaining * 100).rounded() / 100
            }
        }

        allocatedX = allocated
        remainingDenominations = avail
        remainingSum = avail.reduce(0) { $0 + $1.key * Double($1.value) }

        if remaining > 0 {
            message = "Not enough denominations to allocate $" +
                      String(format: "%.2f", remaining) + "."
        } else {
            if remainingSum == 100 {
                message = "Till amount is exactly $100."
            } else if remainingSum > 100 {
                message = "Till amount is more by $" +
                          String(format: "%.2f", remainingSum - 100) + "."
            } else {
                message = "Till amount is less by $" +
                          String(format: "%.2f", 100 - remainingSum) + "."
            }
            showResults = true
        };
        splitMode = .normal
        dismissKeyboard()
    }

    // ───────────────────── Split / Generate Helpers ──────────────────
    private func computeSplitDistributions()
        -> (first100: [Double:Int], remainder: [Double:Int])
    {
        var copy = remainingDenominations
        var first100: [Double:Int] = [:]
        var sumUsed: Double = 0

        for d in copy.keys.sorted(by: >) {
            while let cnt = copy[d], cnt > 0, sumUsed + d <= 100 {
                copy[d]! -= 1
                first100[d, default: 0] += 1
                sumUsed += d
            }
        }
        return (first100, copy)
    }

    private func computeGeneratedDistribution() -> [Double:Int] {
        let missing = ((100 - remainingSum) * 100).rounded() / 100
        let denomList = [100.00,50.00,20.00,10.00,5.00,2.00,1.00,0.25,0.10,0.05]
        var extra: [Double:Int] = [:]
        var left = missing

        for d in denomList {
            let count = Int(left / d)
            if count > 0 {
                extra[d] = count
                left -= Double(count) * d
                left = (left * 100).rounded() / 100
            }
        }
        var combined = remainingDenominations
        for (d, c) in extra {
            combined[d, default: 0] += c
        }
        return combined
    }

    // ───────────────────────── Utilities ─────────────────────────────
    private func calculateEndDaySale() -> Double {
        (Double(totalSales) ?? 0) - (Double(midDaySales) ?? 0)
    }

    private func reset() {
        totalSales  = ""
        midDaySales = ""
        denominations = denominations.mapValues { _ in "" }
        allocatedX  = [:]
        remainingDenominations = [:]
        endDaySale  = 0
        remainingSum = 0
        message     = ""
        showResults = false
        splitMode   = .normal
        dismissKeyboard()
    }

    private func messageColor() -> Color {
        if remainingSum == 100 { return .green }
        if remainingSum > 100  { return .blue  }
        return .red
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}

// ─────────────────────── Preview ───────────────────────
struct SalesContentView_Previews: PreviewProvider {
    static var previews: some View {
        SalesContentView()
    }
}
