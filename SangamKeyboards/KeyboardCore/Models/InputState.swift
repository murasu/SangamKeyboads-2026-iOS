//
//  InputState.swift
//  SangamKeyboards
//
//  Created by Muthu Nedumaran on 24/09/2025.
//

import Foundation

public struct InputState {
    public let languageId: LanguageId
    public let composition: String
    public let previousWord: String?
    public let contextBefore: String?
    public let contextAfter: String?
    public let predictions: [PredictionCandidate]
    public let bestPrediction: PredictionCandidate?
    public let isShifted: Bool
    public let timestamp: Date
    
    public init(
        languageId: LanguageId,
        composition: String = "",
        previousWord: String? = nil,
        contextBefore: String? = nil,
        contextAfter: String? = nil,
        predictions: [PredictionCandidate] = [],
        bestPrediction: PredictionCandidate? = nil,
        isShifted: Bool = false
    ) {
        self.languageId = languageId
        self.composition = composition
        self.previousWord = previousWord
        self.contextBefore = contextBefore
        self.contextAfter = contextAfter
        self.predictions = predictions
        self.bestPrediction = bestPrediction
        self.isShifted = isShifted
        self.timestamp = Date()
    }
}

