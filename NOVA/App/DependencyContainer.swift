// NOVA Voice Banking AI
// Dependency Injection Container - Centralized service resolution

import SwiftUI

@MainActor
final class DependencyContainer: ObservableObject, Sendable {
    static let shared = DependencyContainer()

    // MARK: - Core Services

    lazy var audioEngineManager: AudioEngineManager = {
        AudioEngineManager()
    }()

    lazy var speechRecognitionService: SpeechRecognitionServiceProtocol = {
        SpeechRecognitionService()
    }()

    lazy var intentClassifier: IntentClassifierProtocol = {
        IntentClassifier()
    }()

    lazy var aiResponseGenerator: AIResponseGeneratorProtocol = {
        AIResponseGenerator()
    }()

    lazy var textToSpeechService: TextToSpeechServiceProtocol = {
        TextToSpeechService()
    }()

    lazy var nlpProcessor: NLPProcessorProtocol = {
        NLPProcessor()
    }()

    lazy var ragEngine: RAGEngineProtocol = {
        RAGEngine(bankingRepository: bankingRepository, transactionRepository: transactionRepository)
    }()

    // MARK: - Security Services

    lazy var biometricAuthManager: BiometricAuthManagerProtocol = {
        BiometricAuthManager()
    }()

    lazy var keychainManager: KeychainManagerProtocol = {
        KeychainManager()
    }()

    lazy var secureEnclaveManager: SecureEnclaveManagerProtocol = {
        SecureEnclaveManager()
    }()

    lazy var voiceAuthService: VoiceAuthenticationServiceProtocol = {
        VoiceAuthenticationService(audioEngine: audioEngineManager)
    }()

    lazy var encryptionService: EncryptionServiceProtocol = {
        EncryptionService()
    }()

    // MARK: - Networking

    lazy var networkClient: NetworkClientProtocol = {
        NetworkClient()
    }()

    // MARK: - Repositories

    lazy var bankingRepository: BankingRepositoryProtocol = {
        BankingRepository(networkClient: networkClient, storage: secureStorage)
    }()

    lazy var transactionRepository: TransactionRepositoryProtocol = {
        TransactionRepository(networkClient: networkClient)
    }()

    lazy var cardRepository: CardRepositoryProtocol = {
        CardRepository(networkClient: networkClient)
    }()

    lazy var wealthRepository: WealthRepositoryProtocol = {
        WealthRepository(networkClient: networkClient)
    }()

    // MARK: - Local Storage

    lazy var secureStorage: SecureStorageManagerProtocol = {
        SecureStorageManager(keychainManager: keychainManager, encryptionService: encryptionService)
    }()

    // MARK: - Use Cases

    lazy var getBalanceUseCase: GetBalanceUseCase = {
        GetBalanceUseCase(repository: bankingRepository)
    }()

    lazy var transferMoneyUseCase: TransferMoneyUseCase = {
        TransferMoneyUseCase(
            repository: bankingRepository,
            fraudDetector: fraudDetectionUseCase
        )
    }()

    lazy var getTransactionsUseCase: GetTransactionsUseCase = {
        GetTransactionsUseCase(repository: transactionRepository)
    }()

    lazy var freezeCardUseCase: FreezeCardUseCase = {
        FreezeCardUseCase(repository: cardRepository)
    }()

    lazy var analyzeSpendingUseCase: AnalyzeSpendingUseCase = {
        AnalyzeSpendingUseCase(transactionRepository: transactionRepository)
    }()

    lazy var fraudDetectionUseCase: FraudDetectionUseCase = {
        FraudDetectionUseCase()
    }()

    lazy var processVoiceCommandUseCase: ProcessVoiceCommandUseCase = {
        ProcessVoiceCommandUseCase(
            intentClassifier: intentClassifier,
            bankingRepository: bankingRepository,
            transactionRepository: transactionRepository,
            cardRepository: cardRepository,
            aiResponseGenerator: aiResponseGenerator,
            analyzeSpendingUseCase: analyzeSpendingUseCase
        )
    }()

    lazy var financialAdvisorUseCase: FinancialAdvisorUseCase = {
        FinancialAdvisorUseCase(
            transactionRepository: transactionRepository,
            bankingRepository: bankingRepository,
            aiResponseGenerator: aiResponseGenerator
        )
    }()

    private init() {}
}

// MARK: - Environment Key

struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue = DependencyContainer.shared
}

extension EnvironmentValues {
    var dependencyContainer: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}
