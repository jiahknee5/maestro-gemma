import AVFoundation
import SwiftUI
import Vision

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    weak var postureAnalyzer: PostureAnalyzer?
    @Published var permissionGranted = false

    func requestPermissions() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async { self?.permissionGranted = granted }
        }
    }

    func start() {
        guard permissionGranted else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.configureSession()
            self.session.startRunning()
        }
    }

    func stop() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
        }
    }

    private func configureSession() {
        guard !session.isRunning else { return }
        session.beginConfiguration()
        session.sessionPreset = .hd1280x720

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) { session.addInput(input) }

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.queue", qos: .userInteractive))
        output.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(output) { session.addOutput(output) }

        session.commitConfiguration()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        postureAnalyzer?.analyze(sampleBuffer: sampleBuffer, orientation: .leftMirrored)
    }
}

struct CameraPreview: UIViewRepresentable {
    let cameraManager: CameraManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraManager.session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(previewLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
