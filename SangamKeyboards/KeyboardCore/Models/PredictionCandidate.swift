//
//  PredictionCandidate.swift
//  SangamKeyboards
//
//  Created by Muthu Nedumaran on 24/09/2025.
//

import Foundation

public struct PredictionCandidate: Identifiable, Hashable {
    public let id = UUID()
    public let word: String
    public let score: Double
    public let confidence: Double
    public let type: PredictionType
    public let metadata: PredictionMetadata?
    
    public init(word: String, score: Double, confidence: Double, type: PredictionType, metadata: PredictionMetadata? = nil) {
        self.word = word
        self.score = score
        self.confidence = confidence
        self.type = type
        self.metadata = metadata
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(word)
        hasher.combine(type)
    }
    
    public static func == (lhs: PredictionCandidate, rhs: PredictionCandidate) -> Bool {
        lhs.word == rhs.word && lhs.type == rhs.type
    }
}

public enum PredictionType: Int, CaseIterable {
    case unigram = 1
    case bigram = 2
    case trigram = 3
    case corrected = 7
    case nextWord = 8
    case emoji = 9
    
    public var priority: Int {
        switch self {
        case .corrected: return 0
        case .trigram: return 1
        case .bigram: return 2
        case .unigram: return 3
        case .nextWord: return 4
        case .emoji: return 5
        }
    }
}

public struct PredictionMetadata {
    public let frequency: Int?
    public let lastUsed: Date?
    public let isDualScript: Bool
    public let isEmoji: Bool
    
    public init(frequency: Int? = nil, lastUsed: Date? = nil, isDualScript: Bool = false, isEmoji: Bool = false) {
        self.frequency = frequency
        self.lastUsed = lastUsed
        self.isDualScript = isDualScript
        self.isEmoji = isEmoji
    }
}
