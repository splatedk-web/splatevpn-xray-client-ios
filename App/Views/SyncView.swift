import SwiftUI

struct SyncView: View {
    @EnvironmentObject private var vpn: VPNManager
    @State private var webdavPassword = ""
    @State private var backupPassword = ""
    @State private var isBusy = false
    @State private var statusText: String?
    @State private var isError = false

    var body: some View {
        Form {
            Section("WebDAV сервер (Яндекс.Диск / Nextcloud)") {
                TextField("https://webdav.yandex.ru/SplateVPN/", text: Binding(
                    get: { vpn.state.settings.webdavUrl },
                    set: { v in vpn.updateSettings { $0.webdavUrl = v } }
                ))
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                TextField("Логин WebDAV", text: Binding(
                    get: { vpn.state.settings.webdavUser },
                    set: { v in vpn.updateSettings { $0.webdavUser = v } }
                ))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                SecureField("Пароль приложения WebDAV", text: $webdavPassword)
            }

            Section("Ключ шифрования резервной копии (AES-256-GCM)") {
                SecureField("Пароль бэкапа (от 8 символов)", text: $backupPassword)
            }

            Section("Действия") {
                Button {
                    Task { await upload() }
                } label: {
                    HStack {
                        Label("Выгрузить в WebDAV", systemImage: "icloud.and.arrow.up")
                        Spacer()
                        if isBusy { ProgressView().controlSize(.small) }
                    }
                }
                .disabled(isBusy || vpn.state.settings.webdavUrl.isEmpty || backupPassword.count < 8)

                Button {
                    Task { await downloadAndRestore() }
                } label: {
                    Label("Загрузить и восстановить из WebDAV", systemImage: "icloud.and.arrow.down")
                }
                .disabled(isBusy || vpn.state.settings.webdavUrl.isEmpty || backupPassword.isEmpty)
            }

            if let statusText {
                Section {
                    Text(statusText)
                        .font(.footnote)
                        .foregroundStyle(isError ? .red : .green)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Перенос и синхронизация")
    }

    private func upload() async {
        isBusy = true
        defer { isBusy = false }
        do {
            let encrypted = try vpn.exportEncryptedBackup(password: backupPassword)
            try await WebDavSyncService.upload(
                document: encrypted,
                urlString: vpn.state.settings.webdavUrl,
                username: vpn.state.settings.webdavUser,
                password: webdavPassword
            )
            isError = false
            statusText = "Зашифрованный бэкап успешно выгружен в WebDAV."
        } catch {
            isError = true
            statusText = error.localizedDescription
        }
    }

    private func downloadAndRestore() async {
        isBusy = true
        defer { isBusy = false }
        do {
            let doc = try await WebDavSyncService.download(
                urlString: vpn.state.settings.webdavUrl,
                username: vpn.state.settings.webdavUser,
                password: webdavPassword
            )
            try vpn.importEncryptedBackup(document: doc, password: backupPassword)
            isError = false
            statusText = "Состояние успешно восстановлено из WebDAV."
        } catch {
            isError = true
            statusText = error.localizedDescription
        }
    }
}
