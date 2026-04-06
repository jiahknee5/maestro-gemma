import AVFoundation
import SwiftUI
import Vision
import CoreImage

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    weak var postureAnalyzer: PostureAnalyzer?
    @Published var permissionGranted = false

    // Latest frame for Gemma vision analysis
    private let ciContext = CIContext()
    private var latestPixelBuffer: CVPixelBuffer?
    private let frameLock = NSLock()

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

        // Store latest frame for Gemma vision
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            frameLock.lock()
            latestPixelBuffer = pixelBuffer
            frameLock.unlock()
        }
    }

    /// Captures the latest camera frame as a base64 JPEG string, resized for model input
    func captureFrameBase64() -> String? {
        frameLock.lock()
        guard let pixelBuffer = latestPixelBuffer else {
            frameLock.unlock()
            return nil
        }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        frameLock.unlock()

        // Resize to 384x288 for fast inference (keeps aspect ~4:3)
        let scale = 384.0 / ciImage.extent.width
        let resized = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = ciContext.createCGImage(resized, from: resized.extent) else { return nil }

        let uiImage = UIImage(cgImage: cgImage)
        guard let jpegData = uiImage.jpegData(compressionQuality: 0.6) else { return nil }

        return jpegData.base64EncodedString()
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
