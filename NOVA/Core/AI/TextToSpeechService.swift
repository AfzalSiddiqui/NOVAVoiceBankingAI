// NOVA Voice Banking AI
// TextToSpeechService - Converts AI responses to spoken audio

import AVFoundation

protocol TextToSpeechServiceProtocol: AnyObject, Sendable {
    func speak(_ text: String) async
    func stop()
    var isSpeaking: Bool { get }
}

@MainActor
final class TextToSpeechService: NSObject, ObservableObject, TextToSpeechServiceProtocol {
    @Published private(set) var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()
    private var continuation: CheckedContinuation<Void, Never>?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) async {
        stop()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.9
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1

        isSpeaking = true

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            self.continuation = cont
            self.synthesizer.speak(utterance)
        }

        isSpeaking = false
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        if let continuation {
            continuation.resume()
            self.continuation = nil
        }
        isSpeaking = false
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TextToSpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.continuation?.resume()
            self.continuation = nil
            self.isSpeaking = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.continuation?.resume()
            self.continuation = nil
            self.isSpeaking = false
        }
    }
}
