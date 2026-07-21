// NOVA Voice Banking AI
// SecurityViewModel - Security screen business logic

import Foundation

@MainActor
final class SecurityViewModel: ObservableObject {
    @Published var biometricType: BiometricType = .none
    @Published var isBiometricEnabled = true
    @Published var isVoiceEnrolled = false
    @Published var cards: [Card] = []
    @Published var isLoading = false
    @Published var alertMessage: String?
    @Published var showAlert = false

    private let container: DependencyContainer

    init(container: DependencyContainer = .shared) {
        self.container = container
    }

    func loadSecurityStatus() async {
        isLoading = true
        biometricType = container.biometricAuthManager.canUseBiometrics()
        isVoiceEnrolled = container.voiceAuthService.isEnrolled

        do {
            cards = try await container.cardRepository.getCards()
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }

        isLoading = false
    }

    func toggleCardFreeze(card: Card) async {
        do {
            if card.isFrozen {
                _ = try await container.cardRepository.unfreezeCard(id: card.id)
            } else {
                _ = try await container.cardRepository.freezeCard(id: card.id)
            }
            cards = try await container.cardRepository.getCards()
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    func enrollVoice() async {
        do {
            let result = try await container.voiceAuthService.enrollVoice()
            isVoiceEnrolled = result
            alertMessage = result ? "Voice enrollment successful" : "Voice enrollment failed"
            showAlert = true
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    func authenticateBiometric() async {
        do {
            let result = try await container.biometricAuthManager.authenticate(reason: "Verify your identity")
            alertMessage = result ? "Authentication successful" : "Authentication failed"
            showAlert = true
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}
