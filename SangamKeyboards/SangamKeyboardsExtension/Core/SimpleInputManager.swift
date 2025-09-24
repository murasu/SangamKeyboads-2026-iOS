//
//  SimpleInputManager.swift
//  SangamKeyboards
//
//  Created by Muthu Nedumaran on 24/09/2025.
//

import Foundation
import KeyboardCore

/// Simplified input manager to test the flow before full async implementation
@MainActor
final class SimpleInputManager: ObservableObject {
    
    @Published private(set) var currentComposition = ""
    @Published private(set) var predictions: [PredictionCandidate] = []
    
    private let mockPredictionService = MockPredictionService()
    private let currentLanguage: LanguageId = .tamil
    
    func handleCharacterInput(_ char: String) {
        currentComposition += char
        updatePredictions()
    }
    
    func handleDelete() {
        if !currentComposition.isEmpty {
            currentComposition = String(currentComposition.dropLast())
            updatePredictions()
        }
    }
    
    func handleSpace() {
        currentComposition = ""
        predictions = []
    }
    
    func selectPrediction(_ prediction: PredictionCandidate) {
        currentComposition = ""
        predictions = []
        // In real implementation, this would commit the prediction
    }
    
    private func updatePredictions() {
        predictions = mockPredictionService.getPredictions(
            for: currentComposition,
            language: currentLanguage
        )
    }
}

