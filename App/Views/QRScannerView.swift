import AVFoundation
import SwiftUI

struct QRScannerView: View {
    let onScan: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                QRCameraPreview(
                    onCodeDetected: { code in
                        dismiss()
                        onScan(code)
                    },
                    onError: { message in
                        errorMessage = message
                    }
                )
                .ignoresSafeArea()

                if let errorMessage {
                    Text(errorMessage)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding()
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.85), lineWidth: 3)
                        .frame(width: 240, height: 240)
                }
            }
            .navigationTitle("QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("✕") { dismiss() }
                }
            }
        }
    }
}

private struct QRCameraPreview: UIViewControllerRepresentable {
    let onCodeDetected: (String) -> Void
    let onError: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerController {
        let controller = QRScannerController()
        controller.onCodeDetected = onCodeDetected
        controller.onError = onError
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerController, context: Context) {}
}

private final class QRScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeDetected: ((String) -> Void)?
    var onError: ((String) -> Void)?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var didEmit = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            onError?("Камера недоступна на этом устройстве")
            return
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            onError?("Не удалось настроить сканер QR")
            return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.stopRunning()
            }
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !didEmit,
              let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue,
              !value.isEmpty else {
            return
        }
        didEmit = true
        session.stopRunning()
        onCodeDetected?(value)
    }
}
