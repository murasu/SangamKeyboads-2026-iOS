//
//  KeyboardViewController.swift
//  SangamKeyboardsExtension
//
//  Created by Muthu Nedumaran on 24/09/2025.
//

// Updated to use actual Tamil99 layout from XML

import UIKit
import KeyboardCore

class KeyboardViewController: UIInputViewController {
    // MARK: - Keyboard State
    private var keyboardState: KeyboardState = .normal
    private var isShiftLocked = false
    
    // MARK: - Current Language
    private var currentLanguage: LanguageId = .tamil
    
    // MARK: - Test Components
    private var tamil99Translator: Tamil99KeyTranslator!
    private var tamilAnjalTranslator: TamilAnjalKeyTranslator!
    private var currentTranslator: KeyTranslator!
    private var currentComposition = ""
    
    // MARK: - Layout
    private var currentLayout: KeyboardLayout!
    
    // MARK: - UI
    private var statusLabel: UILabel!
    private var compositionLabel: UILabel!
    private var keyboardContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTranslators()
        //setupLayout()
        setupUI()
    }
    
    private func setupTranslators() {
        tamil99Translator = Tamil99KeyTranslator()
        tamilAnjalTranslator = TamilAnjalKeyTranslator()
        currentTranslator = tamil99Translator // Start with Tamil99
    }
    
    private func setupLayout() {
        currentLayout = LayoutParser.loadLayout(for: .tamil)
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemGray5
        
        // Status display
        statusLabel = UILabel()
        statusLabel.text = "Tamil99 Layout Test"
        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        // Composition display
        compositionLabel = UILabel()
        compositionLabel.text = "Composition: (empty)"
        compositionLabel.textAlignment = .center
        compositionLabel.font = UIFont.systemFont(ofSize: 18)
        compositionLabel.numberOfLines = 0
        compositionLabel.backgroundColor = UIColor.systemGray6
        compositionLabel.layer.cornerRadius = 8
        compositionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(compositionLabel)
        
        // Keyboard container
        keyboardContainer = UIView()
        keyboardContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboardContainer)
        
        // Control buttons
        let controlStack = createControlButtons()
        view.addSubview(controlStack)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            compositionLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            compositionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            compositionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            compositionLabel.heightAnchor.constraint(equalToConstant: 40),
            
            keyboardContainer.topAnchor.constraint(equalTo: compositionLabel.bottomAnchor, constant: 8),
            keyboardContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            keyboardContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            keyboardContainer.heightAnchor.constraint(equalToConstant: 180),
            
            controlStack.topAnchor.constraint(equalTo: keyboardContainer.bottomAnchor, constant: 8),
            controlStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            controlStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            controlStack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -8)
        ])
        
        // Build the Tamil keyboard
        buildTamilKeyboard()
        updateDisplay()
    }
    
    private func buildTamilKeyboard() {
        keyboardContainer.subviews.forEach { $0.removeFromSuperview() }
        
        guard let layout = LayoutParser.loadLayout(for: .tamil, state: keyboardState) else {
            print("Failed to load layout for state: \(keyboardState)")
            return
        }
        
        let keyboardView = KeyboardBuilder.buildKeyboard(
            layout: layout,
            containerView: keyboardContainer
        ) { [weak self] key in
            self?.handleKeyPress(key)
        }
        
        keyboardContainer.addSubview(keyboardView)
        
        NSLayoutConstraint.activate([
            keyboardView.topAnchor.constraint(equalTo: keyboardContainer.topAnchor),
            keyboardView.leadingAnchor.constraint(equalTo: keyboardContainer.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: keyboardContainer.trailingAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: keyboardContainer.bottomAnchor)
        ])
        
        // Update shift key appearance based on current state
        KeyboardBuilder.updateAllShiftKeys(
            in: keyboardView,
            shifted: keyboardState == .shifted,
            locked: isShiftLocked
        )
        
        updateStatusLabel()
    }

    private func handleShift() {
        let previousState = keyboardState
        let wasLocked = isShiftLocked
        
        switch keyboardState {
        case .normal:
            keyboardState = .shifted
            isShiftLocked = false
            
        case .shifted:
            if isShiftLocked {
                keyboardState = .normal
                isShiftLocked = false
            } else {
                // Double-tap shift = caps lock
                isShiftLocked = true
            }
            
        case .symbols:
            if hasShiftedSymbolsLayout(for: currentLanguage) {
                keyboardState = .shiftedSymbols
            }
            
        case .shiftedSymbols:
            keyboardState = .symbols
        }
        
        // Only rebuild if we're changing layout types
        if (previousState == .normal || previousState == .shifted) &&
           (keyboardState == .symbols || keyboardState == .shiftedSymbols) ||
           (previousState == .symbols || previousState == .shiftedSymbols) &&
           (keyboardState == .normal || keyboardState == .shifted) {
            buildTamilKeyboard()
        } else {
            // Just update the shift key appearance without rebuilding
            KeyboardBuilder.updateAllShiftKeys(
                in: keyboardContainer,
                shifted: keyboardState == .shifted,
                locked: isShiftLocked
            )
            updateStatusLabel()
        }
    }
    
    private func createControlButtons() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let clearButton = createControlButton(title: "Clear") { [weak self] in
            self?.clearComposition()
        }
        
        let switchButton = createControlButton(title: "Switch Mode") { [weak self] in
            self?.switchTranslatorMode()
        }
        
        stack.addArrangedSubview(clearButton)
        stack.addArrangedSubview(switchButton)
        
        return stack
    }
    
    private func createControlButton(title: String, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        
        return button
    }
    
    // MARK: - Key Handling
    
    private func handleKeyPress(_ key: KeyboardKey) {
        let keyCode = key.keyCode
        
        switch keyCode {
        case -1: // Shift
            handleShift()
            return
        case -2: // Mode change (123/ABC)
            handleModeChange()
            return
        case -5: // Delete
            handleDelete()
            // Auto-unshift after delete (standard behavior)
            if keyboardState == .shifted && !isShiftLocked {
                keyboardState = .normal
                buildTamilKeyboard()
            }
            return
        case -6: // Globe
            advanceToNextInputMode()
            return
        case 32: // Space
            handleSpace()
            // Auto-unshift after space
            if keyboardState == .shifted && !isShiftLocked {
                keyboardState = .normal
                buildTamilKeyboard()
            }
            return
        case 10: // Return
            handleReturn()
            return
        default:
            break
        }
        
        // Handle character input
        handleCharacterInput(keyCode: keyCode, label: key.keyLabel)
        
        // Auto-unshift after character input (standard behavior)
        if keyboardState == .shifted && !isShiftLocked {
            keyboardState = .normal
            buildTamilKeyboard()
        }
    }

    /*
    private func handleShift() {
        switch keyboardState {
        case .normal:
            keyboardState = .shifted
            isShiftLocked = false
            
        case .shifted:
            if isShiftLocked {
                keyboardState = .normal
                isShiftLocked = false
            } else {
                // Double-tap shift = caps lock
                isShiftLocked = true
            }
            
        case .symbols:
            // Check if shifted symbols layout exists for current language
            if hasShiftedSymbolsLayout(for: currentLanguage) {
                keyboardState = .shiftedSymbols
            }
            
        case .shiftedSymbols:
            keyboardState = .symbols
        }
        buildTamilKeyboard()
    } */
    
    private func hasShiftedSymbolsLayout(for languageId: LanguageId) -> Bool {
        // Languages that have shifted symbols layouts
        let languagesWithShiftedSymbols: Set<LanguageId> = [
            .punjabi, .hindi, .bengali, .gujarati
            // Add other languages that have symbols_shift layouts
        ]
        return languagesWithShiftedSymbols.contains(languageId)
    }

    private func handleModeChange() {
        switch keyboardState {
        case .normal, .shifted:
            keyboardState = .symbols
        case .symbols:
            // Check if this language has shifted symbols
            if hasShiftedSymbolsLayout(for: currentLanguage) {
                keyboardState = .shiftedSymbols
            } else {
                keyboardState = .normal
            }
        case .shiftedSymbols:
            keyboardState = .normal
        }
        isShiftLocked = false
        buildTamilKeyboard()
    }
    
    private func updateStatusLabel() {
        let stateText: String
        switch keyboardState {
        case .normal:
            stateText = "Normal"
        case .shifted:
            stateText = isShiftLocked ? "CAPS" : "Shift"
        case .symbols:
            stateText = "123"
        case .shiftedSymbols:
            stateText = "#+="
        }
        
        let translatorText = currentTranslator is Tamil99KeyTranslator ? "Tamil99" : "Tamil Anjal"
        statusLabel.text = "\(translatorText) - \(stateText)"
    }
    
    private func handleCharacterInput(keyCode: Int, label: String) {
        Task {
            do {
                let result = await currentTranslator.translateKey(
                    keyCode: keyCode,
                    isShifted: false,
                    currentComposition: currentComposition
                )
                
                currentComposition = result.newComposition
                textDocumentProxy.insertText(result.displayText)
                
                await MainActor.run {
                    updateDisplay()
                }
                
            } catch {
                print("Translation error: \(error)")
            }
        }
    }
    
    private func handleDelete() {
        Task {
            do {
                let result = await currentTranslator.processDelete(composition: currentComposition)
                
                currentComposition = result.newComposition
                
                for _ in 0..<result.charactersToDelete {
                    textDocumentProxy.deleteBackward()
                }
                
                await MainActor.run {
                    updateDisplay()
                }
                
            } catch {
                print("Delete error: \(error)")
            }
        }
    }
    
    private func handleSpace() {
        textDocumentProxy.insertText(" ")
        currentComposition = ""
        updateDisplay()
    }
    
    private func handleReturn() {
        textDocumentProxy.insertText("\n")
        currentComposition = ""
        updateDisplay()
    }
    
    private func clearComposition() {
        currentComposition = ""
        updateDisplay()
    }
    
    private func switchTranslatorMode() {
        if currentTranslator is Tamil99KeyTranslator {
            currentTranslator = tamilAnjalTranslator
            statusLabel.text = "Tamil Anjal Layout Test"
        } else {
            currentTranslator = tamil99Translator
            statusLabel.text = "Tamil99 Layout Test"
        }
        currentComposition = ""
        updateDisplay()
    }
    
    private func updateDisplay() {
        compositionLabel.text = currentComposition.isEmpty ?
            "Composition: (empty)" :
            "Composition: \(currentComposition)"
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Set minimum height instead of fixed height
        let minHeightConstraint = NSLayoutConstraint(
            item: view!,
            attribute: .height,
            relatedBy: .greaterThanOrEqual,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 0.0,
            constant: 250
        )
        minHeightConstraint.priority = UILayoutPriority(999) // High but not required
        view.addConstraint(minHeightConstraint)
    }
    /*
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        let heightConstraint = NSLayoutConstraint(
            item: view!,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 0.0,
            constant: 300 // Increased for full Tamil layout
        )
        view.addConstraint(heightConstraint)
    }*/
}

