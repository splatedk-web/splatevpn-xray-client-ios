import SwiftUI
import AVFoundation

public struct QrScannerView: UIViewControllerRepresentable {
    public let onScan: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    public init(onScan: @escaping (String) -> Void) {
        self.onScan = onScan
    }

    public func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    public func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public final class Coordinator: NSObject, ScannerViewControllerDelegate {
        let parent: QrScannerView

        init(parent: QrScannerView) {
            self.parent = parent
        }

        public func didScanCode(_ code: String) {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            parent.onScan(code)
            parent.dismiss()
        }
    }
}

public protocol ScannerViewControllerDelegate: AnyObject {
    func didScanCode(_ code: String)
}

public final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    public weak var delegate: ScannerViewControllerDelegate?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCaptureSession()
    }

    private func setupCaptureSession() {
        let session = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              session.canAddInput(videoInput) else {
            return
        }

        session.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.layer.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        self.previewLayer = preview

        self.captureSession = session

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObject.stringValue else {
            return
        }

        captureSession?.stopRunning()
        delegate?.didScanCode(stringValue)
    }
}
