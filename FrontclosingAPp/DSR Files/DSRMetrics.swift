//
//  DSRMetrics.swift
//
//  Created by Shubham on 2025‑05‑xx
//

import Foundation
import UIKit

// ────────────────────────────────────────────────────────────
// MARK: - Data model
// ────────────────────────────────────────────────────────────
struct DSRMetrics {

    // ── Section A
    var netSales:        Double?
    var fryLoads:        Double?
    var gstHst:          Double?
    var manitobaPst:     Double?
    var totalA:          Double?

    // ── Section B
    var cashFloatDelta:  Double?
    var aggregators:     Double?
    var payouts:         Double?
    var gstOnPayouts:    Double?
    var visa:            Double?
    var mastercard:      Double?
    var amex:            Double?
    var debit:           Double?
    var bankDeposit:     Double?
    var fryPayments:     Double?
    var nonCash:         Double?
    var givex:           Double?
    var totalB:          Double?

    // ── Final
    var cashDifference:  Double?
}

// ────────────────────────────────────────────────────────────
// MARK: - Parser  (Vision / OCR dictionary ➜ DSRMetrics)
// ────────────────────────────────────────────────────────────
extension DSRMetrics {

    /// Build a `DSRMetrics` from the dictionary your OCR pipeline spits out.
    ///
    /// Adjust the **section / key** strings so they match your real JSON.
    static func from(parsed dict: [String: [String: Double]]) -> DSRMetrics? {

        // Helper that keeps nil if the key is missing
        func get(_ section: String, _ key: String) -> Double? {
            dict[section]?[key]
        }

        // Add two optionals, but preserve nil if both are nil
        func add(_ a: Double?, _ b: Double?) -> Double? {
            switch (a, b) {
            case (nil, nil): return nil
            default:         return (a ?? 0) + (b ?? 0)
            }
        }

        // ── Mandatory (fail early if absent)
        guard
            let net   = dict["end"]?["net"],                // TODO key
            let taxes = dict["end"]?["total taxes"]         // TODO key
        else { return nil }

        // ── Optional
        let fryLoads    = dict["end"]?["fry society loads"] // TODO key
        let mbPst       = dict["end"]?["manitoba pst"]      // TODO key

        let cashFloat   = dict["cash"]?["float delta"]      // TODO key
        let aggregators = dict["delivery"]?["sales"]        // TODO key
        let payouts     = dict["cash"]?["payouts"]          // TODO key
        let gstPayout   = dict["cash"]?["gst on payouts"]   // TODO key

        let visa        = add(get("eat in","visa"),        get("take out","visa"))
        let mastercard  = add(get("eat in","mastercard"),  get("take out","mastercard"))
        let amex        = add(get("eat in","amex"),        get("take out","amex"))
        let debit       = add(get("eat in","debit"),       get("take out","debit"))
        let bankDep     = add(get("eat in","cash"),        get("take out","cash"))

        let fryPay      = dict["cash"]?["fry society payments"] // TODO key
        let nonCash     = dict["cash"]?["non cash coupons"]     // TODO key
        let givex       = add(get("eat in","givex"),       get("take out","givex"))

        // ── Totals
        let totalA = [net, fryLoads, taxes, mbPst]
                      .compactMap { $0 }.reduce(0, +)

        let totalB = [
            cashFloat, aggregators, payouts, gstPayout,
            visa, mastercard, amex, debit, bankDep,
            fryPay, nonCash, givex
        ].compactMap { $0 }.reduce(0, +)

        return DSRMetrics(
            netSales:        net,
            fryLoads:        fryLoads,
            gstHst:          taxes,
            manitobaPst:     mbPst,
            totalA:          totalA,

            cashFloatDelta:  cashFloat,
            aggregators:     aggregators,
            payouts:         payouts,
            gstOnPayouts:    gstPayout,
            visa:            visa,
            mastercard:      mastercard,
            amex:            amex,
            debit:           debit,
            bankDeposit:     bankDep,
            fryPayments:     fryPay,
            nonCash:         nonCash,
            givex:           givex,
            totalB:          totalB,

            cashDifference:  totalB - totalA
        )
    }
}

// ────────────────────────────────────────────────────────────
// MARK: - Receipt renderer (metrics ➜ UIImage)
// ────────────────────────────────────────────────────────────
extension DSRMetrics {

    /// Create a bitmap ready for Star‑TSP100 printing
    static func makeReceiptImage(from m: DSRMetrics) -> UIImage {

        let lines = m.receiptLines()

        // Printer constants
        let maxWidth:  CGFloat = 576    // 80‑mm Star default
        let sidePad:   CGFloat = 14
        let interLine: CGFloat = 6

        // Choose font size so the longest line fits
        var fontSize: CGFloat = 28
        let longest = lines.max(by: { $0.count < $1.count }) ?? ""
        while fontSize > 10 {
            let width = (longest as NSString).size(
                withAttributes: [.font: UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)]
            ).width
            if width + sidePad * 2 <= maxWidth { break }
            fontSize -= 1
        }
        let font      = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        let lineH     = font.lineHeight + interLine
        let totalH    = lineH * CGFloat(lines.count) + 20

        let renderer  = UIGraphicsImageRenderer(
            size: CGSize(width: maxWidth, height: totalH)
        )
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: ctx.format.bounds.size))

            for (i, line) in lines.enumerated() {
                let y = 10 + CGFloat(i) * lineH
                (line as NSString).draw(
                    at: CGPoint(x: sidePad, y: y),
                    withAttributes: [.font: font, .foregroundColor: UIColor.black]
                )
            }
        }
    }
}

// ────────────────────────────────────────────────────────────
// MARK: - Receipt text builder
// ────────────────────────────────────────────────────────────
extension DSRMetrics {

    /// 8‑char money cell: `$ 123.45` right‑aligned, or eight blanks if nil/zero
    private func money(_ v: Double?) -> String {
        guard let v, abs(v) > 0.0001 else { return "        " }   // 8 spaces
        let s   = String(format: "%.2f", v)
        let pad = max(0, 7 - s.count)                             // one char is "$"
        return "$" + String(repeating: " ", count: pad) + s
    }

    /// Convenience to keep rows tidy
    private func row(_ label: String, _ value: Double?, bold: Bool = false) -> String {
        let lbl = label.padding(toLength: 30, withPad: " ", startingAt: 0)
        let val = money(value)
        return bold ? lbl.uppercased() + val : lbl + val
    }

    /// All lines in printing order
    func receiptLines() -> [String] {
        var out: [String] = []

        out.append("----------- DAILY SALES REPORT -----------")
        out.append("")

        // Section A
        out.append(row("NET SALES",                netSales))
        out.append(row("FRY SOCIETY LOADS",        fryLoads))
        out.append(row("GST & HST",                gstHst))
        out.append(row("MANITOBA PST",             manitobaPst))
        out.append(row("TOTAL A",                  totalA, bold: true))
        out.append("")

        // Section B
        out.append(row("CASH FLOAT INCREASE (DECREASE)", cashFloatDelta))
        out.append(row("AGGREGATORS",              aggregators))
        out.append(row("PAYOUTS, GST/HST NOT INCLUDED", payouts))
        out.append(row("GST/HST ON PAYOUTS",       gstOnPayouts))
        out.append(row("VISA",                     visa))
        out.append(row("MASTERCARD",               mastercard))
        out.append(row("AMERICAN EXPRESS",         amex))
        out.append(row("DEBIT CARD",               debit))
        out.append(row("BANK DEPOSIT",             bankDeposit))
        out.append(row("FRY SOCIETY PAYMENTS",     fryPayments))
        out.append(row("NON‑CASH COUPONS/REWARDS", nonCash))
        out.append(row("GIVEX $ +/-",              givex))
        out.append(row("TOTAL B",                  totalB, bold: true))
        out.append("")

        // Difference
        out.append(row("CASH DIFFERENCE",          cashDifference, bold: true))
        out.append("------------------------------------------")
        out.append("")

        // Footer
        let date = DateFormatter.localizedString(from: Date(),
                                                 dateStyle: .medium,
                                                 timeStyle: .none)
        out.append("Printed: \(date)")
        return out
    }
}
