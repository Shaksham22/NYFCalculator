//
//  ReceiptGenerator.swift
//

import Foundation
import UIKit
import SwiftUI

struct ReceiptGenerator {

  static func generateReceiptImage(
    employeeName: String,
    currentDate:  String,
    tableTitle:   String?,
    individualDenominationCounts: [Double: Int],
    bundleDenominationCounts:      [Double: Int],
    width: CGFloat = 576,

    isEndDay: Bool = false,
    salesSummary: (total: Double,
                   midDay: Double,
                   endDay: Double)? = nil
  ) -> UIImage {

    // ───────────────────────── 0. Constants ─────────────────────────
    let space = " "                                    // ← FIX: declare early
    let denominations = ["100.00","50.00","20.00","10.00","5.00","2.00",
                         "1.00","0.25","0.10","0.05"]
    let bundleDenoms  = ["1.00","0.25","0.10","0.05"]
    let bundleValues: [Double: Double] =
        [1.00:25, 0.25:10, 0.10:5, 0.05:2]
  var receiptLines: [String] = []
  var totalValue = 0.0

  let m = max(denominations.map { $0.count }.max() ?? 0,
              bundleDenoms .map { $0.count }.max() ?? 0)
  let mct = max(individualDenominationCounts.values.map { String($0).count }.max() ?? 0,
                bundleDenominationCounts.values .map { String($0).count }.max() ?? 0)

    // ───────────────────── 1. Denomination section ──────────────────



    for s in denominations {
      guard
        let denom = Double(s),
        let count = individualDenominationCounts[denom >= 1 ? Double(Int(denom)) : denom],
        count > 0
      else { continue }

      let lineTotal = denom * Double(count)
      totalValue   += lineTotal

      receiptLines.append(
        " $" + s +
        String(repeating: space, count: m - s.count + 2) +
        "x"  + String(repeating: space, count: 3) +
        String(count) +
        space +
        String(repeating: space, count: 2 + mct - String(count).count) +
        "=" + String(repeating: space, count: 2) +
        "$" + String(format: "%.2f", lineTotal)
      )
    }
      

    for s in bundleDenoms {
      guard
        let denom = Double(s),
        let multiplier = bundleValues[denom],
        let count = bundleDenominationCounts[denom >= 1 ? Double(Int(denom)) : denom],
        count > 0
      else { continue }

      let lineTotal = Double(count) * multiplier
      totalValue   += lineTotal

      receiptLines.append(
        " $" + s +
        String(repeating: space, count: m - s.count + 2) +
        "x" + String(repeating: space, count: 2) +
        "(" + String(count) + ")" +
        String(repeating: space, count: 2 + mct - String(count).count) +
        "=" + String(repeating: space, count: 2) +
        "$" + String(format: "%.2f", lineTotal)
      )
    }

    // divider + grand total
    let longestDenomLine = receiptLines.max(by: { $0.count < $1.count }) ?? ""
    let prefixLen        = longestDenomLine.split(separator: "=")[0].count
      let heading = "Cash Summary"
      let totalWidth = longestDenomLine.count + 2
      let pad = max(0, (totalWidth - heading.count) / 2)

      receiptLines.insert(
        String(repeating: space, count: pad) + heading +
        String(repeating: space, count: totalWidth - pad - heading.count),
        at: 0
      )
      receiptLines.insert(String(repeating: "-", count: totalWidth), at: 1)
    receiptLines.insert(String(repeating: "-", count: longestDenomLine.count + 2), at: 0)
    receiptLines.append(String(repeating: "-", count: longestDenomLine.count + 2))
    receiptLines.append(
      " Total" +
      String(repeating: space, count: prefixLen - 6) +
      "=" + String(repeating: space, count: 2) +
      "$" + String(format: "%.2f", totalValue)
    )
    receiptLines.append(String(repeating: "-", count: longestDenomLine.count + 2))
      receiptLines.insert("", at: 0)
      receiptLines.insert("", at: 0)
    // footer
    receiptLines.append(contentsOf: ["", "",
                                     "Employee: \(employeeName)",
                                     "Date: \(currentDate)"])
      
      
      let fullLineWidth    = longestDenomLine.count                            // width for dashes

      // ───────────────────── 2. End-Day sales summary ─────────────────────────────
      var summaryLines: [String] = []
      if isEndDay, let s = salesSummary {

          // 1-a. rows & fixed settings
          let rows: [(String, Double)] = [
              ("Total Sale", s.total),
              ("Mid Day",    s.midDay),
              ("End Day",    s.endDay)
          ]
          let gap = 2                       // spaces after '=' before the number

          summaryLines.append("")
          summaryLines.append("")   // blank line before the block
            let heading = "Sales Details"
            let totalWidth = longestDenomLine.count + 2
            let pad = max(0, (totalWidth - heading.count) / 2)
          summaryLines.append(String(repeating: "-", count: longestDenomLine.count + 2))
          summaryLines.append(
              String(repeating: space, count: pad) + heading +
              String(repeating: space, count: totalWidth - pad - heading.count)
            )
          summaryLines.append(String(repeating: "-", count: longestDenomLine.count + 2))
          // 1-b. build each row
          for (idx, row) in rows.enumerated() {

              // dashed rule before “End Day”
              if idx == 2 {
                  summaryLines.append(String(repeating: "-", count: fullLineWidth + 2))
              }

              let value   = String(format: "%.2f", row.1)
              let leftPad = max(0, prefixLen - (row.0.count + 1))// never negative

              summaryLines.append(
                  " " + row.0 +                              // leading space + label
                  String(repeating: space, count: leftPad) + // pad to '=' column
                  "=" +
                  String(repeating: space, count: gap) +
                 "$" +
                  value
              )
          }
          summaryLines.append(String(repeating: "-", count: longestDenomLine.count + 2))
          summaryLines.append("")
// blank line after the block
      }



    // ───────────────────── 3. Combine & size logic ──────────────────
    let bodyLines = summaryLines + receiptLines          // ← FIX: actually include summary
    let margin: CGFloat = 10
    let maxTextWidth = width - margin * 2

    var fontSize: CGFloat = 30
    var bodyFont = UIFont(name: "Courier", size: fontSize)!
    var attrs: [NSAttributedString.Key: Any] = [.font: bodyFont]

    while true {
      let widest = bodyLines.map {
        NSString(string: $0).size(withAttributes: attrs).width
      }.max() ?? 0
      if widest <= maxTextWidth || fontSize <= 8 { break }
      fontSize -= 1
      bodyFont  = UIFont(name: "Courier", size: fontSize)!
      attrs[.font] = bodyFont
    }

    let lineHeight = bodyFont.lineHeight

    // Title styling
    let titleFont = UIFont(name: "Courier-Bold", size: fontSize + 4)!
    let titlePara = NSMutableParagraphStyle(); titlePara.alignment = .center
    let titleAttrs: [NSAttributedString.Key: Any] =
        [.font: titleFont, .paragraphStyle: titlePara]

    // Canvas height  (titleHeight + 4 spacing ONCE)
      let verticalTitleOffset: CGFloat = 40  // top spacing before the title
      let titleHeight = (tableTitle != nil) ? titleFont.lineHeight : 0

      let totalHeight =
            margin +
            verticalTitleOffset +              // top gap
            titleHeight +
            (titleHeight > 0 ? 4 : 0) +        // gap after title
            lineHeight * CGFloat(bodyLines.count) +
      verticalTitleOffset +                               // ← bottom gap
            margin

      let size = CGSize(width: width, height: totalHeight)

      // ───────────────────── 4. Render image ──────────────────────────
      let renderer = UIGraphicsImageRenderer(size: size)
      return renderer.image { ctx in
        ctx.cgContext.setFillColor(UIColor.white.cgColor)
        ctx.cgContext.fill(CGRect(origin: .zero, size: size))

        var y = margin

        // title
        if let title = tableTitle {
          y += verticalTitleOffset             // ← spacing before drawing title
          NSString(string: title).draw(
            in: CGRect(x: margin, y: y,
                       width: width - margin * 2, height: titleHeight),
            withAttributes: titleAttrs)
          y += titleHeight + 4                 // gap after title
        }

        // body
        attrs[.paragraphStyle] = {
          let p = NSMutableParagraphStyle(); p.alignment = .left; return p
        }()
        for line in bodyLines {
          NSString(string: line).draw(
            in: CGRect(x: margin, y: y,
                       width: width - margin * 2, height: lineHeight),
            withAttributes: attrs)
          y += lineHeight
        }
      }
  }
}
