import SwiftUI

struct BackupView: View {
    @EnvironmentObject private var vpn: VPNManager
    @State private var password = ""
    @State private var importPayload = ""
    @State private var exportedDocument = ""
    @State private var statusMessage: String?
    @State private var isError = false

    var body: some View {
        Form {
            Section("Пароль шифрования (минимум 8 символов, совместимо с Android)") {
                SecureField("Пароль для экспорта / импорта", text: $password)
            }

            Section("Экспорт резервной копии") {
                Button("Создать зашифрованный бэкап") {
                    do {
                        exportedDocument = try vpn.exportEncryptedBackup(password: password)
                        UIPasteboard.general.string = exportedDocument
                        isError = false
                        statusMessage = "Бэкап создан и скопирован в буфер обмена (\(exportedDocument.count) байт)."
                    } catch {
                        isError = true
                        statusMessage = error.localizedDescription
                    }
                }
                .disabled(password.count < 8)

                if !exportedDocument.isEmpty {
                    ShareLink(item: exportedDocument) {
                        Label("Поделиться файлом / текстом бэкапа", systemImage: "square.and.arrow.up")
                    }
                }
            }

            Section("Восстановление из бэкапа") {
                TextEditor(text: $importPayload)
                    .frame(minHeight: 100)
                    .font(.system(.caption, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                if let paste = UIPasteboard.general.string, !paste.isEmpty {
                    Button("Вставить из буфера") {
                        importPayload = paste
                    }
                }

                Button("Восстановить состояние") {
                    do {
                        try vpn.importEncryptedBackup(document: importPayload, password: password)
                        isError = false
                        statusMessage = "Резервная копия успешно восстановлена."
                        importPayload = ""
                    } catch {
                        isError = true
                        statusMessage = error.localizedDescription
                    }
                }
                .disabled(importPayload.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let statusMessage {
                Section {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(isError ? .red : .green)
                }
            }
        }
        .navigationTitle("Резервные копии")
    }
}
