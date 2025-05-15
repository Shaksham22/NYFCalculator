//
//  SalesContentView.swift
//  NYF‑Calculator
//
//  A single‑file drop‑in that keeps the exact visual style
//  of your “original” screen (rounded text fields, two main
//  tables), but layers on the Split / Generate / Revert logic
//  from your prototype.
//
//  It expects a `DenominationTableView` you already have that
//  takes two dictionaries plus an optional title.
//

import SwiftUI

struct SalesContentView: View {
    // ───────────────────────────── Inputs ─────────────────────────────
    @State private var totalSales: String = ""
    @State private var midDaySales: String = ""
    @State private var denominations: [Double: String] = [
        100.00: "", 50.00: "", 20.00: "", 10.00: "",
          5.00: "",  2.00: "",  1.00: "",  0.25: "",
          0.10: "",  0.05: ""
    ]

    // ─────────────────────── Computed / Results ───────────────────────
    @State private var allocatedX:            [Double: Int] = [:]  // to bank
    @State private var remainingDenominations:[Double: Int] = [:]  // stays in till
    @State private var endDaySale:            Double        = 0.0
    @State private var remainingSum:          Double        = 0.0     // $ left in till

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
                // ── 1. Sales Info ─────────────────────────────────────
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
                        Text("Mid‑Day Sales")
                        Spacer()
                        TextField("Mid‑Day Sales", text: $midDaySales)
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
                            .frame(width: 150)
                    }
                }

                // ── 2. Denomination Inputs ───────────────────────────
                Section(header: Text("Denominations")) {
                    ForEach(denominations.keys.sorted(by: >), id: \.self) { denom in
                        HStack {
                            Text("\(denom, specifier: "%.2f") $")
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

                // ── 3. Results Section(s) ─────────────────────────────
                if showResults {
                    // 3‑a. Money going to bank
                    DenominationTableView(
                        individualDenominationCounts: allocatedX,
                        bundleDenominationCounts: [:],
                        tableTitle: "Bank Deposit Money"
                    )

                    // 3‑b. Till money (normal or split / generated)
                    switch splitMode {
                    case .normal:
                        // single table
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
                            tableTitle: "Till: First $100"
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
                            tableTitle: "Till – Generated to $100"
                        )
                    }

                    // 3‑c. Action button(s)
                    Group {
                        if splitMode == .normal {
                            if remainingSum > 100 {
                                Button("Split Till Money")  { splitMode = .split100 }
                            } else if remainingSum < 100 {
                                Button("Generate to $100") { splitMode = .generated100 }
                            }
                        } else {
                            Button("Revert") { splitMode = .normal }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }

                // 3‑d. Status message
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

                Button("Reset")     { reset() }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.4))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 8)
        }
        .padding()
        .onAppear { endDaySale = calculateEndDaySale() }
    }

    // ─────────────────────── Core Calculation ────────────────────────
    private func calculate() {
        // 1. end‑of‑day sale
        let total = Double(totalSales) ?? 0
        let mid   = Double(midDaySales) ?? 0
        endDaySale = total - mid

        // 2. copy user‑entered counts into integers
        var avail     = denominations.mapValues { Int($0) ?? 0 }
        var allocated:[Double: Int] = [:]
        var remaining = endDaySale

        // 3. greedy allocate to bank
        for denom in avail.keys.sorted(by: >) {
            while avail[denom]! > 0 && remaining >= denom {
                avail[denom]! -= 1
                allocated[denom, default: 0] += 1
                remaining -= denom
                remaining = (remaining * 100).rounded() / 100
            }
        }

        // 4. store results
        allocatedX            = allocated
        remainingDenominations = avail
        remainingSum          = avail.reduce(0) { $0 + $1.key * Double($1.value) }

        // 5. status message
        if remaining > 0 {
            message = "Not enough denominations to allocate $\(String(format: "%.2f", remaining))."
        } else {
            if remainingSum == 100 {
                message = "Till amount is exactly $100."
            } else if remainingSum > 100 {
                message = "Till amount is more by $\(String(format: "%.2f", remainingSum - 100))."
            } else {
                message = "Till amount is less by $\(String(format: "%.2f", 100 - remainingSum))."
            }
            showResults = true
        }
        splitMode = .normal
        dismissKeyboard()
    }

    // ───────────────────── Split / Generate Helpers ──────────────────
    private func computeSplitDistributions()
        -> (first100: [Double:Int], remainder: [Double:Int])
    {
        var copy = remainingDenominations
        var first100:[Double:Int] = [:]
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
        let denomList = [100.00, 50.00, 20.00, 10.00, 5.00,
                          2.00,  1.00,  0.25,  0.10,  0.05]
        var extra:[Double:Int] = [:]
        var left = missing

        for d in denomList {
            let count = Int(left / d)
            if count > 0 {
                extra[d] = count
                left -= Double(count) * d
                left = (left * 100).rounded() / 100
            }
        }
        // merge extras with what’s already in the till
        var combined = remainingDenominations
        for (d, c) in extra { combined[d, default: 0] += c }
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
