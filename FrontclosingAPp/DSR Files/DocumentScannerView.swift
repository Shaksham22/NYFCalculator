import VisionKit
import SwiftUI

struct DocumentScannerView: UIViewControllerRepresentable {
    var onFinished: (UIImage) -> Void        // deskewed result
    @Environment(\.presentationMode) private var presentation

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }
    func updateUIViewController(_ vc: VNDocumentCameraViewController, context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView
        init(_ p: DocumentScannerView) { parent = p }

        func documentCameraViewController(_ vc: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount > 0 else { parent.presentation.wrappedValue.dismiss(); return }
            let img = scan.imageOfPage(at: 0)     // already cropped & deskewed
            parent.onFinished(img)
            parent.presentation.wrappedValue.dismiss()
        }
        func documentCameraViewControllerDidCancel(_ vc: VNDocumentCameraViewController) {
            parent.presentation.wrappedValue.dismiss()
        }
        func documentCameraViewController(_ vc: VNDocumentCameraViewController,
                                          didFailWithError error: Error) {
            print("Scan failed:", error)
            parent.presentation.wrappedValue.dismiss()
        }
    }
}
