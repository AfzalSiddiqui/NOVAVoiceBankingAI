// NOVA Voice Banking AI
// EncryptionService - Data encryption/decryption using CryptoKit

import Foundation
import CryptoKit

protocol EncryptionServiceProtocol: Sendable {
    func encrypt(data: Data, key: SymmetricKey) throws -> Data
    func decrypt(data: Data, key: SymmetricKey) throws -> Data
    func generateKey() -> SymmetricKey
    func hash(data: Data) -> String
}

final class EncryptionService: EncryptionServiceProtocol, Sendable {

    func encrypt(data: Data, key: SymmetricKey) throws -> Data {
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            guard let combined = sealedBox.combined else {
                throw EncryptionError.encryptionFailed
            }
            return combined
        } catch let error as EncryptionError {
            throw error
        } catch {
            throw EncryptionError.encryptionFailed
        }
    }

    func decrypt(data: Data, key: SymmetricKey) throws -> Data {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            throw EncryptionError.decryptionFailed
        }
    }

    func generateKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }

    func hash(data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Errors

enum EncryptionError: LocalizedError, Sendable {
    case encryptionFailed
    case decryptionFailed
    case invalidKey

    var errorDescription: String? {
        switch self {
        case .encryptionFailed: return "Failed to encrypt data"
        case .decryptionFailed: return "Failed to decrypt data"
        case .invalidKey: return "Invalid encryption key"
        }
    }
}
