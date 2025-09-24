//
//  TamilAnjalKeyTranslator.swift
//  SangamKeyboards
//
//  Created by Muthu Nedumaran on 24/09/2025.
//

import Foundation
import KeyboardCore

final class TamilAnjalKeyTranslator: KeyTranslator {
    
    // MARK: - State Management
    private var gksResults = KeyStringResults()
    
    // MARK: - Lookup Tables (from your Objective-C code)
    
    // Vowel keystrokes
    private let anjalUV1Keys: [Character] = ["a","i","u","e","a","o","a","q","A","I","U","E","O"]
    private let anjalUV2Keys: [Character] = ["a","i","u","e","i","o","u","q","*","*","*","*","M"]
    
    // Vowel characters
    private let anjalUV1Char: [UnicodeScalar] = [
        0x0B85, 0x0B87, 0x0B89, 0x0B8E, 0x0B90, 0x0B92, 0x0B94, 0x0B83,
        0x0B86, 0x0B88, 0x0B8A, 0x0B8F, 0x0B93
    ].compactMap(UnicodeScalar.init)
    
    private let anjalUVS1Char: [UnicodeScalar] = [
        0x0008, 0x0BBF, 0x0BC1, 0x0BC6, 0x0BC8, 0x0BCA, 0x0BCC, 0x0BCD,
        0x0BBE, 0x0BC0, 0x0BC2, 0x0BC7, 0x0BCB
    ].compactMap(UnicodeScalar.init)
    
    // Consonant keystrokes
    private let anjalUC1Keys: [Character] = [
        "k","g","c","d","t","p","b","R", "y","r","l","v","z","L",
        "n","n","N","w","m","n", "j","s","S","h","x","s", "n","W"
    ]
    private let anjalUC2Keys: [Character] = [
        "*","*","h","*","h","*","*","*", "*","*","*","*","*","*",
        "g","j","*","-","*","-", "*","h","*","*","*","r", "=","*"
    ]
    
    // Consonant characters
    private let anjalUC1Char: [UnicodeScalar] = [
        0x0B95, 0x0B95, 0x0B9A, 0x0B9F, 0x0BA4, 0x0BAA, 0x0BAA, 0x0BB1,
        0x0BAF, 0x0BB0, 0x0BB2, 0x0BB5, 0x0BB4, 0x0BB3,
        0x0BA9, 0x0BA9, 0x0BA3, 0x0BA8, 0x0BAE, 0x0BA9,
        0x0B9C, 0x0B9A, 0x0BB8, 0x0BB9, 0x0B01, 0x0B9A,
        0x0BA9, 0x0BA9
    ].compactMap(UnicodeScalar.init)
    
    init() {
        clearResults()
        gksResults.imeType = .tamil
    }
    
    // MARK: - KeyTranslator Protocol
    
    func translateKey(
        keyCode: Int,
        isShifted: Bool,
        currentComposition: String
    ) async -> TranslationResult {
        
        // Set context from composition
        if !currentComposition.isEmpty {
            gksResults.contextBefore = UnicodeScalar(currentComposition.unicodeScalars.last!).value
        }
        
        let currKey = Character(UnicodeScalar(keyCode)!)
        var translatedString = [UnicodeScalar]()
        
        // Call main translation logic (converted from your C code)
        getKeyStringTamilAnjal(currKey: currKey, result: &translatedString)
        
        // Convert result
        let outputString = String(String.UnicodeScalarView(translatedString))
        let deleteCount = gksResults.deleteCount
        
        // Handle deletions
        var finalOutput = ""
        if deleteCount > 0 {
            finalOutput += String(repeating: "\u{0008}", count: Int(deleteCount)) // DEL codes
        }
        finalOutput += outputString
        
        return TranslationResult(
            newComposition: currentComposition + outputString,
            displayText: finalOutput
        )
    }
    
    func processDelete(composition: String) async -> SimpleDeleteResult {
        if composition.isEmpty {
            return SimpleDeleteResult(newComposition: "", charactersToDelete: 1)
        }
        
        // Tamil Anjal delete logic
        clearResults()
        let newComposition = String(composition.dropLast())
        
        return SimpleDeleteResult(
            newComposition: newComposition,
            charactersToDelete: 1
        )
    }
    
    // MARK: - Tamil Anjal Logic (Converted from C)
    
    private func getKeyStringTamilAnjal(currKey: Character, result: inout [UnicodeScalar]) {
        result.removeAll()
        
        // Handle vowel reset
        if currKey == "f" {
            if gksResults.prevKey == "f" {
                result.append(UnicodeScalar(0x0BCD)!) // pulli
            }
            gksResults.prevKeyType = .characterEnd
            return
        }
        
        // Handle 'n' replacement after delete
        var actualKey = currKey
        if currKey == "n" && isValidTamilContext(gksResults.contextBefore) {
            actualKey = "W" // force dental na
        }
        
        switch gksResults.prevKeyType {
        case .characterEnd:
            startNewSessionTamilAnjal(currKey: actualKey, result: &result)
            
        case .firstVowel, .firstVowelSign:
            handleVowelSequence(currKey: actualKey, result: &result)
            
        case .firstConso:
            handleFirstConsonant(currKey: actualKey, result: &result)
            
        case .secondConso:
            handleSecondConsonant(currKey: actualKey, result: &result)
            
        default:
            startNewSessionTamilAnjal(currKey: actualKey, result: &result)
        }
        
        gksResults.prevKey = String(currKey)
    }
    
    private func handleVowelSequence(currKey: Character, result: inout [UnicodeScalar]) {
        // Handle vowel combinations (a+i = ai, etc.)
        if let vpos = getKeyPosition(currKey, in: anjalUV2Keys, matchingPrev: gksResults.prevKey, in: anjalUV1Keys) {
            if gksResults.prevKeyType == .firstVowel {
                result.append(anjalUV1Char[vpos])
                gksResults.prevKeyType = .secondVowel
            } else {
                result.append(anjalUVS1Char[vpos])
                gksResults.prevKeyType = .secondVowelSign
            }
            gksResults.deleteCount = 1
            return
        }
        
        // Not a vowel sequence, start new session
        startNewSessionTamilAnjal(currKey: currKey, result: &result)
    }
    
    private func handleFirstConsonant(currKey: Character, result: inout [UnicodeScalar]) {
        // Handle special consonant combinations
        if gksResults.prevKey == "t" && currKey == "r" {
            // tr -> rra + pulli + rra + pulli
            result.append(contentsOf: [
                UnicodeScalar(0x0BB1)!, UnicodeScalar(0x0BCD)!,
                UnicodeScalar(0x0BB1)!, UnicodeScalar(0x0BCD)!
            ])
            gksResults.deleteCount = 2
            gksResults.prevKeyType = .secondConso
            return
        }
        
        // Check for second consonant
        if let vpos = getKeyPosition(currKey, in: anjalUC2Keys, matchingPrev: gksResults.prevKey, in: anjalUC1Keys) {
            result.append(anjalUC1Char[vpos])
            result.append(UnicodeScalar(0x0BCD)!) // pulli
            gksResults.deleteCount = 2
            gksResults.prevKeyType = .secondConso
            return
        }
        
        // Check for vowel sign
        if let vpos = getKeyPosition(currKey, in: anjalUV1Keys) {
            if currKey != "a" {
                result.append(anjalUVS1Char[vpos])
                gksResults.deleteCount = 1 // delete pulli
            } else {
                gksResults.deleteCount = 1 // delete pulli, add nothing
            }
            gksResults.prevKeyType = .firstVowelSign
            return
        }
        
        startNewSessionTamilAnjal(currKey: currKey, result: &result)
    }
    
    private func handleSecondConsonant(currKey: Character, result: inout [UnicodeScalar]) {
        // Handle vowel after consonant cluster
        if let vpos = getKeyPosition(currKey, in: anjalUV1Keys) {
            if currKey != "a" {
                result.append(anjalUVS1Char[vpos])
                gksResults.deleteCount = 1
            } else {
                gksResults.deleteCount = 1
            }
            gksResults.prevKeyType = .firstVowelSign
            return
        }
        
        startNewSessionTamilAnjal(currKey: currKey, result: &result)
    }
    
    private func startNewSessionTamilAnjal(currKey: Character, result: inout [UnicodeScalar]) {
        // Check if consonant
        if let vpos = getKeyPosition(currKey, in: anjalUC1Keys) {
            // Use dental na at word start
            if (gksResults.prevKeyType == .none || gksResults.prevKeyType == .whiteSpace) &&
               currKey == "n" && gksResults.prevKey != "\u{0008}" {
                result.append(UnicodeScalar(0x0BA8)!) // dental na
            } else {
                result.append(anjalUC1Char[vpos])
            }
            result.append(UnicodeScalar(0x0BCD)!) // pulli
            
            gksResults.prevKeyType = .firstConso
            gksResults.firstConsoKey = String(currKey)
            gksResults.fixPrevious = true
            return
        }
        
        // Check if vowel
        if let vpos = getKeyPosition(currKey, in: anjalUV1Keys) {
            result.append(anjalUV1Char[vpos])
            gksResults.prevKeyType = .firstVowel
            gksResults.firstVowelKey = String(currKey)
            gksResults.fixPrevious = true
            return
        }
        
        // Non-Indic character
        if currKey.isLetter {
            // Don't send Roman letters in Indic mode
            return
        } else {
            result.append(UnicodeScalar(String(currKey).unicodeScalars.first!))
            gksResults.prevKeyType = currKey.isWhitespace ? .whiteSpace : .characterEnd
            gksResults.fixPrevious = true
        }
    }
    
    // MARK: - Helper Methods
    
    private func getKeyPosition(_ key: Character, in array: [Character]) -> Int? {
        return array.firstIndex(of: key)
    }
    
    private func getKeyPosition(_ key: Character, in array: [Character],
                               matchingPrev prevKey: String, in prevArray: [Character]) -> Int? {
        guard let prevChar = prevKey.first,
              let prevIndex = prevArray.firstIndex(of: prevChar) else {
            return nil
        }
        
        // Find matching key at same index
        if prevIndex < array.count && array[prevIndex] == key {
            return prevIndex
        }
        
        return nil
    }
    
    private func isValidTamilContext(_ contextChar: UInt32) -> Bool {
        return contextChar >= 0x0B85 && contextChar <= 0x0BCD
    }
    
    private func clearResults() {
        gksResults = KeyStringResults()
    }
}

// MARK: - Supporting Types

struct KeyStringResults {
    var deleteCount: Int = 0
    var insertCount: Int = 0
    var fixPrevious: Bool = false
    var prevKey: String = ""
    var prevKeyType: KeyType = .none
    var prevCharType: CharType = .nonIndic
    var firstConsoKey: String = ""
    var firstVowelKey: String = ""
    var contextBefore: UInt32 = 0
    var imeType: IMEType = .tamil
}

enum KeyType {
    case none
    case characterEnd
    case whiteSpace
    case firstVowel
    case secondVowel
    case thirdVowel
    case firstVowelSign
    case secondVowelSign
    case thirdVowelSign
    case firstConso
    case secondConso
    case thirdConso
}

enum CharType {
    case nonIndic
    case vowel
    case consonant
}

enum IMEType {
    case tamil
    case malayalam
    case hindi
    // Add others as needed
}
