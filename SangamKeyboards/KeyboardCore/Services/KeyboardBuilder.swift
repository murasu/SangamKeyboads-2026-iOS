//
//  KeyboardBuilder.swift
//  SangamKeyboards
//
//  Created by Muthu Nedumaran on 24/09/2025.
//

import UIKit

public class KeyboardBuilder {
    
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
        return specialKeyCodes.contains(key.keyCode) ||
               key.keyLabel.hasPrefix("#") ||
               key.isModifier == true
    }
    
    private static func configureSpecialKey(button: UIButton, key: KeyboardKey) {
        button.setTitle(nil, for: .normal) // Clear any text
        
        // Create custom image for special keys
        let keySize = CGSize(width: 30, height: 30)
        let image = createSpecialKeyImage(for: key, size: keySize)
        
        if let image = image {
            button.setImage(image, for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.tintColor = .black
        } else {
            // Fallback to text if image creation fails
            let displayLabel = localizeKeyLabel(key.keyLabel)
            button.setTitle(displayLabel, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: getFontSize(for: key))
        }
        
        // Store key reference for state-aware updates
        button.tag = key.keyCode
    }
    
    // Method to update shift key appearance
    public static func updateShiftKeyAppearance(button: UIButton, shifted: Bool, locked: Bool = false) {
        guard button.tag == -1 else { return } // Only for shift keys
        
        let keySize = CGSize(width: 30, height: 30)
        // For now, use the fallback drawing since we don't have KbStyleKit yet
        let image = createShiftImage(size: keySize, shifted: shifted || locked)
        button.setImage(image, for: .normal)
        
        // Update background color for visual feedback
        if locked {
            button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        } else if shifted {
            button.backgroundColor = UIColor.systemGray3
        } else {
            button.backgroundColor = UIColor.systemGray4
        }
    }
    
    private static func createSpecialKeyImage(for key: KeyboardKey, size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        let rect = CGRect(origin: .zero, size: size)
        
        switch key.keyCode {
        case -1: // Shift
            drawShiftSymbol(in: rect, context: context)
        case -5: // Delete
            drawDeleteSymbol(in: rect, context: context)
        case -6: // Globe
            drawGlobeSymbol(in: rect, context: context)
        case -2: // Mode change (123/ABC)
            drawModeSymbol(in: rect, context: context, label: key.keyLabel)
        default:
            // For other special keys, draw text
            drawText(key.keyLabel, in: rect)
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private static func createShiftImage(size: CGSize, shifted: Bool) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        let rect = CGRect(origin: .zero, size: size)
        
        // Set colors based on shift state
        let color = shifted ? UIColor.black : UIColor.darkGray
        context.setStrokeColor(color.cgColor)
        context.setFillColor(color.cgColor)
        context.setLineWidth(2.0)
        
        let path = CGMutablePath()
        let centerX = rect.midX
        let topY = rect.minY + 5
        let bottomY = rect.maxY - 8
        let arrowWidth: CGFloat = 12
        
        // Draw upward arrow
        path.move(to: CGPoint(x: centerX, y: topY))
        path.addLine(to: CGPoint(x: centerX - arrowWidth/2, y: topY + arrowWidth/2))
        path.move(to: CGPoint(x: centerX, y: topY))
        path.addLine(to: CGPoint(x: centerX + arrowWidth/2, y: topY + arrowWidth/2))
        
        // Draw vertical line
        path.move(to: CGPoint(x: centerX, y: topY + 3))
        path.addLine(to: CGPoint(x: centerX, y: bottomY - 3))
        
        // Draw horizontal base
        path.move(to: CGPoint(x: centerX - 6, y: bottomY))
        path.addLine(to: CGPoint(x: centerX + 6, y: bottomY))
        
        context.addPath(path)
        context.strokePath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private static func drawShiftSymbol(in rect: CGRect, context: CGContext) {
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(2.0)
        
        let path = CGMutablePath()
        let centerX = rect.midX
        let topY = rect.minY + 5
        let bottomY = rect.maxY - 8
        let arrowWidth: CGFloat = 12
        
        // Draw upward arrow
        path.move(to: CGPoint(x: centerX, y: topY))
        path.addLine(to: CGPoint(x: centerX - arrowWidth/2, y: topY + arrowWidth/2))
        path.move(to: CGPoint(x: centerX, y: topY))
        path.addLine(to: CGPoint(x: centerX + arrowWidth/2, y: topY + arrowWidth/2))
        
        // Draw vertical line
        path.move(to: CGPoint(x: centerX, y: topY + 3))
        path.addLine(to: CGPoint(x: centerX, y: bottomY - 3))
        
        // Draw horizontal base
        path.move(to: CGPoint(x: centerX - 6, y: bottomY))
        path.addLine(to: CGPoint(x: centerX + 6, y: bottomY))
        
        context.addPath(path)
        context.strokePath()
    }
    
    private static func drawDeleteSymbol(in rect: CGRect, context: CGContext) {
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1.5)
        
        let path = CGMutablePath()
        let insetRect = rect.insetBy(dx: 4, dy: 8)
        
        // Draw X shape
        path.move(to: CGPoint(x: insetRect.minX, y: insetRect.minY))
        path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.maxY))
        path.move(to: CGPoint(x: insetRect.maxX, y: insetRect.minY))
        path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.maxY))
        
        context.addPath(path)
        context.strokePath()
    }
    
    private static func drawGlobeSymbol(in rect: CGRect, context: CGContext) {
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1.0)
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 4
        
        // Draw circle
        context.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        
        // Draw horizontal line
        context.move(to: CGPoint(x: center.x - radius, y: center.y))
        context.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        
        // Draw vertical line
        context.move(to: CGPoint(x: center.x, y: center.y - radius))
        context.addLine(to: CGPoint(x: center.x, y: center.y + radius))
        
        // Draw curved lines
        let path = CGMutablePath()
        path.move(to: CGPoint(x: center.x - radius * 0.7, y: center.y - radius))
        path.addQuadCurve(to: CGPoint(x: center.x - radius * 0.7, y: center.y + radius),
                         control: CGPoint(x: center.x + radius * 0.3, y: center.y))
        
        path.move(to: CGPoint(x: center.x + radius * 0.7, y: center.y - radius))
        path.addQuadCurve(to: CGPoint(x: center.x + radius * 0.7, y: center.y + radius),
                         control: CGPoint(x: center.x - radius * 0.3, y: center.y))
        
        context.addPath(path)
        context.strokePath()
    }
    
    private static func drawModeSymbol(in rect: CGRect, context: CGContext, label: String) {
        let displayText = label == "#123" ? "123" : "ABC"
        drawText(displayText, in: rect)
    }
    
    private static func drawText(_ text: String, in rect: CGRect) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
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
            return "" // Will be drawn as symbol
        case "#delete":
            return "" // Will be drawn as symbol
        case "#123", "#ABC":
            return "" // Will be drawn as symbol
        case "#globe":
            return "" // Will be drawn as symbol
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

