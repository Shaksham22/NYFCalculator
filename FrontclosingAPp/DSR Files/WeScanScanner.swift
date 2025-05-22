import SwiftUI
import WeScan

/// Presents WeScan’s ImageScannerController either with
/// live-camera or an existing UIImage.
struct WeScanScanner: UIViewControllerRepresentable {
    enum Source {
        case camera            // live rectangle detection
        case image(UIImage)    // gallery pick
    }
    var source: Source
    var onFinished: (UIImage) -> Void
    @Environment(\.presentationMode) private var presentation

    func makeCoordinator() -> Coord { Coord(self) }

    func makeUIViewController(context: Context) -> UIViewController {
        let scanner: ImageScannerController
        switch source {
        case .camera:
            scanner = ImageScannerController()              // live
        case .image(let img):
            scanner = ImageScannerController(image: img)    // gallery
        }
        scanner.modalPresentationStyle = .overFullScreen        // ← NEW
        scanner.imageScannerDelegate = context.coordinator
        scanner.modalPresentationCapturesStatusBarAppearance = true

        return scanner    }
    func updateUIViewController(_: UIViewController, context: Context) {}

    final class Coord: NSObject, ImageScannerControllerDelegate {
        let parent: WeScanScanner
        init(_ parent: WeScanScanner) { self.parent = parent }

        func imageScannerController(_ scanner: ImageScannerController,
                                    didFailWithError error: Error) {
            print("WeScan error:", error)
            parent.presentation.wrappedValue.dismiss()
        }
        func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
            parent.presentation.wrappedValue.dismiss()
        }
        func imageScannerController(_ scanner: ImageScannerController,
                                    didFinishScanningWithResults results: ImageScannerResults) {

            let final: UIImage
            if results.doesUserPreferEnhancedScan,
               let enhanced = results.enhancedScan?.image {
                final = enhanced
            } else {
                final = results.croppedScan.image      // perspective-corrected
            }

            parent.onFinished(final)
            parent.presentation.wrappedValue.dismiss()
        }

    }
}
