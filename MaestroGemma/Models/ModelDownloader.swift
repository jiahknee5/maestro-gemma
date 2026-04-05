import Foundation

// Downloads Gemma 4 E2B weights from Cactus HuggingFace repo on first launch.
// Weights are stored in Documents/gemma-4-e2b-it/ and never re-downloaded.

@MainActor
class ModelDownloader: ObservableObject {
    static let shared = ModelDownloader()

    @Published var isDownloading = false
    @Published var progress: Double = 0
    @Published var statusMessage = ""
    @Published var isReady = false
    @Published var error: String?

    let modelDir: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("gemma-4-e2b-it")
    }()

    // Cactus weight files for Gemma 4 E2B INT4
    // Manifest fetched from HuggingFace API
    private let repoId = "Cactus-Compute/gemma-4-E2B-it"
    private let hfBase = "https://huggingface.co/Cactus-Compute/gemma-4-E2B-it/resolve/main"

    func checkOrDownload() async {
        if modelExists() {
            isReady = true
            return
        }
        await downloadModel()
    }

    func modelExists() -> Bool {
        // Check for a sentinel file that indicates complete download
        let sentinel = modelDir.appendingPathComponent(".download_complete")
        return FileManager.default.fileExists(atPath: sentinel.path)
    }

    func modelPath() -> String? {
        guard modelExists() else { return nil }
        return modelDir.path
    }

    private func downloadModel() async {
        isDownloading = true
        error = nil
        statusMessage = "Fetching model manifest..."

        do {
            // Fetch file list from HuggingFace API
            let files = try await fetchManifest()
            try FileManager.default.createDirectory(at: modelDir, withIntermediateDirectories: true)

            let total = files.count
            for (index, file) in files.enumerated() {
                let filename = (file as NSString).lastPathComponent
                statusMessage = "Downloading \(filename) (\(index + 1)/\(total))"
                progress = Double(index) / Double(total)
                try await downloadFile(path: file)
            }

            // Write sentinel
            let sentinel = modelDir.appendingPathComponent(".download_complete")
            try "done".write(to: sentinel, atomically: true, encoding: .utf8)

            progress = 1.0
            statusMessage = "Model ready!"
            isDownloading = false
            isReady = true

        } catch {
            self.error = error.localizedDescription
            self.statusMessage = "Download failed: \(error.localizedDescription)"
            isDownloading = false
        }
    }

    private func fetchManifest() async throws -> [String] {
        let apiURL = URL(string: "https://huggingface.co/api/models/\(repoId)")!
        let (data, _) = try await URLSession.shared.data(from: apiURL)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let siblings = json["siblings"] as? [[String: Any]] else {
            throw URLError(.cannotParseResponse)
        }
        return siblings.compactMap { $0["rfilename"] as? String }
            .filter { !$0.hasPrefix(".") }
    }

    private func downloadFile(path: String) async throws {
        let url = URL(string: "\(hfBase)/\(path)")!
        let dest = modelDir.appendingPathComponent(path)

        // Skip if already exists
        if FileManager.default.fileExists(atPath: dest.path) { return }

        // Create subdirectories if needed
        try FileManager.default.createDirectory(
            at: dest.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let (tempURL, _) = try await URLSession.shared.download(from: url)
        try FileManager.default.moveItem(at: tempURL, to: dest)
    }
}
