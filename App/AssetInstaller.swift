import Foundation

enum AssetInstaller {
    private static let managedFiles = ["geoip.dat", "geosite.dat"]

    static func installBundledGeoAssetsIfNeeded() {
        let destDir = AppGroup.assetsDirectoryURL
        for name in managedFiles {
            guard let bundledURL = Bundle.main.url(forResource: name, withExtension: nil) else {
                continue
            }
            let targetURL = destDir.appendingPathComponent(name)
            if shouldCopy(from: bundledURL, to: targetURL) {
                try? FileManager.default.removeItem(at: targetURL)
                do {
                    try FileManager.default.copyItem(at: bundledURL, to: targetURL)
                    AppLogger.shared.log("Installed \(name) to App Group assets", source: "Assets")
                } catch {
                    AppLogger.shared.log("Failed to install \(name): \(error.localizedDescription)", source: "Assets", level: "ERROR")
                }
            }
        }
    }

    static var hasGeoAssetsInstalled: Bool {
        managedFiles.allSatisfy {
            FileManager.default.fileExists(atPath: AppGroup.assetsDirectoryURL.appendingPathComponent($0).path)
        }
    }

    private static func shouldCopy(from src: URL, to dst: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: dst.path) else { return true }
        let srcSize = (try? FileManager.default.attributesOfItem(atPath: src.path)[.size] as? Int) ?? 0
        let dstSize = (try? FileManager.default.attributesOfItem(atPath: dst.path)[.size] as? Int) ?? 0
        return srcSize > 0 && srcSize != dstSize
    }
}
