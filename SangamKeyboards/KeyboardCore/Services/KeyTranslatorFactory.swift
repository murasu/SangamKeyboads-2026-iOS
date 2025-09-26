//
//  KeyTranslatorFactory.swift
//  SangamKeyboards
//
//  Created by Muthu Nedumaran on 26/09/2025.
//

import Foundation

public class KeyTranslatorFactory {
    
    // MARK: - Main Factory Method
    public static func getTranslator(for languageId: LanguageId) -> KeyTranslator {
        switch languageId {
        // Tamil99 - dedicated translator
        case .tamil:
            return Tamil99KeyTranslator()
            
        // Languages using Common Translator
        case .malayalam, .bengali, .hindi, .sinhala, .marathi, .sanskrit, .nepali, .jawi:
            return CommonKeyTranslator()
            
        // Languages using Common Anjal Translator
        case .tamilAnjal:
            return CommonAnjalKeyTranslator(anjalType: .tamil)
        case .malayalamAnjal:
            return CommonAnjalKeyTranslator(anjalType: .malayalam)
        case .kannadaAnjal:
            return CommonAnjalKeyTranslator(anjalType: .kannada)
        case .teluguAnjal:
            return CommonAnjalKeyTranslator(anjalType: .telugu)
            
        // QWERTY Jawi (special case)
        case .qwertyJawi:
            return CommonKeyTranslator() // Uses common with special config
            
        // English fallback
        case .english:
            return EnglishKeyTranslator()
            
        // Add other specific languages as needed
        @unknown default:
            print("Warning: Unknown language \(languageId), using Common translator")
            return CommonKeyTranslator()
        }
    }
    
    // MARK: - Translator Availability Check
    public static func isTranslatorAvailable(for languageId: LanguageId) -> Bool {
        // Check if we have a translator for this language
        switch languageId {
        case .tamil, .malayalam, .bengali, .hindi, .sinhala, .marathi, .sanskrit,
             .nepali, .jawi, .tamilAnjal, .malayalamAnjal, .kannadaAnjal,
             .teluguAnjal, .qwertyJawi, .english:
            return true
        @unknown default:
            return false
        }
    }
    
    // MARK: - Special Configuration Check
    public static func usesAVS(for languageId: LanguageId) -> Bool {
        // AVS (Automatic Vowel Selection) confirmation for Tamil variants
        switch languageId {
        case .tamil, .tamilAnjal:
            return true
        default:
            return false
        }
    }
    
    public static func getMinComposedLength(for languageId: LanguageId) -> Int {
        // Special configuration for QWERTY Jawi
        switch languageId {
        case .qwertyJawi:
            return 1
        default:
            return 0
        }
    }
    
    // MARK: - App Variant Support
    public static func getSupportedLanguages(for appVariant: AppVariant) -> [LanguageId] {
        switch appVariant {
        case .multiLanguage:
            return LanguageId.allCases
            
        case .tamilOnly:
            return [.tamil, .tamilAnjal]
            
        case .jawiOnly:
            return [.jawi, .qwertyJawi, .english] // Jawi variants + fallback English
        }
    }
    
    // MARK: - Translator Information
    public static func getTranslatorInfo(for languageId: LanguageId) -> TranslatorInfo {
        switch languageId {
        case .tamil:
            return TranslatorInfo(
                name: "Tamil99",
                description: "Standard Tamil99 layout with contextual composition",
                supportsComposition: true,
                isRTL: false,
                usesAVS: true
            )
            
        case .tamilAnjal:
            return TranslatorInfo(
                name: "Tamil Anjal",
                description: "Tamil Anjal phonetic layout",
                supportsComposition: true,
                isRTL: false,
                usesAVS: true
            )
            
        case .malayalam, .bengali, .hindi, .sinhala, .marathi, .sanskrit, .nepali, .jawi:
            return TranslatorInfo(
                name: languageId.displayName,
                description: "Uses common translator for \(languageId.displayName)",
                supportsComposition: true,
                isRTL: languageId == .jawi
            )
            
        case .malayalamAnjal, .kannadaAnjal, .teluguAnjal:
            return TranslatorInfo(
                name: languageId.displayName,
                description: "Anjal phonetic layout for \(languageId.displayName)",
                supportsComposition: true,
                isRTL: false
            )
            
        case .qwertyJawi:
            return TranslatorInfo(
                name: "QWERTY Jawi",
                description: "QWERTY layout for Jawi script",
                supportsComposition: false,
                isRTL: true,
                minComposedLength: 1
            )
            
        case .punjabi, .gujarati, .kannada, .telugu, .oriya, .assamese, .grantha, .qwerty:
            return TranslatorInfo(
                name: languageId.displayName,
                description: "Standard \(languageId.displayName) keyboard layout",
                supportsComposition: false,
                isRTL: false
            )
            
        case .english:
            return TranslatorInfo(
                name: "English",
                description: "Standard English QWERTY layout",
                supportsComposition: false,
                isRTL: false
            )
        }
    }
}

// MARK: - Supporting Types

public enum AnjalType {
    case tamil
    case malayalam
    case kannada
    case telugu
}

public struct TranslatorInfo {
    public let name: String
    public let description: String
    public let supportsComposition: Bool
    public let isRTL: Bool
    public let usesAVS: Bool
    public let minComposedLength: Int
    
    public init(name: String, description: String, supportsComposition: Bool, isRTL: Bool, usesAVS: Bool = false, minComposedLength: Int = 0) {
        self.name = name
        self.description = description
        self.supportsComposition = supportsComposition
        self.isRTL = isRTL
        self.usesAVS = usesAVS
        self.minComposedLength = minComposedLength
    }
}

// MARK: - Actual Translator Classes
// These match your existing translator architecture

private class CommonKeyTranslator: KeyTranslator {
    func translateKey(keyCode: Int, isShifted: Bool, currentComposition: String) async -> TranslationResult {
        // Implementation will use your existing CommonKeyTranslator logic
        return TranslationResult(newComposition: "", displayText: "")
    }
    
    func processDelete(composition: String) async -> SimpleDeleteResult {
        return SimpleDeleteResult(newComposition: "", charactersToDelete: 1)
    }
}

private class CommonAnjalKeyTranslator: KeyTranslator {
    private let anjalType: AnjalType
    
    init(anjalType: AnjalType) {
        self.anjalType = anjalType
    }
    
    func translateKey(keyCode: Int, isShifted: Bool, currentComposition: String) async -> TranslationResult {
        // Implementation will use your existing CommonAnjalKeyTranslator logic
        return TranslationResult(newComposition: "", displayText: "")
    }
    
    func processDelete(composition: String) async -> SimpleDeleteResult {
        return SimpleDeleteResult(newComposition: "", charactersToDelete: 1)
    }
}

private class EnglishKeyTranslator: KeyTranslator {
    func translateKey(keyCode: Int, isShifted: Bool, currentComposition: String) async -> TranslationResult {
        let char = String(UnicodeScalar(keyCode) ?? UnicodeScalar(65)!) // Fallback to 'A'
        let result = isShifted ? char.uppercased() : char.lowercased()
        return TranslationResult(newComposition: "", displayText: result)
    }
    
    func processDelete(composition: String) async -> SimpleDeleteResult {
        return SimpleDeleteResult(newComposition: "", charactersToDelete: 1)
    }
}
