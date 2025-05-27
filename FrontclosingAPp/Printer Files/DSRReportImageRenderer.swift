//
//  DSRReportImageRenderer.swift
//
//  Generates a UIImage (width = 576 pt) from your SwiftUI DSRReportView.
//  Nothing else—no printing side-effects.
//

import SwiftUI
import UIKit

struct DSRReportImageRenderer {

    /// Convert a `DSRMetrics` model into a bitmap ready for Star-TSP100 printing.
    /// - Parameter metrics:   Your filled-in DSRMetrics struct
    /// - Parameter width:     Desired pixel width (Star default = 576)
    /// - Returns:             A `UIImage` whose height is whatever the view needs
    static func makeImage(from metrics: DSRMetrics,
                          width: CGFloat = 576) -> UIImage {

        // 1. Build the SwiftUI report view
        let reportView = DSRReportView(m: metrics)

        // 2. Put it in an off-screen hosting controller
        let host = UIHostingController(rootView: reportView)
        host.view.backgroundColor = .white

        // 3. Ask Auto-Layout for the natural height at the fixed width
        let targetSize = CGSize(width: width,
                                height: UIView.layoutFittingCompressedSize.height)

        let height = host.view.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        host.view.bounds = CGRect(x: 0, y: 0, width: width, height: height)
        host.view.layoutIfNeeded()

        // 4. Render that hierarchy into a bitmap
        let renderer = UIGraphicsImageRenderer(size: host.view.bounds.size)
        return renderer.image { _ in
            host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
        }
    }
}
