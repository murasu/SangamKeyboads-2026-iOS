//
//  LayoutParser.swift
//  SangamKeyboards
//
//  Created by Muthu Nedumaran on 24/09/2025.
//

import Foundation

public class LayoutParser {
    
    // MARK: - Public Methods
    public static func loadLayout(for languageId: LanguageId, state: KeyboardState = .normal) -> KeyboardLayout? {
        let filename = getLayoutFilename(for: languageId, state: state)
        
        guard let layout = loadLayoutFromFile(filename: filename) else {
            print("Failed to load layout: \(filename)")
            return nil
        }
        
        return layout
    }
    
    public static func getAllAvailableLayouts() -> [String] {
        let bundle = getKeyboardCoreBundle()
        
        guard let resourcePath = bundle.resourcePath else {
            print("Could not get resource path from bundle: \(bundle.bundlePath)")
            return []
        }
        
        guard let fileNames = try? FileManager.default.contentsOfDirectory(atPath: resourcePath) else {
            print("Could not list contents of resource path: \(resourcePath)")
            return []
        }
        
        let jsonFiles = fileNames.filter { $0.hasSuffix(".json") }
        print("Found JSON files: \(jsonFiles)")
        return jsonFiles
    }
    
    // MARK: - Private Helper Methods
    private static func getLayoutFilename(for languageId: LanguageId, state: KeyboardState) -> String {
        // For symbols states, use language family base name (shared symbols)
        if state == .symbols || state == .shiftedSymbols {
            let symbolsBaseName = getSymbolsBaseName(for: languageId)
            let suffix = getLayoutSuffix(for: state)
            return "\(symbolsBaseName)_\(suffix).json"
        }
        
        // For normal/shifted states, use the individual layout name
        let baseName = getBaseLayoutName(for: languageId)
        let suffix = getLayoutSuffix(for: state)
        
        if suffix.isEmpty {
            return "\(baseName).json"
        } else {
            return "\(baseName)_\(suffix).json"
        }
    }
    
    private static func getBaseLayoutName(for languageId: LanguageId) -> String {
        switch languageId {
        case .tamil:
            return "mn_tamil99"
        case .tamilAnjal, .malayalamAnjal, .kannadaAnjal, .teluguAnjal:
            return "mn_qwerty"  // All Anjal variants use QWERTY for normal/shifted
        case .malayalam:
            return "mn_malayalam"
        case .hindi:
            return "mn_hindi"
        case .bengali:
            return "mn_bangla"
        case .gujarati:
            return "mn_gujarati"
        case .kannada:
            return "mn_kannada"
        case .punjabi:
            return "mn_punjabi"
        case .telugu:
            return "mn_telugu"
        case .marathi:
            return "mn_marathi"
        case .oriya:
            return "mn_oriya"
        case .assamese:
            return "mn_assamese"
        case .sinhala:
            return "mn_sinhala"
        case .jawi:
            return "mn_jawi18"
        case .qwertyJawi:
            return "mn_qwerty_jawi"
        case .grantha:
            return "mn_grantha"
        case .sanskrit:
            return "mn_sanskrit"
        case .nepali:
            return "mn_nepali"
        case .qwerty:
            return "mn_qwerty"
        case .english:
            return "mn_qwerty"
        }
    }
    
    private static func getSymbolsBaseName(for languageId: LanguageId) -> String {
        switch languageId {
        // Tamil family - both Tamil99 and Tamil Anjal share mn_tamil_symbols.json
        case .tamil, .tamilAnjal:
            return "mn_tamil"
            
        // Malayalam family - both Malayalam and Malayalam Anjal share mn_malayalam_symbols.json
        case .malayalam, .malayalamAnjal:
            return "mn_malayalam"
            
        // Kannada family - both Kannada and Kannada Anjal share mn_kannada_symbols.json
        case .kannada, .kannadaAnjal:
            return "mn_kannada"
            
        // Telugu family - both Telugu and Telugu Anjal share mn_telugu_symbols.json
        case .telugu, .teluguAnjal:
            return "mn_telugu"
            
        // Languages with dedicated symbols
        case .hindi:
            return "mn_hindi"
        case .bengali:
            return "mn_bangla"
        case .gujarati:
            return "mn_gujarati"
        case .punjabi:
            return "mn_punjabi"
        case .marathi:
            return "mn_marathi"
        case .oriya:
            return "mn_oriya"
        case .assamese:
            return "mn_assamese"
        case .sinhala:
            return "mn_sinhala"
        case .grantha:
            return "mn_grantha"
            
        // QWERTY-based symbols
        case .jawi:
            return "mn_jawi18"
        case .qwertyJawi:
            return "mn_qwerty_jawi"
        case .sanskrit:
            return "mn_sanskrit"
        case .nepali:
            return "mn_nepali"
        case .qwerty, .english:
            return "mn_common"
        }
    }
    
    private static func getLayoutSuffix(for state: KeyboardState) -> String {
        switch state {
        case .normal:
            return ""
        case .shifted:
            return "shift"
        case .symbols:
            return "symbols"
        case .shiftedSymbols:
            return "symbols_shift"
        }
    }
    
    private static func loadLayoutFromFile(filename: String) -> KeyboardLayout? {
        let bundle = getKeyboardCoreBundle()
        
        // Remove .json extension for resource lookup
        let resourceName = filename.replacingOccurrences(of: ".json", with: "")
        
        guard let filePath = bundle.path(forResource: resourceName, ofType: "json") else {
            print("Layout file not found: \(filename) in bundle: \(bundle.bundlePath)")
            // Debug: List available resources
            if let resourcePath = bundle.resourcePath,
               let files = try? FileManager.default.contentsOfDirectory(atPath: resourcePath) {
                let jsonFiles = files.filter { $0.hasSuffix(".json") }
                print("Available JSON files: \(jsonFiles)")
            }
            return nil
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let layout = try JSONDecoder().decode(KeyboardLayout.self, from: data)
            return layout
        } catch {
            print("Error parsing layout file \(filename): \(error)")
            return nil
        }
    }
    
    // MARK: - Bundle Detection
    private static func getKeyboardCoreBundle() -> Bundle {
        // First try: Look for KeyboardCore framework by identifier
        if let bundle = Bundle(identifier: "com.murasu.Sangam.KeyboardCore") {
            print("Found KeyboardCore bundle by identifier")
            return bundle
        }
        
        // Second try: KeyboardCore framework is embedded in the main app
        if let frameworksPath = Bundle.main.path(forResource: "Frameworks", ofType: nil),
           let keyboardCorePath = Bundle(path: frameworksPath + "/KeyboardCore.framework") {
            print("Found KeyboardCore in main app frameworks")
            return keyboardCorePath
        }
        
        // Third try: Look for framework bundle in main bundle
        if let bundlePath = Bundle.main.path(forResource: "KeyboardCore", ofType: "framework"),
           let bundle = Bundle(path: bundlePath) {
            print("Found KeyboardCore framework in main bundle")
            return bundle
        }
        
        // Fourth try: Current bundle (if we're running from KeyboardCore itself)
        for bundle in Bundle.allBundles {
            if bundle.bundlePath.contains("KeyboardCore") {
                print("Found KeyboardCore in allBundles: \(bundle.bundlePath)")
                return bundle
            }
        }
        
        // Final fallback: Use main bundle and hope resources are there
        print("Using main bundle as fallback: \(Bundle.main.bundlePath)")
        return Bundle.main
    }
    
    // MARK: - Layout Validation
    public static func validateLayout(_ layout: KeyboardLayout) -> [String] {
        var issues: [String] = []
        
        // Check basic structure
        if layout.rows.isEmpty {
            issues.append("Layout has no rows")
        }
        
        for (rowIndex, row) in layout.rows.enumerated() {
            if row.keys.isEmpty {
                issues.append("Row \(rowIndex) has no keys")
                continue
            }
            
            // Check width calculations
            let totalWidth = row.keys.compactMap { key in
                Double(key.keyWidth?.replacingOccurrences(of: "%", with: "") ?? layout.keyWidth.replacingOccurrences(of: "%", with: ""))
            }.reduce(0, +)
            
            if totalWidth > 101.0 { // Allow 1% margin for rounding
                issues.append("Row \(rowIndex) width exceeds 100%: \(totalWidth)%")
            }
            
            // Check for invalid key codes
            for (keyIndex, key) in row.keys.enumerated() {
                if key.keyCode == 0 && !key.keyLabel.isEmpty {
                    issues.append("Row \(rowIndex), Key \(keyIndex) has keyCode 0 but non-empty label")
                }
            }
        }
        
        return issues
    }
    
    // MARK: - Debug Utilities
    public static func debugLayout(_ layout: KeyboardLayout, name: String = "Unknown") {
        print("=== Layout Debug: \(name) ===")
        print("Default key width: \(layout.keyWidth)")
        print("Horizontal gap: \(layout.horizontalGap)")
        print("Total rows: \(layout.rows.count)")
        
        for (rowIndex, row) in layout.rows.enumerated() {
            let rowId = row.rowId ?? "nil"
            let totalWidth = row.keys.compactMap { key in
                Double(key.keyWidth?.replacingOccurrences(of: "%", with: "") ?? layout.keyWidth.replacingOccurrences(of: "%", with: ""))
            }.reduce(0, +)
            
            print("\nRow \(rowIndex) (id: \(rowId)):")
            print("  Height: \(row.keyHeight)")
            print("  Keys: \(row.keys.count)")
            print("  Total width: \(String(format: "%.2f", totalWidth))%")
            
            for (keyIndex, key) in row.keys.enumerated() {
                let width = key.keyWidth ?? layout.keyWidth
                let modifier = key.isModifier == true ? " [MOD]" : ""
                print("    \(keyIndex): '\(key.keyLabel)' (code: \(key.keyCode)) width: \(width)\(modifier)")
            }
        }
        
        // Show validation issues
        let issues = validateLayout(layout)
        if !issues.isEmpty {
            print("\n⚠️ Layout Issues:")
            for issue in issues {
                print("  - \(issue)")
            }
        } else {
            print("\n✅ Layout validation passed")
        }
    }
}

