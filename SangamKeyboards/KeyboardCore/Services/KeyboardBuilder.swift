//
//  KeyboardBuilder.swift
//  SangamKeyboards
//
//  Created by Muthu Nedumaran on 24/09/2025.
//

import UIKit

public class KeyboardBuilder {
    
    private static let debugMode = false // Disable debug to reduce console noise
    
    // MARK: - Color Configuration
    private struct KeyboardColors {
        // Regular key colors
        static let lightModeRegularBackground = UIColor.white
        static let darkModeRegularBackground = UIColor.systemGray5
        
        // Modifier key colors
        static let lightModeModifierBackground = UIColor.systemGray4
        static let darkModeModifierBackground = UIColor.systemGray4
        
        // Text colors
        static let lightModeTextColor = UIColor.black
        static let darkModeTextColor = UIColor.white
        
        // Border colors
        static let lightModeBorderColor = UIColor.systemGray3
        static let darkModeBorderColor = UIColor.systemGray2
    }
    
    // MARK: - Color Helper Methods
    private static func getCurrentInterfaceStyle(from view: UIView) -> UIUserInterfaceStyle {
        return view.traitCollection.userInterfaceStyle
    }
    
    private static func getRegularKeyBackgroundColor(for interfaceStyle: UIUserInterfaceStyle) -> UIColor {
        switch interfaceStyle {
        case .dark:
            return KeyboardColors.darkModeRegularBackground
        case .light, .unspecified:
            return KeyboardColors.lightModeRegularBackground
        @unknown default:
            return KeyboardColors.lightModeRegularBackground
        }
    }
    
    private static func getModifierKeyBackgroundColor(for interfaceStyle: UIUserInterfaceStyle) -> UIColor {
        switch interfaceStyle {
        case .dark:
            return KeyboardColors.darkModeModifierBackground
        case .light, .unspecified:
            return KeyboardColors.lightModeModifierBackground
        @unknown default:
            return KeyboardColors.lightModeModifierBackground
        }
    }
    
    private static func getTextColor(for interfaceStyle: UIUserInterfaceStyle) -> UIColor {
        switch interfaceStyle {
        case .dark:
            return KeyboardColors.darkModeTextColor
        case .light, .unspecified:
            return KeyboardColors.lightModeTextColor
        @unknown default:
            return KeyboardColors.lightModeTextColor
        }
    }
    
    private static func getBorderColor(for interfaceStyle: UIUserInterfaceStyle) -> UIColor {
        switch interfaceStyle {
        case .dark:
            return KeyboardColors.darkModeBorderColor
        case .light, .unspecified:
            return KeyboardColors.lightModeBorderColor
        @unknown default:
            return KeyboardColors.lightModeBorderColor
        }
    }
    
    public static func buildKeyboard(
        layout: KeyboardLayout,
        containerView: UIView,
        keyPressHandler: @escaping (KeyboardKey) -> Void
    ) -> UIView {
        
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.distribution = .fillEqually // Changed from fillProportionally to fillEqually
        mainStack.spacing = 6
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        for row in layout.rows {
            // Skip iPad-specific rows for now
            if row.rowId == "pad" { continue }
            
            let rowView = createRowView(
                row: row,
                defaultKeyWidth: layout.keyWidth,
                containerView: containerView,
                keyPressHandler: keyPressHandler
            )
            
            mainStack.addArrangedSubview(rowView)
        }
        
        return mainStack
    }
    
    private static func createRowView(
        row: KeyboardRow,
        defaultKeyWidth: String,
        containerView: UIView,
        keyPressHandler: @escaping (KeyboardKey) -> Void
    ) -> UIView {
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 3
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        // Get raw widths from JSON (don't normalize to 100%)
        var keyWidths: [CGFloat] = []
        
        for key in row.keys {
            let keyWidthString = key.keyWidth ?? defaultKeyWidth
            let width = parsePercentage(keyWidthString)
            keyWidths.append(width)
        }
        
        // Don't normalize - use the actual percentages from JSON
        // The JSON percentages are designed to work with spacing/margins
        
        var widthConstraints: [NSLayoutConstraint] = []
        
        // Create buttons and add to stack
        for (index, key) in row.keys.enumerated() {
            let button = createKeyButton(key: key, containerView: containerView, handler: keyPressHandler)
            stackView.addArrangedSubview(button)
            
            // Set width constraint relative to the first button
            if index == 0 {
                // First button - no relative constraint needed
                continue
            } else {
                // Calculate width ratio relative to first button
                let firstButtonWidth = keyWidths[0]
                let currentButtonWidth = keyWidths[index]
                let ratio = currentButtonWidth / firstButtonWidth
                
                let firstButton = stackView.arrangedSubviews[0]
                let widthConstraint = button.widthAnchor.constraint(
                    equalTo: firstButton.widthAnchor,
                    multiplier: ratio
                )
                widthConstraint.priority = UILayoutPriority(999)
                widthConstraints.append(widthConstraint)
            }
        }
        
        NSLayoutConstraint.activate(widthConstraints)
        
        return stackView
    }
    
    private static func createKeyButton(
        key: KeyboardKey,
        containerView: UIView,
        handler: @escaping (KeyboardKey) -> Void
    ) -> UIButton {
        
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Detect current interface style
        let interfaceStyle = getCurrentInterfaceStyle(from: containerView)
        
        // Set colors based on interface style and key type
        if key.isModifier == true {
            button.backgroundColor = getModifierKeyBackgroundColor(for: interfaceStyle)
        } else {
            button.backgroundColor = getRegularKeyBackgroundColor(for: interfaceStyle)
        }
        
        // Set consistent styling
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 1
        button.layer.borderColor = getBorderColor(for: interfaceStyle).cgColor
        
        // Set text color
        let textColor = getTextColor(for: interfaceStyle)
        button.setTitleColor(textColor, for: .normal)
        
        if debugMode {
            print("Key '\(key.keyLabel)' - Interface Style: \(interfaceStyle.rawValue), Background: \(button.backgroundColor?.description ?? "nil"), Text: \(textColor.description)")
        }
        
        // Handle special keys with SF Symbols or text
        if isSpecialKey(key) {
            configureSpecialKey(button: button, key: key, interfaceStyle: interfaceStyle)
        } else {
            // Regular text key - use the new displayText property
            let displayLabel = localizeKeyLabel(key.displayText)
            button.setTitle(displayLabel, for: .normal)
            
            let fontSize = getFontSize(for: key)
            button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
            
            // Handle Tamil characters that might need larger font
            if isTamilCharacter(displayLabel) {
                button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize * 1.1)
            }
        }
        
        // Add touch handling with visual feedback
        button.addAction(UIAction { _ in
            // Haptic feedback for special keys
            if key.isModifier == true {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
            
            // Visual feedback with proper color restoration
            UIView.animate(withDuration: 0.1, animations: {
                button.backgroundColor = button.backgroundColor?.withAlphaComponent(0.5)
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    // Restore colors based on current interface style
                    let currentInterfaceStyle = getCurrentInterfaceStyle(from: containerView)
                    
                    if key.isModifier == true {
                        button.backgroundColor = getModifierKeyBackgroundColor(for: currentInterfaceStyle)
                    } else {
                        button.backgroundColor = getRegularKeyBackgroundColor(for: currentInterfaceStyle)
                    }
                }
            }
            
            handler(key)
        }, for: .touchUpInside)
        
        return button
    }
    
    private static func isSpecialKey(_ key: KeyboardKey) -> Bool {
        let specialKeyCodes: Set<Int> = [-1, -2, -5, -6] // shift, mode, delete, globe
        let hasSpecialCode = specialKeyCodes.contains(key.keyCode)
        let hasHashLabel = key.keyLabel.hasPrefix("#")
        let isModifierKey = key.isModifier == true
        
        let isSpecial = hasSpecialCode || hasHashLabel || isModifierKey
        
        if isSpecial && debugMode {
            print("Key identified as special: code=\(key.keyCode), label='\(key.keyLabel)', isModifier=\(key.isModifier ?? false)")
            print("  - hasSpecialCode: \(hasSpecialCode)")
            print("  - hasHashLabel: \(hasHashLabel)")
            print("  - isModifierKey: \(isModifierKey)")
        }
        
        return isSpecial
    }
    
    private static func configureSpecialKey(button: UIButton, key: KeyboardKey, interfaceStyle: UIUserInterfaceStyle) {
        if debugMode {
            print("Configuring special key: code=\(key.keyCode), label='\(key.keyLabel)', isModifier=\(key.isModifier ?? false)")
        }
        
        // Clear any existing content
        button.setTitle("", for: .normal)
        button.setImage(nil, for: .normal)
        
        // Get appropriate colors for current interface style
        let textColor = getTextColor(for: interfaceStyle)
        
        // Configure based on key type
        switch key.keyCode {
        case -1: // Shift - use SF Symbol
            if let shiftImage = UIImage(systemName: "shift") {
                button.setImage(shiftImage, for: .normal)
                button.tintColor = textColor
                button.imageView?.contentMode = .scaleAspectFit
                
                // Set appropriate size for the symbol
                let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
                button.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
                
                if debugMode { print("✅ Set SF Symbol 'shift' for key \(key.keyCode)") }
            } else {
                // Fallback to text if SF Symbol isn't available
                button.setTitle("⬆", for: .normal)
                button.setTitleColor(textColor, for: .normal)
                if debugMode { print("⚠️ SF Symbol 'shift' not available, using fallback") }
            }
            
        case -5: // Delete - use SF Symbol
            if let deleteImage = UIImage(systemName: "delete.left") {
                button.setImage(deleteImage, for: .normal)
                button.tintColor = textColor
                button.imageView?.contentMode = .scaleAspectFit
                
                // Set appropriate size for the symbol
                let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
                button.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
                
                if debugMode { print("✅ Set SF Symbol 'delete.left' for key \(key.keyCode)") }
            } else {
                // Fallback to text if SF Symbol isn't available
                button.setTitle("⌫", for: .normal)
                button.setTitleColor(textColor, for: .normal)
                if debugMode { print("⚠️ SF Symbol 'delete.left' not available, using fallback") }
            }
            
        default:
            // Use regular text for all other keys (123, space, return, globe, etc.)
            let displayText = getDisplayTextForKey(key)
            button.setTitle(displayText, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: getFontSize(for: key), weight: .medium)
            button.setTitleColor(textColor, for: .normal)
            
            if debugMode {
                print("Set text '\(displayText)' for key \(key.keyCode) with color \(textColor.description)")
            }
        }
        
        // Store key reference for state-aware updates
        button.tag = key.keyCode
    }
    
    private static func getDisplayTextForKey(_ key: KeyboardKey) -> String {
        switch key.keyCode {
        case -6: // Globe (should be removed from layout)
            return "🌐"
        case -2: // Mode change (123/ABC)
            return key.keyLabel == "123" ? "123" : "ABC"
        case 32: // Space
            return "space"
        case 10: // Return
            return "return"
        default:
            return key.keyLabel.replacingOccurrences(of: "#", with: "")
        }
    }
    
    // Method to update shift key appearance
    public static func updateShiftKeyAppearance(button: UIButton, shifted: Bool, locked: Bool = false, interfaceStyle: UIUserInterfaceStyle) {
        guard button.tag == -1 else { return } // Only for shift keys
        
        // Clear any existing title
        button.setTitle("", for: .normal)
        
        // Get appropriate color for current interface style
        let textColor = getTextColor(for: interfaceStyle)
        
        // Use shift symbol based on state (no caps lock support)
        let symbolName = shifted ? "shift.fill" : "shift"
        
        if let shiftImage = UIImage(systemName: symbolName) {
            button.setImage(shiftImage, for: .normal)
            button.tintColor = textColor
            
            // Set appropriate size for the symbol
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
            button.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
        }
        
        // Update background color for visual feedback
        if shifted {
            let baseColor = getModifierKeyBackgroundColor(for: interfaceStyle)
            button.backgroundColor = baseColor.withAlphaComponent(0.8)
        } else {
            button.backgroundColor = getModifierKeyBackgroundColor(for: interfaceStyle)
        }
    }
    
    private static func parsePercentage(_ percentString: String) -> CGFloat {
        let cleanString = percentString.replacingOccurrences(of: "%", with: "")
        return CGFloat(Double(cleanString) ?? 10.0)
    }
    
    private static func parsePixelValue(_ pixelString: String, defaultValue: CGFloat) -> CGFloat {
        let cleanString = pixelString.replacingOccurrences(of: "px", with: "")
        return CGFloat(Double(cleanString) ?? Double(defaultValue))
    }
    
    private static func localizeKeyLabel(_ label: String) -> String {
        // Handle special labels that start with #
        switch label {
        case "#space":
            return "space"
        case "#return":
            return "return"
        case "⬆️", "#shift":
            return "" // Will be handled by special key logic
        case "#delete":
            return "" // Will be handled by special key logic
        case "#123", "#ABC":
            return "" // Will be handled by special key logic
        case "#globe":
            return "" // Will be handled by special key logic
        default:
            // For regular characters (including Hindi, Tamil, etc.), return as-is
            return label
        }
    }
    
    private static func getFontSize(for key: KeyboardKey) -> CGFloat {
        if key.isModifier == true {
            if key.keyLabel.count > 2 {
                return 12.0 // For labels like "space", "return"
            } else {
                return 16.0 // For symbols
            }
        } else {
            return 18.0 // Normal character keys
        }
    }
    
    private static func isTamilCharacter(_ text: String) -> Bool {
        guard let firstScalar = text.unicodeScalars.first else { return false }
        return (0x0B80...0x0BFF).contains(firstScalar.value)
    }
    
    // Method to find and update all shift keys in a view hierarchy
    public static func updateAllShiftKeys(in view: UIView, shifted: Bool, locked: Bool = false) {
        let interfaceStyle = getCurrentInterfaceStyle(from: view)
        for subview in view.subviews {
            if let button = subview as? UIButton, button.tag == -1 {
                updateShiftKeyAppearance(button: button, shifted: shifted, locked: locked, interfaceStyle: interfaceStyle)
            }
            updateAllShiftKeys(in: subview, shifted: shifted, locked: locked)
        }
    }
    
    // Method to update all key colors when interface style changes
    public static func updateKeyboardColors(in view: UIView, interfaceStyle: UIUserInterfaceStyle) {
        for subview in view.subviews {
            if let button = subview as? UIButton {
                // Update colors based on key type
                if button.tag == -1 || button.tag == -2 || button.tag == -5 || button.tag == -6 {
                    // Modifier key
                    button.backgroundColor = getModifierKeyBackgroundColor(for: interfaceStyle)
                } else {
                    // Regular key
                    button.backgroundColor = getRegularKeyBackgroundColor(for: interfaceStyle)
                }
                
                // Update text/tint color
                let textColor = getTextColor(for: interfaceStyle)
                button.setTitleColor(textColor, for: .normal)
                button.tintColor = textColor
                
                // Update border color
                button.layer.borderColor = getBorderColor(for: interfaceStyle).cgColor
            }
            
            // Recursively update subviews
            updateKeyboardColors(in: subview, interfaceStyle: interfaceStyle)
        }
    }
    
    // Debug method
    public static func debugLayout(_ layout: KeyboardLayout) {
        print("=== Layout Debug ===")
        print("Default key width: \(layout.keyWidth)")
        print("Horizontal gap: \(layout.horizontalGap)")
        
        for (rowIndex, row) in layout.rows.enumerated() {
            print("\nRow \(rowIndex):")
            print("  Height: \(row.keyHeight)")
            print("  Keys: \(row.keys.count)")
            
            let totalWidth = row.keys.reduce(0.0) { total, key in
                let width = key.keyWidth ?? layout.keyWidth
                return total + parsePercentage(width)
            }
            print("  Total width: \(totalWidth)%")
            
            for (keyIndex, key) in row.keys.enumerated() {
                let width = key.keyWidth ?? layout.keyWidth
                print("    Key \(keyIndex): '\(key.keyLabel)' width: \(width)")
            }
        }
    }
}

