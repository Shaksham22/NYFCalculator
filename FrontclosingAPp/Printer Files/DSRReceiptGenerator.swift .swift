//
//  DSRReceiptGenerator.swift
//
//  Created by Shubham on 2025-05-27
//

import UIKit

struct DSRReceiptGenerator {

    // ─────────────────────────────────────────────
    // MARK: – Public entry point
    // ─────────────────────────────────────────────
    /// Create a bitmap ready for Star-TSP100 printing.
    ///
    /// `dict` must contain the same keys you used in `DSRMetrics.asDict`
    /// (e.g. "netSales", "gstHst", "totalB", …).  Missing keys are ignored.
    static func makeImage(from dict: [String: Double]) -> UIImage {
        let lines = receiptLines(from: dict)

        // Printer constants
        let maxWidth:  CGFloat = 576      // 80-mm Star default
        let sidePad:   CGFloat = 14
        let interLine: CGFloat = 6

        // Pick a font size that lets the longest line fit
        var fontSize: CGFloat = 28
        let longest = lines.max(by: { $0.count < $1.count }) ?? ""
        while fontSize > 10 {
            let width = (longest as NSString).size(
                withAttributes: [.font: UIFont.monospacedSystemFont(ofSize: fontSize,
                                                                    weight: .regular)]
            ).width
            if width + sidePad * 2 <= maxWidth { break }
            fontSize -= 1
        }

        let font   = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        let lineH  = font.lineHeight + interLine
        let totalH = lineH * CGFloat(lines.count) + 20

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: maxWidth, height: totalH))
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(ctx.format.bounds)

            for (i, line) in lines.enumerated() {
                let y = 10 + CGFloat(i) * lineH
                (line as NSString).draw(
                    at: CGPoint(x: sidePad, y: y),
                    withAttributes: [.font: font, .foregroundColor: UIColor.black]
                )
            }
        }
    }

    // ─────────────────────────────────────────────
    // MARK: – Receipt-text helpers
    // ─────────────────────────────────────────────
    /// 8-char money cell – right aligned (`$ 123.45`) or blanks if absent
    private static func money(_ v: Double?) -> String {
        guard let v, abs(v) > 0.0001 else { return "        " } // 8 spaces
        let s   = String(format: "%.2f", v)
        let pad = max(0, 7 - s.count)                           // one char is “$”
        return "$" + String(repeating: " ", count: pad) + s
    }

    private static func row(_ label: String, _ value: Double?, bold: Bool = false) -> String {
        let lbl = label.padding(toLength: 30, withPad: " ", startingAt: 0)
        let val = money(value)
        return bold ? lbl.uppercased() + val : lbl + val
    }

    /// Produce all receipt lines from the flat dictionary
    private static func receiptLines(from d: [String: Double]) -> [String] {

        // Convenience accessor (returns nil if key missing)
        func v(_ key: String) -> Double? { d[key] }

        var out: [String] = []
        out.append("----------- DAILY SALES REPORT -----------")
        out.append("")

        // Section A
        out.append(row("NET SALES",                v("netSales")))
        out.append(row("FRY SOCIETY LOADS",        v("fryLoads")))
        out.append(row("GST & HST",                v("gstHst")))
        out.append(row("MANITOBA PST",             v("manitobaPst")))
        out.append(row("TOTAL A",                  v("totalA"), bold: true))
        out.append("")

        // Section B
        out.append(row("CASH FLOAT INCREASE (DECREASE)", v("cashFloatDelta")))
        out.append(row("AGGREGATORS",              v("aggregators")))
        out.append(row("PAYOUTS, GST/HST NOT INCLUDED", v("payouts")))
        out.append(row("GST/HST ON PAYOUTS",       v("gstOnPayouts")))
        out.append(row("VISA",                     v("visa")))
        out.append(row("MASTERCARD",               v("mastercard")))
        out.append(row("AMERICAN EXPRESS",         v("amex")))
        out.append(row("DEBIT CARD",               v("debit")))
        out.append(row("BANK DEPOSIT",             v("bankDeposit")))
        out.append(row("FRY SOCIETY PAYMENTS",     v("fryPayments")))
        out.append(row("NON-CASH COUPONS/REWARDS", v("nonCash")))
        out.append(row("GIVEX $ +/-",              v("givex")))
        out.append(row("TOTAL B",                  v("totalB"), bold: true))
        out.append("")

        // Difference
        out.append(row("CASH DIFFERENCE",          v("cashDifference"), bold: true))
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
