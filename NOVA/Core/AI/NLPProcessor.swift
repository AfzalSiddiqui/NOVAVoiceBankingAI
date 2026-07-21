// NOVA Voice Banking AI
// NLPProcessor - Natural Language Processing utilities

import NaturalLanguage
import Foundation

protocol NLPProcessorProtocol: Sendable {
    func extractEntities(from text: String) -> [ExtractedEntity]
    func analyzeSentiment(of text: String) -> SentimentResult
    func tokenize(_ text: String) -> [String]
    func detectLanguage(of text: String) -> String?
    func lemmatize(_ text: String) -> [String]
}

// MARK: - Models

struct ExtractedEntity: Sendable, Identifiable {
    let id: String
    let text: String
    let type: EntityType
    let startIndex: Int
    let endIndex: Int

    enum EntityType: String, Sendable {
        case person, organization, place, date, currency, number, unknown
    }

    init(id: String = UUID().uuidString, text: String, type: EntityType, startIndex: Int = 0, endIndex: Int = 0) {
        self.id = id
        self.text = text
        self.type = type
        self.startIndex = startIndex
        self.endIndex = endIndex
    }
}

struct SentimentResult: Sendable {
    let score: Double
    let label: SentimentLabel

    enum SentimentLabel: String, Sendable {
        case positive, negative, neutral
    }

    static var neutral: SentimentResult {
        SentimentResult(score: 0, label: .neutral)
    }
}

// MARK: - Implementation

final class NLPProcessor: NLPProcessorProtocol, Sendable {

    func extractEntities(from text: String) -> [ExtractedEntity] {
        var entities: [ExtractedEntity] = []
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, range in
            guard let tag else { return true }

            let entityType: ExtractedEntity.EntityType = switch tag {
            case .personalName: .person
            case .organizationName: .organization
            case .placeName: .place
            default: .unknown
            }

            if entityType != .unknown {
                let start = text.distance(from: text.startIndex, to: range.lowerBound)
                let end = text.distance(from: text.startIndex, to: range.upperBound)
                entities.append(ExtractedEntity(
                    text: String(text[range]),
                    type: entityType,
                    startIndex: start,
                    endIndex: end
                ))
            }
            return true
        }

        return entities
    }

    func analyzeSentiment(of text: String) -> SentimentResult {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        let score = Double(sentiment?.rawValue ?? "0") ?? 0

        let label: SentimentResult.SentimentLabel
        if score > 0.1 {
            label = .positive
        } else if score < -0.1 {
            label = .negative
        } else {
            label = .neutral
        }

        return SentimentResult(score: score, label: label)
    }

    func tokenize(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        return tokenizer.tokens(for: text.startIndex..<text.endIndex).map { String(text[$0]) }
    }

    func detectLanguage(of text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue
    }

    func lemmatize(_ text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = text
        var lemmas: [String] = []

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lemma, options: [.omitPunctuation, .omitWhitespace]) { tag, range in
            let lemma = tag?.rawValue ?? String(text[range])
            lemmas.append(lemma)
            return true
        }

        return lemmas
    }
}
