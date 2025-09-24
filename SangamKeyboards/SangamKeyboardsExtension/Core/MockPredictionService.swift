//
//  MockPredictionService.swift
//  SangamKeyboards
//
//  Created by Muthu Nedumaran on 24/09/2025.
//

import Foundation
import KeyboardCore

/// Simple mock service to test integration before implementing full async version
final class MockPredictionService {
    
    func getPredictions(for composition: String, language: LanguageId) -> [PredictionCandidate] {
        // Return mock predictions for testing
        guard !composition.isEmpty else { return [] }
        
        return [
            PredictionCandidate(
                word: composition + "1",
                score: 1.0,
                confidence: 0.9,
                type: .unigram
            ),
            PredictionCandidate(
                word: composition + "ing",
                score: 0.8,
                confidence: 0.7,
                type: .unigram
            ),
            PredictionCandidate(
                word: composition + "ed",
                score: 0.6,
                confidence: 0.5,
                type: .unigram
            )
        ]
    }
}
