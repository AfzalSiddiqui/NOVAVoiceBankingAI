// NOVA Voice Banking AI
// ProcessVoiceCommandUseCase - End-to-end voice command processing pipeline

import Foundation

final class ProcessVoiceCommandUseCase: Sendable {

    private let intentClassifier: IntentClassifierProtocol
    private let bankingRepository: BankingRepositoryProtocol
    private let transactionRepository: TransactionRepositoryProtocol
    private let cardRepository: CardRepositoryProtocol
    private let aiResponseGenerator: AIResponseGeneratorProtocol
    private let analyzeSpendingUseCase: AnalyzeSpendingUseCase

    init(
        intentClassifier: IntentClassifierProtocol,
        bankingRepository: BankingRepositoryProtocol,
        transactionRepository: TransactionRepositoryProtocol,
        cardRepository: CardRepositoryProtocol,
        aiResponseGenerator: AIResponseGeneratorProtocol,
        analyzeSpendingUseCase: AnalyzeSpendingUseCase
    ) {
        self.intentClassifier = intentClassifier
        self.bankingRepository = bankingRepository
        self.transactionRepository = transactionRepository
        self.cardRepository = cardRepository
        self.aiResponseGenerator = aiResponseGenerator
        self.analyzeSpendingUseCase = analyzeSpendingUseCase
    }

    func execute(text: String) async throws -> VoiceCommandResult {
        // 1. Classify intent
        let classification = await intentClassifier.classify(text: text)

        // 2. Build response context
        let context = try await buildContext(for: classification.intent)

        // 3. Generate AI response
        let response = await aiResponseGenerator.generateResponse(for: classification.intent, context: context)

        return VoiceCommandResult(
            classification: classification,
            response: response,
            voiceCommand: VoiceCommand(rawText: text, confidence: classification.confidence)
        )
    }

    private func buildContext(for intent: BankingIntent) async throws -> ResponseContext {
        let accounts = try await bankingRepository.getAccounts()
        let balance = accounts.first?.balance
        let transactions = try? await transactionRepository.getRecentTransactions(limit: 5)

        var spending: [SpendingBreakdown]?
        if case .spendingAnalysis = intent {
            let analysis = try? await analyzeSpendingUseCase.execute()
            spending = analysis?.breakdown
        }

        return ResponseContext(
            userName: accounts.first?.holderName.components(separatedBy: " ").first ?? "User",
            accountBalance: balance,
            recentTransactions: transactions,
            spendingBreakdown: spending
        )
    }
}

struct VoiceCommandResult: Sendable {
    let classification: IntentClassificationResult
    let response: AIResponse
    let voiceCommand: VoiceCommand
}
