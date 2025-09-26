//
//  KeyboardState.swift
//  SangamKeyboards
//
//  Created by Muthu Nedumaran on 26/09/2025.
//

import Foundation

public enum KeyboardState: String, CaseIterable, Codable {
    case normal = "normal"
    case shifted = "shifted"
    case symbols = "symbols"
    case shiftedSymbols = "shifted_symbols"
    
    public var displayName: String {
        switch self {
        case .normal:
            return "ABC"
        case .shifted:
            return "ABC"
        case .symbols:
            return "123"
        case .shiftedSymbols:
            return "#+="
        }
    }
    
    public var isShiftedState: Bool {
        switch self {
        case .shifted, .shiftedSymbols:
            return true
        case .normal, .symbols:
            return false
        }
    }
    
    public var isSymbolState: Bool {
        switch self {
        case .symbols, .shiftedSymbols:
            return true
        case .normal, .shifted:
            return false
        }
    }
}

