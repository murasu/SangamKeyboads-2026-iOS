//
//  KeyTranslator.swift
//  SangamKeyboards
//
//  Created by Muthu Nedumaran on 24/09/2025.
//

import Foundation

public protocol KeyTranslator {
    func translateKey(
        keyCode: Int,
        isShifted: Bool,
        currentComposition: String
    ) async -> TranslationResult
    
    func processDelete(composition: String) async -> SimpleDeleteResult
}

public protocol CompositionRules {
    func terminatesComposition(keyCode: Int) -> Bool
}

// KeyboardCore/Models/TranslationResult.swift
import Foundation

public struct TranslationResult {
    public let newComposition: String
    public let displayText: String
    
    public init(newComposition: String, displayText: String) {
        self.newComposition = newComposition
        self.displayText = displayText
    }
}

public struct SimpleDeleteResult {
    public let newComposition: String
    public let charactersToDelete: Int
    
    public init(newComposition: String, charactersToDelete: Int) {
        self.newComposition = newComposition
        self.charactersToDelete = charactersToDelete
    }
}

public struct CompositionResult {
    public let newComposition: String
    public let displayText: String
    public let shouldTriggerPrediction: Bool
    public let actionType: CompositionActionType
    
    public init(newComposition: String, displayText: String, shouldTriggerPrediction: Bool, actionType: CompositionActionType) {
        self.newComposition = newComposition
        self.displayText = displayText
        self.shouldTriggerPrediction = shouldTriggerPrediction
        self.actionType = actionType
    }
}

public struct DeleteResult {
    public let newComposition: String
    public let displayText: String
    public let deleteCount: Int
    
    public init(newComposition: String, displayText: String, deleteCount: Int) {
        self.newComposition = newComposition
        self.displayText = displayText
        self.deleteCount = deleteCount
    }
}

public struct SpaceResult {
    public let textToCommit: String
    public let committedWord: String
    public let actionType: SpaceActionType
    
    public init(textToCommit: String, committedWord: String, actionType: SpaceActionType) {
        self.textToCommit = textToCommit
        self.committedWord = committedWord
        self.actionType = actionType
    }
}

public struct ReturnResult {
    public let textToCommit: String
    public let actionType: ReturnActionType
    
    public init(textToCommit: String, actionType: ReturnActionType) {
        self.textToCommit = textToCommit
        self.actionType = actionType
    }
}

public struct CommitResult {
    public let textToCommit: String
    public let actionType: CommitActionType
    
    public init(textToCommit: String, actionType: CommitActionType) {
        self.textToCommit = textToCommit
        self.actionType = actionType
    }
}

// Action type enums
public enum CompositionActionType {
    case compose
    case terminate
}

public enum SpaceActionType {
    case insertSpace
    case commitWord
}

public enum ReturnActionType {
    case insertReturn
    case commitAndReturn
}

public enum CommitActionType {
    case commitCandidate
}

// UnicodeScalarView extension for Tamil translators
extension String {
    init(_ unicodeScalars: [UnicodeScalar]) {
        self.init(String.UnicodeScalarView(unicodeScalars))
    }
}

extension String.UnicodeScalarView {
    init(_ scalars: [UnicodeScalar]) {
        self.init()
        for scalar in scalars {
            self.append(scalar)
        }
    }
}
