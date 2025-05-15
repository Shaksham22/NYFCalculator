import Foundation
import UIKit
import SwiftUI
import StarIO10
struct ReceiptGenerator {
  /// Renders a receipt‐style breakdown of denominations into a UIImage,
  /// with a centered, larger title at top and a footer showing employee & date.
  static func generateReceiptImage(
    employeeName: String,
    currentDate: String,
    tableTitle: String?,
    individualDenominationCounts: [Double: Int],
    bundleDenominationCounts: [Double: Int],
    width: CGFloat = 900               // adjust to fit your UI
  ) -> UIImage {
    // 1) Data setup
    let denominations = ["100.00","50.00","20.00","10.00","5.00","2.00","1.00","0.25","0.10","0.05"]
    let bundleDenoms  = ["1.00","0.25","0.10","0.05"]
    let bundleValues: [Double: Double] = [1.00:25, 0.25:10, 0.10:5, 0.05:2]

    // 2) Build the “body” lines (denominations + total)
    var receiptLines = [String]()
    let space = " "
    var totalValue: Double = 0

    // 2a) Compute column widths
    let m   = max(
      denominations.map { $0.count }.max() ?? 0,
      bundleDenoms .map { $0.count }.max() ?? 0
    )
    let mct = max(
      individualDenominationCounts.values.map { String($0).count }.max() ?? 0,
      bundleDenominationCounts.values .map { String($0).count }.max() ?? 0
    )

      for s in denominations {
        guard let denom = Double(s) else { continue }
        let key: Double = denom >= 1 ? Double(Int(denom)) : denom
        guard let count = individualDenominationCounts[key], count > 0 else { continue }
        let lineTotal = denom * Double(count)
        totalValue += lineTotal

        let totalStr = String(format: "%.2f", lineTotal)
        let countStr = String(count)

        let line =
          " $" + s +
          String(repeating: space, count: m - s.count + 2) +
          "x" +
          String(repeating: space, count: 3) +
          countStr + space +
          String(repeating: space, count: 2 + mct - countStr.count) +
          "=" +
          String(repeating: space, count: 2) +
          "$" + totalStr

        receiptLines.append(line)
      }


      for s in bundleDenoms {
        guard let denom = Double(s),
              let multiplier = bundleValues[denom] else { continue }
        let key: Double = denom >= 1 ? Double(Int(denom)) : denom
        guard let count = bundleDenominationCounts[key], count > 0 else { continue }
        let lineTotal = Double(count) * multiplier
        totalValue += lineTotal

        let totalStr = String(format: "%.2f", lineTotal)
        let countStr = String(count)
          
        let line =
          " $" + s +
          String(repeating: space, count: m - s.count + 2) +
          "x" +
          String(repeating: space, count: 2) +
          "(" + countStr + ")" +
          String(repeating: space, count: 2 + mct - countStr.count) +
          "=" +
          String(repeating: space, count: 2) +
          "$" + totalStr

        receiptLines.append(line)
      }


    // 2d) Divider + total
    let longestLine = receiptLines.max(by: { $0.count < $1.count }) ?? ""
    let prefixLen   = longestLine.split(separator: "=")[0].count
    let totalStr    = String(format: "%.2f", totalValue)

    receiptLines.append(String(repeating: "-", count: longestLine.count + 2))
    let totalLine =
      " Total" +
      String(repeating: space, count: prefixLen - 6) +
      "=" +
      String(repeating: space, count: 2) +
      "$" + totalStr
    receiptLines.append(totalLine)
      receiptLines.append(String(repeating: "-", count: longestLine.count + 2))
      receiptLines.insert(String(repeating: "-", count: longestLine.count + 2), at: 0)
    // 2e) Add 2–3 blank lines, then footer
    receiptLines.append("")
    receiptLines.append("")
    receiptLines.append("Employee: \(employeeName)")
    receiptLines.append("Date: \(currentDate)")

    // 3) Fit-to-width logic for body + footer
    let margin: CGFloat = 10
    let maxTextWidth = width - margin * 2

    var fontSize: CGFloat = 30
    var bodyFont = UIFont(name: "Courier", size: fontSize)!
    var attrs: [NSAttributedString.Key: Any] = [
      .font: bodyFont,
      .kern: 0
    ]

    while true {
      let widest = receiptLines
        .map { NSString(string: $0).size(withAttributes: attrs).width }
        .max() ?? 0
      if widest <= maxTextWidth || fontSize <= 8 {
        break
      }
      fontSize -= 1
      bodyFont = UIFont(name: "Courier", size: fontSize)!
      attrs[.font] = bodyFont
    }

    let lineHeight = bodyFont.lineHeight

    // 4) Title attributes
    let titleFont = UIFont(name: "Courier-Bold", size: fontSize + 4)!
    let titlePara = NSMutableParagraphStyle()
    titlePara.alignment = .center
    let titleAttrs: [NSAttributedString.Key: Any] = [
      .font: titleFont,
      .paragraphStyle: titlePara,
      .foregroundColor: UIColor.black
    ]
    let titleHeight = titleFont.lineHeight

    // 5) Compute canvas size
    let totalHeight = margin
                     + (tableTitle != nil ? titleHeight + 4 : 0)
                     + (tableTitle != nil ? titleHeight : 0)
                     + 4   // extra spacing after title
                     + lineHeight * CGFloat(receiptLines.count)
                     + margin
    let size = CGSize(width: width, height: totalHeight)

    // 6) Render
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { ctx in
      // white background
      ctx.cgContext.setFillColor(UIColor.white.cgColor)
      ctx.cgContext.fill(CGRect(origin: .zero, size: size))

      var y = margin

      // 6a) Draw title (if any)
      if let title = tableTitle {
        let rect = CGRect(x: margin,
                          y: y,
                          width: width - margin*2,
                          height: titleHeight)
        NSString(string: title)
          .draw(in: rect, withAttributes: titleAttrs)
          y += titleHeight + lineHeight  // space after title
      }

      // 6b) Draw body & footer lines
      // reuse attrs, adding paragraph style for left alignment
      let bodyPara = NSMutableParagraphStyle()
      bodyPara.alignment = .left
      attrs[.paragraphStyle] = bodyPara
      attrs[.foregroundColor] = UIColor.black

      for line in receiptLines {
        let rect = CGRect(x: margin,
                          y: y,
                          width: width - margin*2,
                          height: lineHeight)
        NSString(string: line)
          .draw(in: rect, withAttributes: attrs)
        y += lineHeight
      }
    }
  }
}
