// NOVA Voice Banking AI
// BiometricAuthManager - Face ID / Touch ID authentication

import LocalAuthentication
import Foundation

@MainActor
protocol BiometricAuthManagerProtocol: AnyObject, Sendable {
    func authenticate(reason: String) async throws -> Bool
    func canUseBiometrics() -> BiometricType
    var isAvailable: Bool { get }
}

enum BiometricType: Sendable {
    case faceID, touchID, none
}

enum BiometricError: LocalizedError, Sendable {
    case notAvailable
    case notEnrolled
    case authenticationFailed
    case userCancelled
    case systemCancelled
    case lockout
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable: return "Biometric authentication is not available on this device"
        case .notEnrolled: return "No biometric data enrolled. Please set up Face ID or Touch ID in Settings"
        case .authenticationFailed: return "Authentication failed. Please try again"
        case .userCancelled: return "Authentication was cancelled"
        case .systemCancelled: return "Authentication was cancelled by the system"
        case .lockout: return "Biometric authentication is locked. Please use your passcode"
        case .unknown(let msg): return msg
        }
    }
}

@MainActor
final class BiometricAuthManager: BiometricAuthManagerProtocol {

    var isAvailable: Bool { canUseBiometrics() != .none }

    func canUseBiometrics() -> BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        default: return .none
        }
    }

    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let laError = error as? LAError {
                throw mapLAError(laError)
            }
            throw BiometricError.notAvailable
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch let laError as LAError {
            throw mapLAError(laError)
        } catch {
            throw BiometricError.unknown(error.localizedDescription)
        }
    }

    private func mapLAError(_ error: LAError) -> BiometricError {
        switch error.code {
        case .biometryNotAvailable: return .notAvailable
        case .biometryNotEnrolled: return .notEnrolled
        case .authenticationFailed: return .authenticationFailed
        case .userCancel: return .userCancelled
        case .systemCancel: return .systemCancelled
        case .biometryLockout: return .lockout
        default: return .unknown(error.localizedDescription)
        }
    }
}
