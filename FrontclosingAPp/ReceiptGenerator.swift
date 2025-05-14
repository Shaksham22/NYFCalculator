import Foundation
import UIKit
import SwiftUI
import StarIO10

struct ReceiptGenerator {
  static func generateReceiptImage(
    employeeName: String,
    currentDate: String,
    tableTitle: String?,
    individualDenominationCounts: [Double: Int],
    bundleDenominationCounts: [Double: Int],
    width: CGFloat = 406
  ) -> UIImage {

    let margin: CGFloat = 10

    // 1. Base font sizes
    let baseBodySize: CGFloat  = 35
    let baseTitleSize: CGFloat = 42

    // 2. Figure out how many lines we’ll draw
    let sortedDenoms = Array(Set(individualDenominationCounts.keys)
                              .union(bundleDenominationCounts.keys))
                          .sorted(by: >)
    var lineCount = 0
    for d in sortedDenoms {
      if individualDenominationCounts[d, default: 0] > 0 { lineCount += 1 }
      if bundleDenominationCounts[d, default: 0]   > 0 { lineCount += 1 }
    }

    // 3. Preliminary fonts (we’ll adjust bodyFont if it overflows)
    var bodyFont  = UIFont.monospacedDigitSystemFont(ofSize: baseBodySize,  weight: .regular)
    let titleFont = UIFont.boldSystemFont(ofSize: baseTitleSize)
    var lineHeight = bodyFont.lineHeight

    // 4. Compute heights
    let titleHeight: CGFloat      = (tableTitle?.isEmpty == false)
                                   ? titleFont.lineHeight + 8
                                   : 0
    let separatorHeight: CGFloat  = lineHeight + 4
    let footerHeight: CGFloat     = lineHeight * 2 + 10
    // let extraPadding: CGFloat  = 30  // any extra bottom padding you had
    let extraPadding: CGFloat     = 30

    // 5. What’s our max content area?
    //    (total image height is unconstrained, but we want to limit body text to this area)
    let maxContentArea = CGFloat(1000) // pick some max, or base on paper length

    // 6. If we’d overflow, scale the bodyFont down
    let neededContentHeight = CGFloat(lineCount) * lineHeight
    if neededContentHeight > maxContentArea {
      let scale = maxContentArea / neededContentHeight
      let newSize = baseBodySize * scale
      bodyFont   = UIFont.monospacedDigitSystemFont(ofSize: newSize, weight: .regular)
      lineHeight = bodyFont.lineHeight
    }

    // 7. Now recompute heights with final lineHeight
    let contentHeight = CGFloat(lineCount) * lineHeight
    let totalHeight   = titleHeight + contentHeight + separatorHeight + lineHeight + footerHeight + extraPadding
      let canvasSize = CGSize(width: width, height: totalHeight)

      // 8. Set up high-res renderer
      let format = UIGraphicsImageRendererFormat()
      format.scale = UIScreen.main.scale
      let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)

      return renderer.image { ctx in
          // fill background with the same canvasSize
          ctx.cgContext.setFillColor(UIColor.white.cgColor)
          ctx.cgContext.fill(CGRect(origin: .zero, size: canvasSize))

      // attributes
      let bodyAttrs  = [ NSAttributedString.Key.font: bodyFont,  .foregroundColor: UIColor.black ]
      let titleAttrs = [ NSAttributedString.Key.font: titleFont, .foregroundColor: UIColor.black ]

      // draw helper with margin-aware centering
      func draw(_ text: String, at y: CGFloat, centered: Bool = false, attrs: [NSAttributedString.Key:Any]) {
        let textWidth = NSString(string: text).size(withAttributes: attrs).width
        let x: CGFloat
        if centered {
          let usableWidth = width - 2*margin
          x = margin + (usableWidth - textWidth)/2
        } else {
          x = margin
        }
        NSString(string: text).draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
      }

      var y = margin
      // title
      if let title = tableTitle, !title.isEmpty {
        draw(title, at: y, centered: true, attrs: titleAttrs)
        y += titleFont.lineHeight + 8
      }

      // lines
          func bundleMultiplier(_ d: Double) -> Double {
              switch d {
              case 1.00: return 25
              case 0.25: return 10
              case 0.10: return 5
              case 0.05: return 2
              default:   return 0
              }
          }
          for d in sortedDenoms {
              // 1) “Normal” denominations
              if let cnt = individualDenominationCounts[d], cnt > 0 {
                  let amount = d * Double(cnt)
                  let line = String(format: "$%.2f x %d = $%.2f", d, cnt, amount)
                  draw(line, at: y, attrs: bodyAttrs)
                  y += lineHeight
              }

              // 2) Bundles next
              if let bcnt = bundleDenominationCounts[d], bcnt > 0 {
                  let bundleSize = bundleMultiplier(d)    // e.g. 25, 10, 5, 2
                  let amount     = bundleSize * Double(bcnt)
                  // note: no “bdl”, count in ()
                  let line = String(format: "%.2f x (%d) = %.2f", d, bcnt, amount)
                  draw(line, at: y, attrs: bodyAttrs)
                  y += lineHeight
              }
          }

      // separator
      y += 4
      let dashCount = Int((width - 2*margin)/(bodyFont.pointSize * 0.6))
      draw(String(repeating: "-", count: dashCount), at: y, attrs: bodyAttrs)
      y += lineHeight + 4

      // total
      let totalAmt = sortedDenoms.reduce(0) { s,d in
        s + d*Double(individualDenominationCounts[d,default:0])
          + bundleMultiplier(d)*Double(bundleDenominationCounts[d,default:0])
      }
      draw(String(format: "Total     = $%6.2f", totalAmt), at: y, attrs: bodyAttrs)

      // footer
      y += lineHeight + 10
      draw("Employee: \(employeeName)", at: y, attrs: bodyAttrs)
      draw("Date:     \(currentDate)", at: y + lineHeight, attrs: bodyAttrs)
    }
  }
}
