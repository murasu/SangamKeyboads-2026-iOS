//
//  KeyboardBuilder.swift
//  SangamKeyboards
//
//  Created by Muthu Nedumaran on 24/09/2025.
//

import UIKit

public class KeyboardBuilder {
    
    private static let debugMode = true // Enable debug to see what's happening
    
    public static func buildKeyboard(
        layout: KeyboardLayout,
        containerView: UIView,
        keyPressHandler: @escaping (KeyboardKey) -> Void
    ) -> UIView {
        
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.distribution = .fillProportionally
        mainStack.spacing = 6
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        for row in layout.rows {
            // Skip iPad-specific rows for now
            if row.rowId == "pad" { continue }
            
            let rowView = createRowView(
                row: row,
                defaultKeyWidth: layout.keyWidth,
                keyPressHandler: keyPressHandler
            )
            
            mainStack.addArrangedSubview(rowView)
        }
        
        return mainStack
    }
    
    private static func createRowView(
        row: KeyboardRow,
        defaultKeyWidth: String,
        keyPressHandler: @escaping (KeyboardKey) -> Void
    ) -> UIView {
        
        let rowContainer = UIView()
        rowContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Calculate the total width needed and available space
        let horizontalMargin: CGFloat = 8 // Total margin (4 on each side)
        let keySpacing: CGFloat = 3 // Space between keys
        let totalSpacing = keySpacing * CGFloat(row.keys.count - 1)
        
        var previousButton: UIView? = nil
        var buttonConstraints: [NSLayoutConstraint] = []
        
        // Calculate width percentages and normalize them
        var keyWidths: [CGFloat] = []
        var totalRequestedWidth: CGFloat = 0
        
        for key in row.keys {
            let keyWidthString = key.keyWidth ?? defaultKeyWidth
            let width = parsePercentage(keyWidthString)
            keyWidths.append(width)
            totalRequestedWidth += width
        }
        
        // Normalize widths to fit within available space
        let availableWidth: CGFloat = 100 // Percentage
        let scaleFactor = totalRequestedWidth > 0 ? availableWidth / totalRequestedWidth : 1.0
        
        for i in 0..<keyWidths.count {
            keyWidths[i] = keyWidths[i] * scaleFactor
        }
        
        for (index, key) in row.keys.enumerated() {
            let button = createKeyButton(key: key, handler: keyPressHandler)
            rowContainer.addSubview(button)
            
            let keyWidthPercentage = keyWidths[index]
            
            // Vertical constraints (full height of row)
            buttonConstraints.append(contentsOf: [
                button.topAnchor.constraint(equalTo: rowContainer.topAnchor),
                button.bottomAnchor.constraint(equalTo: rowContainer.bottomAnchor)
            ])
            
            // Width constraint as percentage of available width (minus margins and spacing)
            let widthConstraint = button.widthAnchor.constraint(
                equalTo: rowContainer.widthAnchor,
                multiplier: keyWidthPercentage / 100.0,
                constant: -(horizontalMargin + totalSpacing) * (keyWidthPercentage / 100.0)
            )
            buttonConstraints.append(widthConstraint)
            
            // Horizontal positioning
            if index == 0 {
                // First button: align to leading edge with margin
                buttonConstraints.append(
                    button.leadingAnchor.constraint(equalTo: rowContainer.leadingAnchor, constant: horizontalMargin / 2)
                )
            } else {
                // Subsequent buttons: position after previous with spacing
                buttonConstraints.append(
                    button.leadingAnchor.constraint(equalTo: previousButton!.trailingAnchor, constant: keySpacing)
                )
            }
            
            // Last button: ensure it doesn't exceed trailing edge
            if index == row.keys.count - 1 {
                let trailingConstraint = button.trailingAnchor.constraint(
                    lessThanOrEqualTo: rowContainer.trailingAnchor,
                    constant: -horizontalMargin / 2
                )
                trailingConstraint.priority = UILayoutPriority(999)
                buttonConstraints.append(trailingConstraint)
            }
            
            previousButton = button
        }
        
        // Set row height
        let rowHeight = parsePixelValue(row.keyHeight, defaultValue: 40.0)
        buttonConstraints.append(
            rowContainer.heightAnchor.constraint(equalToConstant: rowHeight)
        )
        
        NSLayoutConstraint.activate(buttonConstraints)
        
        return rowContainer
    }
    
    private static func createKeyButton(
        key: KeyboardKey,
        handler: @escaping (KeyboardKey) -> Void
    ) -> UIButton {
        
        let button = UIButton(type: .system)
        button.backgroundColor = key.isModifier == true ? UIColor.systemGray4 : UIColor.white
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray3.cgColor
        button.setTitleColor(.black, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Handle special keys with SF Symbols or text
        if isSpecialKey(key) {
            configureSpecialKey(button: button, key: key)
        } else {
            // Regular text key
            let displayLabel = localizeKeyLabel(key.keyLabel)
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
            
            // Visual feedback
            UIView.animate(withDuration: 0.1, animations: {
                button.backgroundColor = button.backgroundColor?.withAlphaComponent(0.5)
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    button.backgroundColor = key.isModifier == true ? UIColor.systemGray4 : UIColor.white
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
    
    private static func configureSpecialKey(button: UIButton, key: KeyboardKey) {
        if debugMode {
            print("Configuring special key: code=\(key.keyCode), label='\(key.keyLabel)', isModifier=\(key.isModifier ?? false)")
        }
        
        // Set background colors - keys with # prefix or specific codes should be gray (modifier color)
        let shouldBeGray = key.keyLabel.hasPrefix("#") || key.keyCode == -1 || key.keyCode == -5 || key.keyCode == -2
        if shouldBeGray {
            button.backgroundColor = UIColor.systemGray4
        }
        
        // Clear any existing content
        button.setTitle("", for: .normal)
        button.setImage(nil, for: .normal)
        
        // Configure based on key type
        switch key.keyCode {
        case -1: // Shift - use SF Symbol
            if let shiftImage = UIImage(systemName: "shift") {
                button.setImage(shiftImage, for: .normal)
                button.tintColor = .black
                button.imageView?.contentMode = .scaleAspectFit
                
                // Set appropriate size for the symbol
                let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
                button.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
                
                if debugMode { print("✓ Set SF Symbol 'shift' for key \(key.keyCode)") }
            } else {
                // Fallback to text if SF Symbol isn't available
                button.setTitle("⬆", for: .normal)
                button.setTitleColor(.black, for: .normal)
                if debugMode { print("⚠ SF Symbol 'shift' not available, using fallback") }
            }
            
        case -5: // Delete - use SF Symbol
            if let deleteImage = UIImage(systemName: "delete.left") {
                button.setImage(deleteImage, for: .normal)
                button.tintColor = .black
                button.imageView?.contentMode = .scaleAspectFit
                
                // Set appropriate size for the symbol
                let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
                button.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
                
                if debugMode { print("✓ Set SF Symbol 'delete.left' for key \(key.keyCode)") }
            } else {
                // Fallback to text if SF Symbol isn't available
                button.setTitle("⌫", for: .normal)
                button.setTitleColor(.black, for: .normal)
                if debugMode { print("⚠ SF Symbol 'delete.left' not available, using fallback") }
            }
            
        default:
            // Use regular text for all other keys (123, space, return, globe, etc.)
            let displayText = getDisplayTextForKey(key)
            button.setTitle(displayText, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: getFontSize(for: key), weight: .medium)
            button.setTitleColor(.black, for: .normal)
            
            if debugMode {
                print("Set text '\(displayText)' for key \(key.keyCode)")
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
    public static func updateShiftKeyAppearance(button: UIButton, shifted: Bool, locked: Bool = false) {
        guard button.tag == -1 else { return } // Only for shift keys
        
        // Clear any existing title
        button.setTitle("", for: .normal)
        
        // Use different SF Symbol based on state
        let symbolName = if locked {
            "shift.fill"  // Filled version for caps lock
        } else if shifted {
            "shift.fill"  // Filled version for active shift
        } else {
            "shift"       // Regular version for normal state
        }
        
        if let shiftImage = UIImage(systemName: symbolName) {
            button.setImage(shiftImage, for: .normal)
            button.tintColor = .black
            
            // Set appropriate size for the symbol
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
            button.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
        }
        
        // Update background color for visual feedback
        if locked {
            button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        } else if shifted {
            button.backgroundColor = UIColor.systemGray3
        } else {
            button.backgroundColor = UIColor.systemGray4
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
        for subview in view.subviews {
            if let button = subview as? UIButton, button.tag == -1 {
                updateShiftKeyAppearance(button: button, shifted: shifted, locked: locked)
            }
            updateAllShiftKeys(in: subview, shifted: shifted, locked: locked)
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

