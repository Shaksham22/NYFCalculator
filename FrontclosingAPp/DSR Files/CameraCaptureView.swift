import SwiftUI
import AVFoundation
import Vision

/// A UIKit‑backed full‑screen camera that captures one still image
/// and returns it via `onCapture`.
struct CameraCaptureView: UIViewControllerRepresentable {

    typealias Callback = (UIImage) -> Void
    var onCapture: Callback
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: Context) -> CameraVC {
        let vc = CameraVC()
        vc.onCapture = { img in
            onCapture(img)
            presentationMode.wrappedValue.dismiss()
        }
        return vc
    }
    func updateUIViewController(_ uiViewController: CameraVC, context: Context) {}

    // MARK: - UIKit controller
    final class CameraVC: UIViewController, AVCapturePhotoCaptureDelegate {

        // Public
        var onCapture: Callback?

        // Private
        private let session = AVCaptureSession()
        private let output  = AVCapturePhotoOutput()
        private let preview = UIView()
        private let shutter = UIButton(type: .custom)

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black
            setupSession()
            setupPreview()
            setupShutter()
        }
        private func setupSession() {
            session.beginConfiguration()
            session.sessionPreset = .photo

            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                     for: .video, position: .back),
                let input  = try? AVCaptureDeviceInput(device: device),
                session.canAddInput(input),
                session.canAddOutput(output)
            else { return }

            session.addInput(input)
            session.addOutput(output)
            session.commitConfiguration()
            session.startRunning()
        }
        private func setupPreview() {
            preview.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(preview)
            NSLayoutConstraint.activate([
                preview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                preview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                preview.topAnchor.constraint(equalTo: view.topAnchor),
                preview.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            layer.frame = view.bounds
            preview.layer.addSublayer(layer)
        }
        private func setupShutter() {
            shutter.translatesAutoresizingMaskIntoConstraints = false
            shutter.backgroundColor = .white
            shutter.layer.cornerRadius = 35
            shutter.layer.borderWidth  = 3
            shutter.layer.borderColor  = UIColor.white.cgColor
            shutter.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
            view.addSubview(shutter)
            NSLayoutConstraint.activate([
                shutter.widthAnchor .constraint(equalToConstant: 70),
                shutter.heightAnchor.constraint(equalTo: shutter.widthAnchor),
                shutter.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                shutter.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -25)
            ])
        }
        @objc private func takePhoto() {
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .auto
            output.capturePhoto(with: settings, delegate: self)
        }
        func photoOutput(_ output: AVCapturePhotoOutput,
                         didFinishProcessingPhoto photo: AVCapturePhoto,
                         error: Error?) {
            guard let data = photo.fileDataRepresentation(),
                      let img  = UIImage(data: data) else { return }

                // ⭐️ Auto-crop on a background thread
                DispatchQueue.global(qos: .userInitiated).async {
                    let cropped = autoCropped(img)          // <─ new helper
                    DispatchQueue.main.async { self.onCapture?(cropped) }
                }

        }
        override var prefersStatusBarHidden: Bool { true }
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            session.stopRunning()
        }
    }
}
