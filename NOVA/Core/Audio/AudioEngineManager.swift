// NOVA Voice Banking AI
// AudioEngineManager - Real-time audio capture and processing engine

import AVFoundation
import Combine

@MainActor
final class AudioEngineManager: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var audioLevel: Float = 0.0
    @Published private(set) var waveformSamples: [Float] = Array(repeating: 0, count: 50)
    @Published private(set) var isVoiceDetected = false

    let audioEngine = AVAudioEngine()
    private let voiceActivityDetector = VoiceActivityDetector()
    private let fftAnalyzer = FFTAnalyzer()

    private var audioLevelSubject = PassthroughSubject<Float, Never>()
    var audioLevelPublisher: AnyPublisher<Float, Never> { audioLevelSubject.eraseToAnyPublisher() }

    private var waveformSubject = PassthroughSubject<[Float], Never>()
    var waveformPublisher: AnyPublisher<[Float], Never> { waveformSubject.eraseToAnyPublisher() }

    var onAudioBufferCaptured: ((AVAudioPCMBuffer) -> Void)?
    var onSpeechEnded: (() -> Void)?

    private(set) var recordedAudioData = Data()
    private let sampleRate: Double = 16000.0
    private let bufferSize: AVAudioFrameCount = 1024

    init() {
        voiceActivityDetector.onSpeechStarted = { [weak self] in
            Task { @MainActor in
                self?.isVoiceDetected = true
            }
        }
        voiceActivityDetector.onSpeechEnded = { [weak self] in
            Task { @MainActor in
                self?.isVoiceDetected = false
                self?.onSpeechEnded?()
            }
        }
    }

    // MARK: - Audio Session Configuration

    func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setPreferredSampleRate(sampleRate)
        try session.setPreferredIOBufferDuration(Double(bufferSize) / sampleRate)
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Recording Control

    func startRecording() async throws {
        guard !isRecording else { return }

        try configureAudioSession()
        recordedAudioData = Data()

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: recordingFormat) { [weak self] buffer, _ in
            Task { @MainActor in
                self?.processAudioBuffer(buffer)
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
    }

    func stopRecording() {
        guard isRecording else { return }

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRecording = false
        audioLevel = 0
        isVoiceDetected = false
        voiceActivityDetector.reset()

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Audio Buffer Processing

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        let samples = AudioBufferProcessor.extractSamples(from: buffer)
        guard !samples.isEmpty else { return }

        // 1. Calculate and publish RMS level
        let rms = AudioBufferProcessor.calculateRMS(samples)
        audioLevel = rms
        audioLevelSubject.send(rms)

        // 2. Update waveform visualization data
        updateWaveformSamples(from: samples)

        // 3. Voice activity detection
        voiceActivityDetector.processFrame(samples)

        // 4. Accumulate raw audio data
        let data = AudioBufferProcessor.bufferToData(buffer)
        recordedAudioData.append(data)

        // 5. Notify delegate
        onAudioBufferCaptured?(buffer)
    }

    private func updateWaveformSamples(from samples: [Float]) {
        // Downsample to 50 visualization points
        let targetCount = 50
        let step = max(1, samples.count / targetCount)
        var newSamples: [Float] = []

        for i in stride(from: 0, to: min(samples.count, targetCount * step), by: step) {
            let end = min(i + step, samples.count)
            let chunk = Array(samples[i..<end])
            let avg = chunk.reduce(0, +) / Float(chunk.count)
            newSamples.append(abs(avg) * 10) // Scale for visualization
        }

        while newSamples.count < targetCount {
            newSamples.append(0)
        }

        waveformSamples = Array(newSamples.prefix(targetCount))
        waveformSubject.send(waveformSamples)
    }
}
