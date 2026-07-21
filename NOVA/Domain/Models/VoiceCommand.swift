// NOVA Voice Banking AI
// VoiceCommand - Voice input domain model

import Foundation

struct VoiceCommand: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let rawText: String
    let processedText: String
    let timestamp: Date
    let confidence: Float
    let language: String
    let duration: TimeInterval

    init(
        id: String = UUID().uuidString,
        rawText: String,
        processedText: String? = nil,
        timestamp: Date = Date(),
        confidence: Float = 0,
        language: String = "en-US",
        duration: TimeInterval = 0
    ) {
        self.id = id
        self.rawText = rawText
        self.processedText = processedText ?? rawText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        self.timestamp = timestamp
        self.confidence = confidence
        self.language = language
        self.duration = duration
    }

    static var mock: VoiceCommand {
        VoiceCommand(
            rawText: "Show my account balance",
            confidence: 0.95,
            duration: 2.3
        )
    }
}
