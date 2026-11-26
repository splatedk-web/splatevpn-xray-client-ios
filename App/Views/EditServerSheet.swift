import SwiftUI

struct EditServerSheet: View {
    let original: ServerProfile
    let onSave: (ServerProfile) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var address: String
    @State private var portText: String
    @State private var sni: String
    @State private var host: String
    @State private var path: String

    init(server: ServerProfile, onSave: @escaping (ServerProfile) -> Void) {
        self.original = server
        self.onSave = onSave
        _name = State(initialValue: server.name)
        _address = State(initialValue: server.address)
        _portText = State(initialValue: String(server.port))
        _sni = State(initialValue: server.sni)
        _host = State(initialValue: server.host)
        _path = State(initialValue: server.path)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Название", text: $name)
                    TextField("Адрес / Хост", text: $address)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Порт", text: $portText)
                        .keyboardType(.numberPad)
                }

                Section("Транспорт и TLS") {
                    TextField("SNI", text: $sni)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Host / Authority", text: $host)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Path / ServiceName", text: $path)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Редактировать узел")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        var copy = original
                        copy.name = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? original.name : name
                        copy.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let p = Int(portText), (1...65535).contains(p) {
                            copy.port = p
                        }
                        copy.sni = sni.trimmingCharacters(in: .whitespacesAndNewlines)
                        copy.host = host.trimmingCharacters(in: .whitespacesAndNewlines)
                        copy.path = path.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(copy)
                        dismiss()
                    }
                    .disabled(address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
