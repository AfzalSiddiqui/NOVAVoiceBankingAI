// NOVA Voice Banking AI
// SecureEnclaveManager - Cryptographic key management using Secure Enclave

import Foundation
import Security

protocol SecureEnclaveManagerProtocol: Sendable {
    func generateKeyPair(tag: String) throws
    func sign(data: Data, keyTag: String) throws -> Data
    func verify(data: Data, signature: Data, keyTag: String) throws -> Bool
    func deleteKey(tag: String) throws
}

final class SecureEnclaveManager: SecureEnclaveManagerProtocol, Sendable {

    func generateKeyPair(tag: String) throws {
        // Remove existing key first
        try? deleteKey(tag: tag)

        let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .privateKeyUsage,
            nil
        )

        guard let accessControl = access else {
            throw SecureEnclaveError.accessControlCreationFailed
        }

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tag.data(using: .utf8)!,
                kSecAttrAccessControl as String: accessControl
            ] as [String: Any]
        ]

        var error: Unmanaged<CFError>?
        guard SecKeyCreateRandomKey(attributes as CFDictionary, &error) != nil else {
            throw SecureEnclaveError.keyGenerationFailed(error?.takeRetainedValue().localizedDescription ?? "Unknown error")
        }
    }

    func sign(data: Data, keyTag: String) throws -> Data {
        let privateKey = try getPrivateKey(tag: keyTag)

        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            privateKey,
            .ecdsaSignatureMessageX962SHA256,
            data as CFData,
            &error
        ) as Data? else {
            throw SecureEnclaveError.signingFailed(error?.takeRetainedValue().localizedDescription ?? "Unknown error")
        }

        return signature
    }

    func verify(data: Data, signature: Data, keyTag: String) throws -> Bool {
        let privateKey = try getPrivateKey(tag: keyTag)

        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw SecureEnclaveError.publicKeyExtractionFailed
        }

        var error: Unmanaged<CFError>?
        let result = SecKeyVerifySignature(
            publicKey,
            .ecdsaSignatureMessageX962SHA256,
            data as CFData,
            signature as CFData,
            &error
        )

        return result
    }

    func deleteKey(tag: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag.data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecureEnclaveError.keyDeletionFailed
        }
    }

    // MARK: - Private

    private func getPrivateKey(tag: String) throws -> SecKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag.data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let key = item else {
            throw SecureEnclaveError.keyNotFound
        }

        return key as! SecKey
    }
}

// MARK: - Errors

enum SecureEnclaveError: LocalizedError, Sendable {
    case accessControlCreationFailed
    case keyGenerationFailed(String)
    case keyNotFound
    case signingFailed(String)
    case publicKeyExtractionFailed
    case keyDeletionFailed

    var errorDescription: String? {
        switch self {
        case .accessControlCreationFailed: return "Failed to create access control for Secure Enclave"
        case .keyGenerationFailed(let msg): return "Key generation failed: \(msg)"
        case .keyNotFound: return "Key not found in Secure Enclave"
        case .signingFailed(let msg): return "Signing failed: \(msg)"
        case .publicKeyExtractionFailed: return "Failed to extract public key"
        case .keyDeletionFailed: return "Failed to delete key from Secure Enclave"
        }
    }
}
