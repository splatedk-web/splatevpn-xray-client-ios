import CoreImage.CIFilterBuiltins
import SwiftUI

struct ServerShareSheet: View {
    let server: ServerProfile
    @Environment(\.dismiss) private var dismiss

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(server.name)
                    .font(.headline)

                if let qrImage = generateQR(from: server.rawLink) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .padding(16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16))
                } else {
                    Text("Нет ссылки для генерации QR")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if !server.rawLink.isEmpty {
                    Button {
                        UIPasteboard.general.string = server.rawLink
                    } label: {
                        Label("Копировать ссылку", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 24)
                }

                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("Поделиться")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }

    private func generateQR(from string: String) -> UIImage? {
        guard !string.isEmpty else { return nil }
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
