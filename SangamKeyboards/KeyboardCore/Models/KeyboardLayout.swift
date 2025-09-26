//
//  KeyboardLayout.swift
//  SangamKeyboards
//
//  Created by Muthu Nedumaran on 24/09/2025.
//

import Foundation

// MARK: - Main Layout Structure
public struct KeyboardLayout: Codable {
    public let keyWidth: String
    public let horizontalGap: String
    public let rows: [KeyboardRow]
    
    public init(keyWidth: String, horizontalGap: String, rows: [KeyboardRow]) {
        self.keyWidth = keyWidth
        self.horizontalGap = horizontalGap
        self.rows = rows
    }
}

public struct KeyboardRow: Codable {
    public let verticalGap: String?
    public let keyHeight: String
    public let rowId: String?
    public let keys: [KeyboardKey]
    
    public init(verticalGap: String?, keyHeight: String, rowId: String?, keys: [KeyboardKey]) {
        self.verticalGap = verticalGap
        self.keyHeight = keyHeight
        self.rowId = rowId
        self.keys = keys
    }
}

public struct KeyboardKey: Codable {
    // Primary key identification - supports both formats
    public let codes: String?           // Tamil99 format: "2950", "-1", "32"
    public let unichar: String?         // Hindi format: "ौ", "ै"
    
    // Display information
    public let keyLabel: String         // Tamil99: "ஆ", Hindi: "" (empty)
    
    // Layout properties
    public let keyWidth: String?
    public let horizontalGap: String?
    public let keyEdgeFlags: String?
    
    // Behavior properties
    public let isModifier: Bool?
    public let isShifted: Bool?
    public let isRepeatable: Bool?
    
    // Additional properties for advanced layouts
    public let popupCodes: String?      // Hindi format: "ौऔ"
    
    // MARK: - Computed Properties
    
    /// Returns the key code as an integer, supporting both codes and unichar formats
    public var keyCode: Int {
        // Priority 1: Use codes field (Tamil99 format)
        if let codes = codes, let codeValue = Int(codes) {
            return codeValue
        }
        
        // Priority 2: Use unichar field (Hindi format)
        if let unichar = unichar, let firstScalar = unichar.unicodeScalars.first {
            return Int(firstScalar.value)
        }
        
        // Fallback
        return 0
    }
    
    /// Returns the display text for the key, supporting both formats
    public var displayText: String {
        // Priority 1: Use keyLabel if not empty (Tamil99 format)
        if !keyLabel.isEmpty {
            return keyLabel
        }
        
        // Priority 2: Use unichar if available (Hindi format)
        if let unichar = unichar, !unichar.isEmpty {
            return unichar
        }
        
        // Fallback to empty string
        return ""
    }
    
    /// Returns popup characters if available
    public var popupCharacters: [String] {
        guard let popupCodes = popupCodes else { return [] }
        return popupCodes.map { String($0) }
    }
    
    /// Determines if this is a special/modifier key
    public var isSpecialKey: Bool {
        // Check if it's explicitly marked as modifier
        if isModifier == true {
            return true
        }
        
        // Check for special key codes (negative values)
        if let codes = codes, let codeValue = Int(codes), codeValue < 0 {
            return true
        }
        
        // Check for special labels
        return keyLabel.hasPrefix("#") || keyLabel.contains("⬆") || keyLabel.contains("⌫")
    }
    
    // MARK: - Initialization
    public init(
        codes: String? = nil,
        unichar: String? = nil,
        keyLabel: String,
        keyWidth: String? = nil,
        horizontalGap: String? = nil,
        keyEdgeFlags: String? = nil,
        isModifier: Bool? = nil,
        isShifted: Bool? = nil,
        isRepeatable: Bool? = nil,
        popupCodes: String? = nil
    ) {
        self.codes = codes
        self.unichar = unichar
        self.keyLabel = keyLabel
        self.keyWidth = keyWidth
        self.horizontalGap = horizontalGap
        self.keyEdgeFlags = keyEdgeFlags
        self.isModifier = isModifier
        self.isShifted = isShifted
        self.isRepeatable = isRepeatable
        self.popupCodes = popupCodes
    }
}

// MARK: - Helper Extensions

extension KeyboardKey {
    /// Debug description showing key information
    public var debugDescription: String {
        let codeInfo = codes ?? "unichar:\(unichar ?? "nil")"
        let display = displayText.isEmpty ? "(empty)" : displayText
        return "Key[\(codeInfo)] = '\(display)'"
    }
    
    /// Returns true if this key represents a character that can be typed
    public var isCharacterKey: Bool {
        return !isSpecialKey && !displayText.isEmpty
    }
    
    /// Returns true if this key is a space key
    public var isSpaceKey: Bool {
        return keyCode == 32 || keyLabel == "#space"
    }
    
    /// Returns true if this key is a return/enter key
    public var isReturnKey: Bool {
        return keyCode == 10 || keyLabel == "#return"
    }
}

