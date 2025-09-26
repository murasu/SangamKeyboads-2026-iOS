//
//  KeyboardLogicController.swift
//  KeyboardCore
//
//  Created by Muthu Nedumaran on 26/09/2025.
//

import UIKit
import Foundation

// MARK: - Delegate Protocol
public protocol KeyboardLogicDelegate: AnyObject {
    func insertText(_ text: String)
    func deleteBackward(count: Int)
    func performHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle)
    func updateKeyboardView()
    func getCurrentInterfaceStyle() -> UIUserInterfaceStyle
}

// MARK: - Theme Notification Protocol
public protocol KeyboardThemeObserver: AnyObject {
    func themeDidChange()
}

// MARK: - Main Controller
public class KeyboardLogicController {
    
    // MARK: - Properties
    public weak var delegate: KeyboardLogicDelegate?
    public weak var themeObserver: KeyboardThemeObserver?
    
    // MARK: - State Management
    public private(set) var currentLanguage: LanguageId {
        didSet {
            if currentLanguage != oldValue {
                updateTranslator()
                loadCurrentLayout()
            }
        }
    }
    
    public private(set) var keyboardState: KeyboardState = .normal {
        didSet {
            if keyboardState != oldValue {
                loadCurrentLayout()
                delegate?.updateKeyboardView()
            }
        }
    }
    
    public private(set) var isShiftLocked: Bool = false
    public private(set) var currentComposition: String = ""
    
    // MARK: - Internal Components
    private var currentTranslator: KeyTranslator?
    private var currentLayout: KeyboardLayout?
    private var themeManager: ThemeManager
    
    // MARK: - UserDefaults Observation
    private var themeObservation: NSKeyValueObservation?
    
    // MARK: - Initialization
    public init(language: LanguageId, appGroupIdentifier: String? = nil) {
        self.currentLanguage = language
        self.themeManager = ThemeManager(appGroupIdentifier: appGroupIdentifier)
        
        setupInitialState()
        observeThemeChanges()
    }
    
    deinit {
        themeObservation?.invalidate()
    }
    
    // MARK: - Setup Methods
    private func setupInitialState() {
        updateTranslator()
        loadCurrentLayout()
    }
    
    private func updateTranslator() {
        currentTranslator = KeyTranslatorFactory.getTranslator(for: currentLanguage)
    }
    
    private func loadCurrentLayout() {
        currentLayout = LayoutParser.loadLayout(for: currentLanguage, state: keyboardState)
        
        if currentLayout == nil {
            print("Warning: Failed to load layout for \(currentLanguage) - \(keyboardState)")
        } else {
            print("Successfully loaded layout for \(currentLanguage) - \(keyboardState)")
            // Notify delegate that layout changed and view needs updating
            delegate?.updateKeyboardView()
        }
    }
    
    // MARK: - Theme Management
    private func observeThemeChanges() {
        themeObservation = themeManager.observe(\.currentThemeId, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.themeObserver?.themeDidChange()
                self?.delegate?.updateKeyboardView()
            }
        }
    }
    
    public func getCurrentTheme() -> KeyboardTheme? {
        let interfaceStyle = delegate?.getCurrentInterfaceStyle() ?? .unspecified
        return themeManager.getCurrentTheme(for: interfaceStyle)
    }
    
    // MARK: - Public State Management
    public func setLanguage(_ language: LanguageId) {
        currentLanguage = language
    }
    
    public func getCurrentLayout() -> KeyboardLayout? {
        return currentLayout
    }
    
    // MARK: - Key Press Handling
    public func handleKeyPress(_ key: KeyboardKey) {
        let keyCode = key.keyCode
        
        switch keyCode {
        case -1: // Shift
            handleShift()
            
        case -2: // Mode change (123/ABC)
            handleModeChange()
            
        case -5: // Delete
            handleDelete()
            autoUnshift()
            
        case -6: // Globe
            handleGlobe()
            
        case 32: // Space
            handleSpace()
            autoUnshift()
            
        case 10: // Return
            handleReturn()
            
        default:
            // Regular character input
            handleCharacterInput(keyCode: keyCode, label: key.keyLabel)
            autoUnshift()
        }
    }
    
    // MARK: - Individual Key Handlers
    private func handleShift() {
        let previousState = keyboardState
        
        switch keyboardState {
        case .normal:
            keyboardState = .shifted
            isShiftLocked = false
            
        case .shifted:
            // Skip caps lock - go directly back to normal
            keyboardState = .normal
            isShiftLocked = false
            
        case .symbols:
            if hasShiftedSymbolsLayout() {
                keyboardState = .shiftedSymbols
            }
            
        case .shiftedSymbols:
            keyboardState = .symbols
        }
        
        // Only rebuild if switching between letter/symbol modes
        let needsRebuild = (previousState == .normal || previousState == .shifted) &&
                          (keyboardState == .symbols || keyboardState == .shiftedSymbols) ||
                          (previousState == .symbols || previousState == .shiftedSymbols) &&
                          (keyboardState == .normal || keyboardState == .shifted)
        
        if needsRebuild {
            loadCurrentLayout()
            delegate?.updateKeyboardView()
        }
        
        delegate?.performHapticFeedback(style: .light)
    }
    
    private func handleModeChange() {
        switch keyboardState {
        case .normal, .shifted:
            keyboardState = .symbols
            
        case .symbols:
            if hasShiftedSymbolsLayout() {
                keyboardState = .shiftedSymbols
            } else {
                keyboardState = .normal
            }
            
        case .shiftedSymbols:
            keyboardState = .normal
        }
        
        isShiftLocked = false
        delegate?.performHapticFeedback(style: .light)
    }
    
    private func handleDelete() {
        Task {
            guard let translator = currentTranslator else { return }
            
            let result = await translator.processDelete(composition: currentComposition)
            
            await MainActor.run {
                self.currentComposition = result.newComposition
                self.delegate?.deleteBackward(count: result.charactersToDelete)
            }
        }
        
        delegate?.performHapticFeedback(style: .light)
    }
    
    private func handleSpace() {
        delegate?.insertText(" ")
        currentComposition = ""
    }
    
    private func handleReturn() {
        delegate?.insertText("\n")
        currentComposition = ""
    }
    
    private func handleGlobe() {
        // This will be handled by the delegate (extension-specific)
        delegate?.performHapticFeedback(style: .light)
    }
    
    private func handleCharacterInput(keyCode: Int, label: String) {
        Task {
            guard let translator = currentTranslator else { return }
            
            let result = await translator.translateKey(
                keyCode: keyCode,
                isShifted: keyboardState == .shifted,
                currentComposition: currentComposition
            )
            
            await MainActor.run {
                self.currentComposition = result.newComposition
                self.delegate?.insertText(result.displayText)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func autoUnshift() {
        if keyboardState == .shifted && !isShiftLocked {
            keyboardState = .normal
        }
    }
    
    private func hasShiftedSymbolsLayout() -> Bool {
        // Languages with shifted symbols layouts
        let languagesWithShiftedSymbols: Set<LanguageId> = [
            .punjabi, .hindi, .bengali, .gujarati
            // Add other languages as needed
        ]
        return languagesWithShiftedSymbols.contains(currentLanguage)
    }
    
    // MARK: - Public Utility Methods
    public func getStateDisplayText() -> String {
        switch keyboardState {
        case .normal:
            return "Normal"
        case .shifted:
            return "Shift" // Removed caps lock text since it's disabled
        case .symbols:
            return "123"
        case .shiftedSymbols:
            return "#+="
        }
    }
    
    public func clearComposition() {
        currentComposition = ""
    }
    
    // MARK: - RTL Support
    public func isRightToLeft() -> Bool {
        return currentLanguage == .jawi || currentLanguage == .qwertyJawi
    }
}

// MARK: - Theme Manager Placeholder
private class ThemeManager: NSObject {
    @objc dynamic var currentThemeId: String = "default"
    private let userDefaults: UserDefaults
    private let themeIdKey = "selected_theme_id"
    
    init(appGroupIdentifier: String?) {
        if let groupId = appGroupIdentifier,
           let groupDefaults = UserDefaults(suiteName: groupId) {
            self.userDefaults = groupDefaults
        } else {
            self.userDefaults = UserDefaults.standard
        }
        
        super.init()
        loadCurrentTheme()
    }
    
    private func loadCurrentTheme() {
        currentThemeId = userDefaults.string(forKey: themeIdKey) ?? "default"
    }
    
    func getCurrentTheme(for interfaceStyle: UIUserInterfaceStyle) -> KeyboardTheme? {
        // Placeholder - will be implemented in next step
        return nil
    }
}

// MARK: - KeyboardTheme Placeholder
public struct KeyboardTheme {
    // Placeholder - will be implemented with theme system
}
