// NOVA Voice Banking AI
// SecureStorageManager - Encrypted local data persistence

import Foundation
import CryptoKit

protocol SecureStorageManagerProtocol: Sendable {
    func save<T: Codable & Sendable>(key: String, value: T) throws
    func load<T: Codable & Sendable>(key: String, type: T.Type) throws -> T?
    func delete(key: String) throws
    func clearAll() throws
}

final class SecureStorageManager: SecureStorageManagerProtocol, Sendable {

    private let keychainManager: KeychainManagerProtocol
    private let encryptionService: EncryptionServiceProtocol
    private let storageKeyTag = "com.nova.storage.key"

    init(keychainManager: KeychainManagerProtocol, encryptionService: EncryptionServiceProtocol) {
        self.keychainManager = keychainManager
        self.encryptionService = encryptionService
    }

    func save<T: Codable & Sendable>(key: String, value: T) throws {
        let data = try JSONEncoder().encode(value)
        let encryptionKey = try getOrCreateEncryptionKey()
        let encrypted = try encryptionService.encrypt(data: data, key: encryptionKey)
        try keychainManager.save(key: key, data: encrypted)
    }

    func load<T: Codable & Sendable>(key: String, type: T.Type) throws -> T? {
        guard let encrypted = try keychainManager.load(key: key) else {
            return nil
        }
        let encryptionKey = try getOrCreateEncryptionKey()
        let decrypted = try encryptionService.decrypt(data: encrypted, key: encryptionKey)
        return try JSONDecoder().decode(T.self, from: decrypted)
    }

    func delete(key: String) throws {
        try keychainManager.delete(key: key)
    }

    func clearAll() throws {
        try keychainManager.delete(key: storageKeyTag)
    }

    // MARK: - Private

    private func getOrCreateEncryptionKey() throws -> SymmetricKey {
        if let keyData = try keychainManager.load(key: storageKeyTag) {
            return SymmetricKey(data: keyData)
        }

        let key = encryptionService.generateKey()
        let keyData = key.withUnsafeBytes { Data(Array($0)) }
        try keychainManager.save(key: storageKeyTag, data: keyData)
        return key
    }
}
