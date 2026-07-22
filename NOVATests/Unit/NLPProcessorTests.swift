// NOVA Voice Banking AI
// NLPProcessorTests - Unit tests for NLP processing utilities

import XCTest
@testable import NOVA

final class NLPProcessorTests: XCTestCase {

    private var processor: NLPProcessor!

    override func setUp() {
        super.setUp()
        processor = NLPProcessor()
    }

    func testTokenize() {
        let tokens = processor.tokenize("Show my account balance")
        XCTAssertEqual(tokens.count, 4)
        XCTAssertTrue(tokens.contains("Show"))
        XCTAssertTrue(tokens.contains("balance"))
    }

    func testDetectLanguage() {
        let english = processor.detectLanguage(of: "Show my account balance")
        XCTAssertEqual(english, "en")
    }

    func testSentimentPositive() {
        let result = processor.analyzeSentiment(of: "I love this amazing banking app, it's fantastic!")
        XCTAssertEqual(result.label, .positive)
    }

    func testSentimentNegative() {
        let result = processor.analyzeSentiment(of: "This is terrible and awful, I hate it")
        XCTAssertEqual(result.label, .negative)
    }

    func testLemmatize() {
        let lemmas = processor.lemmatize("running transactions quickly")
        XCTAssertFalse(lemmas.isEmpty)
    }

    func testExtractEntities() {
        let entities = processor.extractEntities(from: "Transfer money to Ahmed in Dubai")
        // NL framework entity extraction depends on model; just verify no crash
        XCTAssertNotNil(entities)
    }
}

final class AudioBufferProcessorTests: XCTestCase {

    func testCalculateRMSWithZeros() {
        let samples: [Float] = [0, 0, 0, 0]
        let rms = AudioBufferProcessor.calculateRMS(samples)
        XCTAssertEqual(rms, 0)
    }

    func testCalculateRMSWithValues() {
        let samples: [Float] = [1, -1, 1, -1]
        let rms = AudioBufferProcessor.calculateRMS(samples)
        XCTAssertEqual(rms, 1.0, accuracy: 0.01)
    }

    func testCalculatePeak() {
        let samples: [Float] = [0.1, 0.5, -0.8, 0.3]
        let peak = AudioBufferProcessor.calculatePeak(samples)
        XCTAssertEqual(peak, 0.8, accuracy: 0.01)
    }

    func testNoiseGate() {
        let samples: [Float] = [0.005, 0.5, -0.003, 0.8]
        let gated = AudioBufferProcessor.applyNoiseGate(samples, threshold: 0.01)
        XCTAssertEqual(gated[0], 0)
        XCTAssertEqual(gated[1], 0.5)
        XCTAssertEqual(gated[2], 0)
        XCTAssertEqual(gated[3], 0.8)
    }

    func testNormalize() {
        let samples: [Float] = [0.2, 0.4, -0.6]
        let normalized = AudioBufferProcessor.normalize(samples)
        let peak = AudioBufferProcessor.calculatePeak(normalized)
        XCTAssertEqual(peak, 1.0, accuracy: 0.01)
    }

    func testZeroCrossingRate() {
        let samples: [Float] = [1, -1, 1, -1, 1]
        let zcr = AudioBufferProcessor.zeroCrossingRate(samples)
        XCTAssertEqual(zcr, 1.0, accuracy: 0.01)
    }

    func testEmptyInput() {
        XCTAssertEqual(AudioBufferProcessor.calculateRMS([]), 0)
        XCTAssertEqual(AudioBufferProcessor.calculatePeak([]), 0)
        XCTAssertEqual(AudioBufferProcessor.zeroCrossingRate([]), 0)
    }
}

final class EncryptionServiceTests: XCTestCase {

    private var service: EncryptionService!

    override func setUp() {
        super.setUp()
        service = EncryptionService()
    }

    func testEncryptDecrypt() throws {
        let key = service.generateKey()
        let original = "Sensitive banking data".data(using: .utf8)!

        let encrypted = try service.encrypt(data: original, key: key)
        let decrypted = try service.decrypt(data: encrypted, key: key)

        XCTAssertEqual(original, decrypted)
        XCTAssertNotEqual(original, encrypted)
    }

    func testDecryptWithWrongKeyFails() throws {
        let key1 = service.generateKey()
        let key2 = service.generateKey()
        let data = "Secret".data(using: .utf8)!

        let encrypted = try service.encrypt(data: data, key: key1)

        XCTAssertThrowsError(try service.decrypt(data: encrypted, key: key2))
    }

    func testHash() {
        let data = "test data".data(using: .utf8)!
        let hash1 = service.hash(data: data)
        let hash2 = service.hash(data: data)

        XCTAssertEqual(hash1, hash2)
        XCTAssertEqual(hash1.count, 64) // SHA256 produces 64 hex chars
    }

    func testDifferentDataProducesDifferentHash() {
        let data1 = "hello".data(using: .utf8)!
        let data2 = "world".data(using: .utf8)!

        XCTAssertNotEqual(service.hash(data: data1), service.hash(data: data2))
    }
}
