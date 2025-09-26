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
        
        // Handle special keys with custom drawing
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
            button.backgroundColor = UIColor.systemGray4 // Same as shift and delete
        }
        
        // Create custom image for special keys
        let keySize = CGSize(width: 30, height: 30)
        let image = createSpecialKeyImage(for: key, size: keySize, shifted: false)
        
        if let image = image {
            if debugMode { print("✓ Created image for key \(key.keyCode)") }
            button.setTitle(nil, for: .normal) // Clear text only if we have an image
            button.setImage(image, for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.tintColor = .clear // Don't tint the image since it has its own colors
        } else {
            if debugMode { print("✗ Failed to create image for key \(key.keyCode), using text fallback") }
            // Fallback to text if image creation fails
            let displayText = getDisplayTextForKey(key)
            button.setTitle(displayText, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: getFontSize(for: key))
            button.setTitleColor(.black, for: .normal)
        }
        
        // Store key reference for state-aware updates
        button.tag = key.keyCode
    }
    
    private static func getDisplayTextForKey(_ key: KeyboardKey) -> String {
        switch key.keyCode {
        case -1: // Shift
            return "⬆"
        case -5: // Delete
            return "⌫"
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
    
    private static func createSpecialKeyImage(for key: KeyboardKey, size: CGSize, shifted: Bool = false) -> UIImage? {
        if debugMode { print("Creating image for key: code=\(key.keyCode), label='\(key.keyLabel)'") }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard UIGraphicsGetCurrentContext() != nil else {
            if debugMode { print("Failed to get graphics context") }
            return nil
        }
        
        let rect = CGRect(origin: .zero, size: size)
        
        switch key.keyCode {
        case -1: // Shift
            if debugMode { print("Drawing shift symbol") }
            drawShiftSymbol(in: rect, shifted: shifted)
        case -5: // Delete
            if debugMode { print("Drawing delete symbol") }
            drawDeleteSymbol(in: rect)
        case -6: // Globe (should not appear but handle it)
            if debugMode { print("Drawing globe - this should not appear!") }
            drawText("🌐", in: rect)
        case -2: // Mode change (123/ABC)
            if debugMode { print("Drawing mode symbol") }
            drawText(key.keyLabel == "123" ? "123" : "ABC", in: rect)
        case 32: // Space
            if debugMode { print("Drawing space text") }
            drawText("space", in: rect)
        case 10: // Return
            if debugMode { print("Drawing return text") }
            drawText("return", in: rect)
        default:
            if debugMode { print("Drawing default text: '\(key.keyLabel)'") }
            // For other special keys, draw text
            let cleanText = key.keyLabel.replacingOccurrences(of: "#", with: "")
            drawText(cleanText, in: rect)
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if debugMode {
            if image != nil {
                print("Successfully created image for key \(key.keyCode)")
            } else {
                print("Failed to create image for key \(key.keyCode)")
            }
        }
        
        return image
    }
    
    private static func drawShiftSymbol(in rect: CGRect, shifted: Bool) {
        // Use black for visibility on gray background
        let fillColor = UIColor.black
        
        // Simple but clear upward arrow
        let path = UIBezierPath()
        let centerX = rect.midX
        let topY = rect.minY + 6
        let bottomY = rect.maxY - 6
        let arrowWidth: CGFloat = 10
        
        // Arrow head (triangle)
        path.move(to: CGPoint(x: centerX, y: topY))
        path.addLine(to: CGPoint(x: centerX - arrowWidth/2, y: topY + arrowWidth/2))
        path.addLine(to: CGPoint(x: centerX - 3, y: topY + arrowWidth/2))
        path.addLine(to: CGPoint(x: centerX - 3, y: bottomY))
        path.addLine(to: CGPoint(x: centerX + 3, y: bottomY))
        path.addLine(to: CGPoint(x: centerX + 3, y: topY + arrowWidth/2))
        path.addLine(to: CGPoint(x: centerX + arrowWidth/2, y: topY + arrowWidth/2))
        path.close()
        
        fillColor.setFill()
        path.fill()
    }
    
    private static func drawDeleteSymbol(in rect: CGRect) {
        // Black X for visibility
        let strokeColor = UIColor.black
        
        let path = UIBezierPath()
        let inset: CGFloat = 6
        let insetRect = rect.insetBy(dx: inset, dy: inset)
        
        // First diagonal of X
        path.move(to: CGPoint(x: insetRect.minX, y: insetRect.minY))
        path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.maxY))
        
        // Second diagonal of X
        path.move(to: CGPoint(x: insetRect.maxX, y: insetRect.minY))
        path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.maxY))
        
        strokeColor.setStroke()
        path.lineWidth = 2.0
        path.lineCapStyle = .round
        path.stroke()
    }
    
    private static func drawText(_ text: String, in rect: CGRect) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: UIColor.black
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        let textRect = CGRect(
            x: rect.midX - textSize.width / 2,
            y: rect.midY - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        attributedString.draw(in: textRect)
    }
    
    // Method to update shift key appearance
    public static func updateShiftKeyAppearance(button: UIButton, shifted: Bool, locked: Bool = false) {
        guard button.tag == -1 else { return } // Only for shift keys
        
        // Update text and background color based on state
        if locked {
            button.setTitle("⬆", for: .normal)
            button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        } else if shifted {
            button.setTitle("⬆", for: .normal)
            button.backgroundColor = UIColor.systemGray3
        } else {
            button.setTitle("⬆", for: .normal)
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
                return 10.0 // For labels like "space", "return"
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

