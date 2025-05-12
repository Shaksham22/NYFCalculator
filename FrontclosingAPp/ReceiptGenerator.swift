import Foundation
import UIKit
import SwiftUI
import StarIO10

/// Generates a receipt UIImage from denomination data and header info,
/// formatted for a 79.5 mm (or 57.5 mm) paper width without using a canvas.
struct ReceiptGenerator {
    static func generateReceiptImage(
        employeeName: String,
        currentDate: String,
        individualDenominationCounts: [Double: Int],
        bundleDenominationCounts: [Double: Int],
        size: CGSize = CGSize(width: 406, height: 800)
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // 1) Fill white background
            ctx.cgContext.setFillColor(UIColor.white.cgColor)
            ctx.cgContext.fill(CGRect(origin: .zero, size: size))

            // 2) Prepare monospaced font & attributes
            let font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .regular)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black
            ]
            let lineHeight = font.lineHeight

            // 3) Helper to draw text
            func draw(_ text: String, at y: CGFloat) {
                NSString(string: text).draw(at: CGPoint(x: 10, y: y), withAttributes: attrs)
            }

            // 4) Compute sorted denominations and bundle multiplier
            let sorted = Array(Set(individualDenominationCounts.keys)
                .union(bundleDenominationCounts.keys))
                .sorted(by: >)
            func bundleMultiplier(_ d: Double) -> Double {
                switch d {
                case 1.00: return 25
                case 0.25: return 10
                case 0.10: return 5
                case 0.05: return 2
                default:   return 0
                }
            }

            // 5) Draw each denomination line
            var y: CGFloat = 10
            for denom in sorted {
                if let count = individualDenominationCounts[denom], count > 0 {
                    let line = String(format: "$%6.2f x %3d = $%6.2f",
                                      denom, count, denom * Double(count))
                    draw(line, at: y)
                    y += lineHeight
                }
                if let bundleCount = bundleDenominationCounts[denom], bundleCount > 0 {
                    let total = bundleMultiplier(denom) * Double(bundleCount)
                    let line = String(format: "$%6.2f bdl x %3d = $%6.2f",
                                      denom, bundleCount, total)
                    draw(line, at: y)
                    y += lineHeight
                }
            }

            // 6) Draw separator line
            y += 4
            let dashCount = 20  // adjust for your printer width
            draw(String(repeating: "-", count: dashCount), at: y)
            y += lineHeight + 4

            // 7) Draw total
            let totalAmount = sorted.reduce(0) { sum, denom in
                var s = sum
                if let cnt = individualDenominationCounts[denom] {
                    s += denom * Double(cnt)
                }
                if let bc = bundleDenominationCounts[denom] {
                    s += bundleMultiplier(denom) * Double(bc)
                }
                return s
            }
            let totalText = String(format: "Total     = $%6.2f", totalAmount)
            draw(totalText, at: y)

            // 8) Draw footer (employee & date) at the bottom
            let footerY = size.height - lineHeight * 2 - 10
            draw("Employee: \(employeeName)", at: footerY)
            draw("Date:     \(currentDate)", at: footerY + lineHeight)
        }
    }
}
