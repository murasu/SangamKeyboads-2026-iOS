import Foundation
import KeyboardCore

/// Handles character composition logic with your actual Tamil translators
actor CompositionEngine {
    
    // MARK: - Dependencies
    private let keyTranslators: [LanguageId: KeyTranslator]
    private let languageRules: [LanguageId: CompositionRules]
    
    init() {
        // Initialize with your actual translators
        var translators: [LanguageId: KeyTranslator] = [:]
        
        // Only initialize for enabled languages
        for language in AppConfiguration.shared.enabledLanguages {
            switch language {
            case .tamil:
                // Default to Tamil99, but we can make this configurable
                translators[.tamil] = Tamil99KeyTranslator()
                // For Anjal: translators[.tamil] = TamilAnjalKeyTranslator()
            default:
                break
            }
        }
        
        self.keyTranslators = translators
        self.languageRules = Self.buildLanguageRules()
    }
    
    // MARK: - Character Processing
    
    func processCharacter(
        keyCode: Int,
        isShifted: Bool,
        currentState: InputState
    ) async -> CompositionResult {
        
        let languageId = currentState.languageId
        
        // Check if this key terminates composition
        if terminatesComposition(keyCode: keyCode, languageId: languageId) {
            return CompositionResult(
                newComposition: "",
                displayText: String(UnicodeScalar(keyCode) ?? UnicodeScalar(32)!),
                shouldTriggerPrediction: false,
                actionType: .terminate
            )
        }
        
        // Get current composition or extract from context
        var composition = currentState.composition
        if composition.isEmpty {
            composition = await extractWordBeforeCursor(from: currentState)
        }
        
        // Apply language-specific translation
        let translationResult = await translateKey(
            keyCode: keyCode,
            isShifted: isShifted,
            currentComposition: composition,
            languageId: languageId
        )
        
        let newComposition = translationResult.newComposition
        
        return CompositionResult(
            newComposition: newComposition,
            displayText: translationResult.displayText,
            shouldTriggerPrediction: shouldTriggerPrediction(
                composition: newComposition,
                languageId: languageId
            ),
            actionType: .compose
        )
    }
    
    func processDelete(currentState: InputState) async -> DeleteResult {
        guard !currentState.composition.isEmpty else {
            return DeleteResult(
                newComposition: "",
                displayText: "",
                deleteCount: 1
            )
        }
        
        let languageId = currentState.languageId
        
        if let translator = keyTranslators[languageId] {
            let deleteResult = await translator.processDelete(
                composition: currentState.composition
            )
            
            return DeleteResult(
                newComposition: deleteResult.newComposition,
                displayText: deleteResult.newComposition,
                deleteCount: deleteResult.charactersToDelete
            )
        } else {
            // Fallback for languages without translators
            return DeleteResult(
                newComposition: String(currentState.composition.dropLast()),
                displayText: String(currentState.composition.dropLast()),
                deleteCount: 1
            )
        }
    }
    
    func processSpace(
        currentState: InputState,
        shouldCommitBestPrediction: Bool
    ) async -> SpaceResult {
        
        let composition = currentState.composition
        
        if composition.isEmpty {
            return SpaceResult(
                textToCommit: "",
                committedWord: "",
                actionType: .insertSpace
            )
        }
        
        // Determine what to commit
        let wordToCommit: String
        if shouldCommitBestPrediction,
           let bestPrediction = currentState.bestPrediction,
           bestPrediction.confidence > 0.7 {
            wordToCommit = bestPrediction.word
        } else {
            wordToCommit = composition
        }
        
        return SpaceResult(
            textToCommit: wordToCommit,
            committedWord: wordToCommit,
            actionType: .commitWord
        )
    }
    
    func processReturn(currentState: InputState) async -> ReturnResult {
        let composition = currentState.composition
        
        return ReturnResult(
            textToCommit: composition,
            actionType: composition.isEmpty ? .insertReturn : .commitAndReturn
        )
    }
    
    func commitCandidate(
        candidate: PredictionCandidate,
        currentState: InputState
    ) async -> CommitResult {
        
        return CommitResult(
            textToCommit: candidate.word,
            actionType: .commitCandidate
        )
    }
    
    // MARK: - Private Methods
    
    private func translateKey(
        keyCode: Int,
        isShifted: Bool,
        currentComposition: String,
        languageId: LanguageId
    ) async -> TranslationResult {
        
        guard let translator = keyTranslators[languageId] else {
            // Fallback to simple character insertion
            let char = String(UnicodeScalar(keyCode) ?? UnicodeScalar(32)!)
            return TranslationResult(
                newComposition: currentComposition + char,
                displayText: char
            )
        }
        
        return await translator.translateKey(
            keyCode: keyCode,
            isShifted: isShifted,
            currentComposition: currentComposition
        )
    }
    
    private func terminatesComposition(keyCode: Int, languageId: LanguageId) -> Bool {
        guard let rules = languageRules[languageId] else {
            // Default: only non-letters terminate composition
            return !CharacterSet.letters.contains(UnicodeScalar(keyCode) ?? UnicodeScalar(32)!)
        }
        
        return rules.terminatesComposition(keyCode: keyCode)
    }
    
    private func shouldTriggerPrediction(
        composition: String,
        languageId: LanguageId
    ) -> Bool {
        // Don't predict for very short or very long compositions
        let length = composition.count
        return length >= 2 && length <= 16
    }
    
    private func extractWordBeforeCursor(from state: InputState) async -> String {
        // Extract current word from context (similar to setWordBeforeCursorAsComposingAndAppendingPulli)
        guard let contextBefore = state.contextBefore else { return "" }
        
        // Find the last word boundary
        let words = contextBefore.components(separatedBy: .whitespacesAndNewlines)
        guard let lastWord = words.last else { return "" }
        
        // Only return if it's all Tamil characters
        let tamilRange = NSRange(location: 0x0B80, length: 0x0BFF - 0x0B80)
        let tamilCharacterSet = CharacterSet(charactersIn: UnicodeScalar(tamilRange.location)!...UnicodeScalar(tamilRange.location + tamilRange.length - 1)!)
        
        if lastWord.rangeOfCharacter(from: tamilCharacterSet.inverted) == nil {
            return lastWord
        }
        
        return ""
    }
    
    // MARK: - Language Rules Setup
    
    private static func buildLanguageRules() -> [LanguageId: CompositionRules] {
        var rules: [LanguageId: CompositionRules] = [:]
        
        // Tamil rules (based on your existing logic)
        rules[.tamil] = TamilCompositionRules()
        
        return rules
    }
}

// MARK: - Tamil Composition Rules

struct TamilCompositionRules: CompositionRules {
    func terminatesComposition(keyCode: Int) -> Bool {
        // Based on your Tamil keyboard logic
        let tgv_a = 0x0B85 // Tamil letter A
        let tgm_pulli = 0x0BCD // Tamil sign virama
        let tgg_sri = 0x0BB8 // Tamil letter SA
        let tgg_xa = 0x0BB7 // Tamil letter SHA
        
        if keyCode < tgv_a { return true }
        if keyCode > tgm_pulli && !(keyCode == tgg_sri || keyCode == tgg_xa) { return true }
        
        return false
    }
}
