// NOVA Voice Banking AI
// SpeechRecognitionService - Speech-to-text using Apple Speech framework

import Speech
@preconcurrency import AVFoundation
import Combine

// MARK: - Protocol

@MainActor
protocol SpeechRecognitionServiceProtocol: AnyObject, Sendable {
    func requestAuthorization() async -> Bool
    func startTranscribing(audioEngine: AVAudioEngine) async throws
    func stopTranscribing()
    var transcriptionPublisher: AnyPublisher<TranscriptionResult, Never> { get }
}

// MARK: - Models

struct TranscriptionResult: Sendable {
    let text: String
    let isFinal: Bool
    let confidence: Float
    let segments: [TranscriptionSegment]

    static var empty: TranscriptionResult {
        TranscriptionResult(text: "", isFinal: false, confidence: 0, segments: [])
    }
}

struct TranscriptionSegment: Sendable {
    let text: String
    let timestamp: TimeInterval
    let duration: TimeInterval
    let confidence: Float
}

// MARK: - Service Implementation

@MainActor
final class SpeechRecognitionService: NSObject, ObservableObject, SpeechRecognitionServiceProtocol {
    @Published private(set) var isTranscribing = false
    @Published private(set) var currentTranscription = ""
    @Published private(set) var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    nonisolated(unsafe) let transcriptionSubject = PassthroughSubject<TranscriptionResult, Never>()

    nonisolated var transcriptionPublisher: AnyPublisher<TranscriptionResult, Never> {
        transcriptionSubject.eraseToAnyPublisher()
    }

    init(locale: Locale = Locale(identifier: "en-US")) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
        super.init()
    }

    // MARK: - Authorization

    nonisolated func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    // MARK: - Transcription Control

    func startTranscribing(audioEngine: AVAudioEngine) async throws {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerNotAvailable
        }

        stopTranscribing()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        self.recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let transcription = result.bestTranscription
                let segments = transcription.segments.map { segment in
                    TranscriptionSegment(
                        text: segment.substring,
                        timestamp: segment.timestamp,
                        duration: segment.duration,
                        confidence: segment.confidence
                    )
                }

                let avgConfidence = segments.isEmpty ? 0 : segments.map(\.confidence).reduce(0, +) / Float(segments.count)

                let transcriptionResult = TranscriptionResult(
                    text: transcription.formattedString,
                    isFinal: result.isFinal,
                    confidence: avgConfidence,
                    segments: segments
                )

                Task { @MainActor in
                    self.currentTranscription = transcription.formattedString
                    self.transcriptionSubject.send(transcriptionResult)
                }
            }

            if error != nil || result?.isFinal == true {
                Task { @MainActor in
                    self.stopTranscribing()
                }
            }
        }

        isTranscribing = true
    }

    func stopTranscribing() {
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isTranscribing = false
    }

    /// Append audio buffer directly (for use without tap)
    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        recognitionRequest?.append(buffer)
    }
}

// MARK: - Errors

enum SpeechRecognitionError: LocalizedError, Sendable {
    case recognizerNotAvailable
    case notAuthorized
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .recognizerNotAvailable: return "Speech recognizer is not available"
        case .notAuthorized: return "Speech recognition not authorized"
        case .recognitionFailed(let msg): return "Recognition failed: \(msg)"
        }
    }
}
