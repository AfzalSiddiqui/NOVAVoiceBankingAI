// NOVA Voice Banking AI
// VoiceAssistantViewModel - Voice assistant screen business logic

import Foundation
import Combine
import AVFoundation

@MainActor
final class VoiceAssistantViewModel: ObservableObject {

    enum AssistantState: Equatable {
        case idle
        case listening
        case processing
        case responding
        case error(String)
    }

    @Published var state: AssistantState = .idle
    @Published var transcribedText: String = ""
    @Published var conversationHistory: [ConversationMessage] = []
    @Published var audioLevel: Float = 0
    @Published var waveformSamples: [Float] = Array(repeating: 0, count: 50)

    private let container: DependencyContainer
    private var cancellables = Set<AnyCancellable>()

    init(container: DependencyContainer = .shared) {
        self.container = container
        setupBindings()
    }

    private func setupBindings() {
        container.audioEngineManager.$audioLevel
            .receive(on: DispatchQueue.main)
            .assign(to: &$audioLevel)

        container.audioEngineManager.$waveformSamples
            .receive(on: DispatchQueue.main)
            .assign(to: &$waveformSamples)

        (container.speechRecognitionService as? SpeechRecognitionService)?
            .transcriptionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.transcribedText = result.text
                if result.isFinal {
                    Task { [weak self] in
                        await self?.processTranscription(result.text)
                    }
                }
            }
            .store(in: &cancellables)
    }

    func startListening() async {
        guard state != .listening else { return }

        let authorized = await container.speechRecognitionService.requestAuthorization()
        guard authorized else {
            state = .error("Speech recognition not authorized. Please enable in Settings.")
            return
        }

        do {
            state = .listening
            transcribedText = ""
            try await container.audioEngineManager.startRecording()
            try await container.speechRecognitionService.startTranscribing(
                audioEngine: container.audioEngineManager.audioEngine
            )
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func stopListening() {
        container.speechRecognitionService.stopTranscribing()
        container.audioEngineManager.stopRecording()

        if !transcribedText.isEmpty {
            Task {
                await processTranscription(transcribedText)
            }
        } else {
            state = .idle
        }
    }

    func sendTextCommand(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        transcribedText = text
        await processTranscription(text)
    }

    private func processTranscription(_ text: String) async {
        state = .processing

        // Add user message
        let userMessage = ConversationMessage(role: .user, text: text)
        conversationHistory.append(userMessage)

        do {
            let result = try await container.processVoiceCommandUseCase.execute(text: text)

            // Add AI response
            let aiMessage = ConversationMessage(
                role: .assistant,
                text: result.response.text,
                suggestions: result.response.suggestions,
                intent: result.classification.intent
            )
            conversationHistory.append(aiMessage)

            // Speak the response
            state = .responding
            await container.textToSpeechService.speak(result.response.text)
            state = .idle
        } catch {
            let errorMessage = ConversationMessage(
                role: .assistant,
                text: "Sorry, I encountered an error: \(error.localizedDescription)"
            )
            conversationHistory.append(errorMessage)
            state = .error(error.localizedDescription)
        }

        transcribedText = ""
    }

    func stopSpeaking() {
        container.textToSpeechService.stop()
        state = .idle
    }

    func clearHistory() {
        conversationHistory.removeAll()
    }
}

// MARK: - Conversation Message

struct ConversationMessage: Identifiable, Equatable {
    let id = UUID().uuidString
    let role: Role
    let text: String
    let suggestions: [String]
    let intent: BankingIntent?
    let timestamp: Date

    enum Role: Equatable {
        case user
        case assistant
    }

    init(role: Role, text: String, suggestions: [String] = [], intent: BankingIntent? = nil, timestamp: Date = Date()) {
        self.role = role
        self.text = text
        self.suggestions = suggestions
        self.intent = intent
        self.timestamp = timestamp
    }

    static func == (lhs: ConversationMessage, rhs: ConversationMessage) -> Bool {
        lhs.id == rhs.id
    }
}
