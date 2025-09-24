//
//  Tamil99KeyTranslator.swift
//  SangamKeyboards
//
//  Created by Muthu Nedumaran on 24/09/2025.
//

import Foundation
import KeyboardCore

final class Tamil99KeyTranslator: KeyTranslator {
    
    // MARK: - Constants (from your Tamil encoding)
    private let tgv_a: UnicodeScalar = UnicodeScalar(0x0B85)!
    private let tgm_pulli: UnicodeScalar = UnicodeScalar(0x0BCD)!
    private let tgg_xa: UnicodeScalar = UnicodeScalar(0x0B95)! // placeholder for KSHA
    private let tgg_sri: UnicodeScalar = UnicodeScalar(0x0BB8)! // placeholder for SRI
    private let tgg_ssa: UnicodeScalar = UnicodeScalar(0x0BB7)!
    private let tgc_ka: UnicodeScalar = UnicodeScalar(0x0B95)!
    private let tgc_ra: UnicodeScalar = UnicodeScalar(0x0BB0)!
    private let tgm_ii: UnicodeScalar = UnicodeScalar(0x0BC0)!
    private let tgg_sha: UnicodeScalar = UnicodeScalar(0x0BB7)!
    private let zwnj: UnicodeScalar = UnicodeScalar(0x200C)!
    
    // MARK: - State
    private var prevKeyCode: UnicodeScalar = UnicodeScalar(0)!
    
    // MARK: - Lookup Arrays (from your Objective-C code)
    
    private let consonants: [UnicodeScalar] = [
        0x0B95, 0x0B9A, 0x0B9F, 0x0BA4, 0x0BAA, 0x0BB1, 0x0B99,
        0x0B9E, 0x0BA3, 0x0BA8, 0x0BAE, 0x0BA9, 0x0BAF, 0x0BB0,
        0x0BB2, 0x0BB5, 0x0BB4, 0x0BB3, 0x0BB8, 0x0BB7, 0x0BB7,
        0x0B9C, 0x0BB9, 0x0B95 // last one is alt-ka
    ].compactMap(UnicodeScalar.init)
    
    private let vowels: [UnicodeScalar] = [
        0x0B86, 0x0B87, 0x0B88, 0x0B89, 0x0B8A, 0x0B8E, 0x0B8F,
        0x0B90, 0x0B92, 0x0B93, 0x0B94
    ].compactMap(UnicodeScalar.init)
    
    private let matras: [UnicodeScalar] = [
        0x0BBE, 0x0BBF, 0x0BC0, 0x0BC1, 0x0BC2, 0x0BC6, 0x0BC7,
        0x0BC8, 0x0BCA, 0x0BCB, 0x0BCC
    ].compactMap(UnicodeScalar.init)
    
    init() {
        prevKeyCode = UnicodeScalar(0)!
    }
    
    // MARK: - KeyTranslator Protocol
    
    func translateKey(
        keyCode: Int,
        isShifted: Bool,
        currentComposition: String
    ) async -> TranslationResult {
        
        guard let keyScalar = UnicodeScalar(keyCode) else {
            return TranslationResult(newComposition: currentComposition, displayText: "")
        }
        
        let compositionLength = currentComposition.count
        let prevChar: UnicodeScalar? = compositionLength > 0 ?
            currentComposition.unicodeScalars.last : nil
        let prevChar2: UnicodeScalar? = compositionLength > 1 ?
            Array(currentComposition.unicodeScalars)[compositionLength - 2] : nil
        
        let translatedString = translateFromKeyCode(
            keyCode: keyScalar,
            prevChar: prevChar ?? UnicodeScalar(0)!,
            prevChar2: prevChar2 ?? UnicodeScalar(0)!
        )
        
        prevKeyCode = keyScalar
        
        let newComposition = currentComposition + translatedString
        
        return TranslationResult(
            newComposition: newComposition,
            displayText: translatedString
        )
    }
    
    func processDelete(composition: String) async -> SimpleDeleteResult {
        if composition.isEmpty {
            return SimpleDeleteResult(newComposition: "", charactersToDelete: 1)
        }
        
        let newComposition = String(composition.dropLast())
        return SimpleDeleteResult(newComposition: newComposition, charactersToDelete: 1)
    }
    
    // MARK: - Tamil99 Logic (Converted from Objective-C)
    
    private func translateFromKeyCode(
        keyCode: UnicodeScalar,
        prevChar: UnicodeScalar,
        prevChar2: UnicodeScalar
    ) -> String {
        
        let prevCharIsConso = consonants.contains(prevChar)
        var result = ""
        
        // Handle conjuncts first
        if keyCode.value == tgg_xa.value {
            // KSHA = ka + pulli + ssa
            result = String(String.UnicodeScalarView([tgc_ka, tgm_pulli, tgg_ssa]))
        }
        else if keyCode.value == tgg_sri.value {
            // SRI = sha + pulli + ra + ii
            result = String(String.UnicodeScalarView([tgg_sha, tgm_pulli, tgc_ra, tgm_ii]))
        }
        else if prevChar2.value == tgc_ka.value &&
                prevChar.value == tgm_pulli.value &&
                keyCode.value == tgg_ssa.value {
            // Prevent ksha formation with ZWNJ
            result = String(String.UnicodeScalarView([zwnj, tgg_ssa]))
        }
        else if prevCharIsConso {
            // Previous character is a consonant
            if let vIndex = vowels.firstIndex(of: keyCode) {
                // Current key is a vowel - append corresponding matra
                result = String(matras[vIndex])
            }
            else if keyCode.value == tgv_a.value {
                // Do nothing for 'a' after consonant
                result = ""
            }
            else if let cIndex = consonants.firstIndex(of: keyCode) {
                // Current key is also a consonant - check for auto-pulli
                if shouldAddAutoPulli(prevChar: prevChar, currChar: keyCode) &&
                   prevKeyCode.value != tgv_a.value {
                    result = String(String.UnicodeScalarView([tgm_pulli, keyCode]))
                } else {
                    result = String(keyCode)
                }
            }
            else {
                result = String(keyCode)
            }
        }
        else if keyCode.value == tgm_pulli.value && prevChar.value == tgm_pulli.value {
            // Ignore repeated pulli
            result = ""
        }
        else {
            result = String(keyCode)
        }
        
        return result
    }
    
    private func shouldAddAutoPulli(prevChar: UnicodeScalar, currChar: UnicodeScalar) -> Bool {
        // Auto-pulli rules from your Tamil99 logic
        if prevChar == currChar {
            return true
        }
        
        // Specific consonant combinations that trigger auto-pulli
        let autoPulliPairs: [(UnicodeScalar, UnicodeScalar)] = [
            (UnicodeScalar(0x0BAE)!, UnicodeScalar(0x0BAA)!), // ma + pa
            (UnicodeScalar(0x0BA8)!, UnicodeScalar(0x0BA4)!), // na + ta
            (UnicodeScalar(0x0B9E)!, UnicodeScalar(0x0B9A)!), // nya + ca
            (UnicodeScalar(0x0BA3)!, UnicodeScalar(0x0B9F)!), // nna + tta
            (UnicodeScalar(0x0B99)!, UnicodeScalar(0x0B95)!), // nga + ka
            (UnicodeScalar(0x0BA9)!, UnicodeScalar(0x0BB1)!)  // nnna + rra
        ]
        
        return autoPulliPairs.contains { $0.0 == prevChar && $0.1 == currChar }
    }
    
    // MARK: - State Management
    
    func terminateComposition() {
        prevKeyCode = UnicodeScalar(0)!
    }
    
    func setPrevKeyCode(_ keyCode: UnicodeScalar) {
        prevKeyCode = keyCode
    }
}

// MARK: - Helper Extension

private extension String.UnicodeScalarView {
    init(_ scalars: [UnicodeScalar]) {
        self.init()
        for scalar in scalars {
            self.append(scalar)
        }
    }
}

