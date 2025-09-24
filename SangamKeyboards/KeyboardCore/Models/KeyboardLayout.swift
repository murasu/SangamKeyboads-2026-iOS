//
//  KeyboardLayout.swift
//  SangamKeyboards
//
//  Created by Muthu Nedumaran on 24/09/2025.
//

import Foundation

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
    public let verticalGap: String
    public let keyHeight: String
    public let rowId: String?
    public let keys: [KeyboardKey]
    
    public init(verticalGap: String, keyHeight: String, rowId: String?, keys: [KeyboardKey]) {
        self.verticalGap = verticalGap
        self.keyHeight = keyHeight
        self.rowId = rowId
        self.keys = keys
    }
}

public struct KeyboardKey: Codable {
    public let codes: String?
    public let unichar: String?
    public let keyLabel: String
    public let keyWidth: String?
    public let horizontalGap: String?
    public let keyEdgeFlags: String?
    public let isModifier: Bool?
    public let isShifted: Bool?
    public let isRepeatable: Bool?
    public let popupCodes: String?
    public let popupCharacters: String?
    
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
        popupCodes: String? = nil,
        popupCharacters: String? = nil
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
        self.popupCharacters = popupCharacters
    }
    
    public var keyCode: Int {
        if let codes = codes {
            return Int(codes) ?? 0
        }
        if let unichar = unichar {
            return Int(unichar) ?? 0
        }
        return 0
    }
}
