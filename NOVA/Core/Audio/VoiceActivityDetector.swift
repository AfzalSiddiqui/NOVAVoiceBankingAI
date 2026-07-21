// NOVA Voice Banking AI
// VoiceActivityDetector - Energy-based voice activity detection

import Foundation

final class VoiceActivityDetector {

    enum State: Sendable {
        case silence
        case speech
        case trailing  // Brief silence during speech, waiting to confirm end
    }

    private(set) var state: State = .silence

    var onSpeechStarted: (() -> Void)?
    var onSpeechEnded: (() -> Void)?

    // Configuration thresholds
    var energyThreshold: Float = 0.015
    var silenceTimeout: TimeInterval = 1.5
    var zeroCrossingRateThreshold: Float = 0.08
    var minSpeechDuration: TimeInterval = 0.3

    private var speechStartTime: Date?
    private var lastVoiceTime: Date?
    private var frameCount: Int = 0

    // Adaptive threshold
    private var backgroundNoiseLevel: Float = 0.005
    private let adaptationRate: Float = 0.01

    func processFrame(_ samples: [Float]) {
        frameCount += 1

        let energy = AudioBufferProcessor.calculateRMS(samples)
        let zcr = AudioBufferProcessor.zeroCrossingRate(samples)

        // Adapt background noise level during silence
        if state == .silence {
            backgroundNoiseLevel = backgroundNoiseLevel * (1 - adaptationRate) + energy * adaptationRate
        }

        // Dynamic threshold: 3x background noise level, but at least the configured minimum
        let dynamicThreshold = max(energyThreshold, backgroundNoiseLevel * 3.0)

        let isSpeechFrame = energy > dynamicThreshold && zcr > zeroCrossingRateThreshold

        switch state {
        case .silence:
            if isSpeechFrame {
                state = .speech
                speechStartTime = Date()
                lastVoiceTime = Date()
                onSpeechStarted?()
            }

        case .speech:
            if isSpeechFrame {
                lastVoiceTime = Date()
            } else {
                // Transition to trailing silence
                state = .trailing
            }

        case .trailing:
            if isSpeechFrame {
                // Speech resumed
                state = .speech
                lastVoiceTime = Date()
            } else if let lastVoice = lastVoiceTime,
                      Date().timeIntervalSince(lastVoice) > silenceTimeout {
                // Silence exceeded timeout — speech has ended
                let duration = lastVoice.timeIntervalSince(speechStartTime ?? lastVoice)
                if duration >= minSpeechDuration {
                    onSpeechEnded?()
                }
                state = .silence
                speechStartTime = nil
                lastVoiceTime = nil
            }
        }
    }

    func reset() {
        state = .silence
        speechStartTime = nil
        lastVoiceTime = nil
        frameCount = 0
        backgroundNoiseLevel = 0.005
    }
}
