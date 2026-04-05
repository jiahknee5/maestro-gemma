import SwiftUI

struct ModelLoadingView: View {
    @ObservedObject var downloader = ModelDownloader.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                Image(systemName: "music.note")
                    .font(.system(size: 64))
                    .foregroundColor(.white)

                Text("Maestro Gemma")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                if downloader.isDownloading {
                    VStack(spacing: 14) {
                        ProgressView(value: downloader.progress)
                            .progressViewStyle(.linear)
                            .tint(.white)
                            .frame(width: 260)

                        Text(downloader.statusMessage)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)

                        Text("Downloading AI model — one time only")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.4))
                    }
                } else if let error = downloader.error {
                    VStack(spacing: 12) {
                        Text("Download failed")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Try Again") {
                            Task { await downloader.checkOrDownload() }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                    }
                } else {
                    ProgressView()
                        .tint(.white)
                    Text(downloader.statusMessage)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(40)
        }
        .task {
            await downloader.checkOrDownload()
        }
    }
}
