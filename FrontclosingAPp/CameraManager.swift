import AVFoundation

final class CameraManager: ObservableObject {
    let session = AVCaptureSession()
    
    init() {
        configure()
    }
    
    private func configure() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        guard
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                 for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: camera),
            session.canAddInput(input)
        else { return }
        
        session.addInput(input)
        session.commitConfiguration()
        session.startRunning()
    }
}
