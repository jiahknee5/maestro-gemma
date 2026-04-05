import AVFoundation
import Accelerate

// Real-time pitch detection using AVFoundation + autocorrelation
class PitchDetector: NSObject, ObservableObject {
    @Published var detectedNote: String = "—"
    @Published var detectedCents: Int = 0
    @Published var isActive = false

    private let audioEngine = AVAudioEngine()
    private let bufferSize: AVAudioFrameCount = 4096
    private let sampleRate: Double = 44100

    func start() {
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            self?.processBuffer(buffer)
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .defaultToSpeaker)
            try AVAudioSession.sharedInstance().setActive(true)
            try audioEngine.start()
            DispatchQueue.main.async { self.isActive = true }
        } catch {
            print("[PitchDetector] Failed to start: \(error)")
        }
    }

    func stop() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        DispatchQueue.main.async {
            self.isActive = false
            self.detectedNote = "—"
            self.detectedCents = 0
        }
    }

    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        let data = Array(UnsafeBufferPointer(start: channelData, count: frameCount))

        guard let frequency = autocorrelationPitch(data, sampleRate: sampleRate), frequency > 60 else {
            DispatchQueue.main.async { self.detectedNote = "—" }
            return
        }

        let (note, cents) = noteAndCents(from: frequency)
        DispatchQueue.main.async {
            self.detectedNote = note
            self.detectedCents = cents
        }
    }

    // Autocorrelation-based pitch estimation
    private func autocorrelationPitch(_ samples: [Float], sampleRate: Double) -> Double? {
        let n = samples.count
        var acf = [Float](repeating: 0, count: n)

        // Compute autocorrelation
        vDSP_conv(samples, 1, samples, 1, &acf, 1, vDSP_Length(n), vDSP_Length(n))

        // Find first peak after initial drop
        let minLag = Int(sampleRate / 1000.0)  // 1000 Hz max
        let maxLag = Int(sampleRate / 60.0)    // 60 Hz min (low G on violin)

        guard maxLag < n else { return nil }

        var peakValue: Float = 0
        var peakLag = minLag

        for lag in minLag..<maxLag {
            if acf[lag] > peakValue {
                peakValue = acf[lag]
                peakLag = lag
            }
        }

        // Require reasonable correlation
        guard acf[0] > 0, peakValue / acf[0] > 0.3 else { return nil }

        return sampleRate / Double(peakLag)
    }

    private func noteAndCents(from frequency: Double) -> (String, Int) {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let a4 = 440.0
        let semitones = 12.0 * log2(frequency / a4) + 57 // semitones from C0
        let rounded = (semitones).rounded()
        let cents = Int(((semitones - rounded) * 100).rounded())
        let noteIndex = Int(rounded.truncatingRemainder(dividingBy: 12))
        let octave = Int(rounded / 12)
        let safeIndex = ((noteIndex % 12) + 12) % 12
        return ("\(noteNames[safeIndex])\(octave)", cents)
    }
}
