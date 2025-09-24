//
//  LayoutParser.swift
//  SangamKeyboards
//
//  Created by Muthu Nedumaran on 24/09/2025.
//

import Foundation

public enum KeyboardState {
    case normal
    case shifted
    case symbols
    case shiftedSymbols
}

public class LayoutParser {
    
    public static func loadLayout(for languageId: LanguageId, state: KeyboardState = .normal) -> KeyboardLayout? {
        let fileName: String
        
        switch languageId {
        case .tamil:
            switch state {
            case .normal:
                fileName = "mn_tamil99"
            case .shifted:
                fileName = "mn_tamil99_shift"
            case .symbols:
                fileName = "mn_tamil_symbols"
            case .shiftedSymbols:
                fileName = "mn_tamil_symbols_shift" // If this exists
            }
            
        case .punjabi:
            switch state {
            case .normal:
                fileName = "mn_punjabi"
            case .shifted:
                fileName = "mn_punjabi_shift"
            case .symbols:
                fileName = "mn_punjabi_symbols"
            case .shiftedSymbols:
                fileName = "mn_punjabi_symbols_shift" // Punjabi has this
            }
            
        default:
            // Generic pattern for other languages
            let baseFileName = "mn_\(languageId.rawValue)"
            switch state {
            case .normal:
                fileName = baseFileName
            case .shifted:
                fileName = "\(baseFileName)_shift"
            case .symbols:
                fileName = "\(baseFileName)_symbols"
            case .shiftedSymbols:
                fileName = "\(baseFileName)_symbols_shift"
            }
        }
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            // Fallback: if shifted symbols doesn't exist, use regular symbols
            if state == .shiftedSymbols {
                return loadLayout(for: languageId, state: KeyboardState.symbols) // Use full type name
            }
            print("Could not load layout: \(fileName).json")
            return nil
        }
        
        guard let jsonData = try? Data(contentsOf: url) else {
            return nil
        }
        
        return try? JSONDecoder().decode(KeyboardLayout.self, from: jsonData)
    }
}
