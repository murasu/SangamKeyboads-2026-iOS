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
        mainStack.spacing = 8
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        for row in layout.rows {
            // Skip iPad-specific rows for now
            if row.rowId == "pad" { continue }
            
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fill
            rowStack.spacing = 4
            
            for key in row.keys {
                let button = createKeyButton(key: key, handler: keyPressHandler)
                rowStack.addArrangedSubview(button)
                
                // Apply width constraints based on key.keyWidth
                if let keyWidth = key.keyWidth {
                    let width = parsePercentage(keyWidth) * containerView.frame.width
                    button.widthAnchor.constraint(equalToConstant: width).isActive = true
                }
            }
            
            mainStack.addArrangedSubview(rowStack)
        }
        
        return mainStack
    }
    
    private static func createKeyButton(
        key: KeyboardKey,
        handler: @escaping (KeyboardKey) -> Void
    ) -> UIButton {
        
        let button = UIButton(type: .system)
        button.setTitle(key.keyLabel, for: .normal)
        button.backgroundColor = key.isModifier == true ? UIColor.systemGray4 : UIColor.white
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray3.cgColor
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        button.setTitleColor(.black, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Handle special key labels
        let displayLabel = localizeKeyLabel(key.keyLabel)
        button.setTitle(displayLabel, for: .normal)
        
        button.addAction(UIAction { _ in
            handler(key)
        }, for: .touchUpInside)
        
        return button
    }
    
    private static func parsePercentage(_ percentString: String) -> CGFloat {
        let cleanString = percentString.replacingOccurrences(of: "%", with: "")
        return CGFloat(Double(cleanString) ?? 0) / 100.0
    }
    
    private static func localizeKeyLabel(_ label: String) -> String {
        switch label {
        case "#space":
            return "Space"
        case "#return":
            return "Return"
        case "⬆︎":
            return "⬆"
        default:
            return label
        }
    }
}
