import SwiftUI
import AVFoundation

/// A SwiftUI wrapper that shows a live AVCaptureSession feed.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession      // ← supply this from your CameraManager
    
    // MARK: UIViewRepresentable
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session       = session
        view.videoPreviewLayer.videoGravity  = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Keep orientation correct when device rotates
        if let connection = uiView.videoPreviewLayer.connection,
           connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait   // tweak if you support landscape
        }
    }
}

/// UIView whose underlying layer *is* AVCaptureVideoPreviewLayer.
final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        // Guaranteed safe because of layerClass override
        return layer as! AVCaptureVideoPreviewLayer
    }
}
