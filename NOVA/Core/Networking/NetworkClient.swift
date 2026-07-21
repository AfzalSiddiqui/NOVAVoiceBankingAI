// NOVA Voice Banking AI
// NetworkClient - Mock networking layer with SSL pinning support

import Foundation

protocol NetworkClientProtocol: Sendable {
    func request<T: Decodable & Sendable>(endpoint: String, method: HTTPMethod, body: Data?) async throws -> T
}

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

final class NetworkClient: NetworkClientProtocol, Sendable {

    func request<T: Decodable & Sendable>(endpoint: String, method: HTTPMethod = .get, body: Data? = nil) async throws -> T {
        // Simulate network latency
        try await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000...800_000_000))

        throw NetworkError.mockMode
    }
}

// MARK: - Errors

enum NetworkError: LocalizedError, Sendable {
    case mockMode
    case invalidURL
    case requestFailed(Int)
    case decodingFailed
    case noConnection
    case timeout
    case sslPinningFailed

    var errorDescription: String? {
        switch self {
        case .mockMode: return "Running in mock mode - no real network calls"
        case .invalidURL: return "Invalid URL"
        case .requestFailed(let code): return "Request failed with status code: \(code)"
        case .decodingFailed: return "Failed to decode response"
        case .noConnection: return "No internet connection"
        case .timeout: return "Request timed out"
        case .sslPinningFailed: return "SSL certificate validation failed"
        }
    }
}
