//
//  KeyboardViewController.swift
//  SangamKeyboardsExtension
//
//  Created by Muthu Nedumaran on 24/09/2025.
//

import UIKit
import KeyboardCore

class KeyboardViewController: UIInputViewController {
    
    // MARK: - Logic Controller
    private var logicController: KeyboardLogicController!
    
    // MARK: - UI Components
    private var statusLabel: UILabel!
    private var compositionLabel: UILabel!
    private var keyboardContainer: UIView!
    private var currentKeyboardView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLogicController()
        setupUI()
        buildKeyboard()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Update keyboard colors when interface style changes
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection),
           let keyboardView = currentKeyboardView {
            KeyboardBuilder.updateKeyboardColors(
                in: keyboardView,
                interfaceStyle: traitCollection.userInterfaceStyle
            )
        }
    }
    
    // MARK: - Setup Methods
    private func setupLogicController() {
        // Initialize with Tamil as default - you can change this or make it configurable
        logicController = KeyboardLogicController(
            language: .tamil,
            appGroupIdentifier: "group.com.murasu.SangamKeyboards" // Update with your app group
        )
        logicController.delegate = self
        logicController.themeObserver = self
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemGray5
        
        // Status display
        statusLabel = UILabel()
        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        // Composition display
        compositionLabel = UILabel()
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
        
        // Control buttons (for testing - remove in production)
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
        
        updateDisplay()
    }
    
    private func buildKeyboard() {
        // Remove existing keyboard view
        currentKeyboardView?.removeFromSuperview()
        currentKeyboardView = nil
        
        guard let layout = logicController.getCurrentLayout() else {
            print("Failed to get layout from logic controller")
            return
        }
        
        // Build new keyboard view
        let keyboardView = KeyboardBuilder.buildKeyboard(
            layout: layout,
            containerView: keyboardContainer
        ) { [weak self] key in
            self?.logicController.handleKeyPress(key)
        }
        
        keyboardContainer.addSubview(keyboardView)
        currentKeyboardView = keyboardView
        
        NSLayoutConstraint.activate([
            keyboardView.topAnchor.constraint(equalTo: keyboardContainer.topAnchor),
            keyboardView.leadingAnchor.constraint(equalTo: keyboardContainer.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: keyboardContainer.trailingAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: keyboardContainer.bottomAnchor)
        ])
        
        // Update shift key appearance based on current state
        updateShiftKeyAppearance()
        updateStatusLabel()
    }
    
    private func updateShiftKeyAppearance() {
        guard let keyboardView = currentKeyboardView else { return }
        
        KeyboardBuilder.updateAllShiftKeys(
            in: keyboardView,
            shifted: logicController.keyboardState == .shifted,
            locked: logicController.isShiftLocked
        )
    }
    
    private func updateStatusLabel() {
        let stateText = logicController.getStateDisplayText()
        statusLabel.text = "Tamil - \(stateText)"
    }
    
    private func updateDisplay() {
        let composition = logicController.currentComposition
        compositionLabel.text = composition.isEmpty ?
            "Composition: (empty)" :
            "Composition: \(composition)"
    }
    
    // MARK: - Control Buttons (for testing - remove in production)
    private func createControlButtons() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let clearButton = createControlButton(title: "Clear") { [weak self] in
            self?.logicController.clearComposition()
            self?.updateDisplay()
        }
        
        let switchButton = createControlButton(title: "Switch Lang") { [weak self] in
            // Example: Switch between Tamil and Tamil Anjal
            let newLanguage: LanguageId = self?.logicController.currentLanguage == .tamil ? .tamilAnjal : .tamil
            self?.logicController.setLanguage(newLanguage)
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
        minHeightConstraint.priority = UILayoutPriority(999)
        view.addConstraint(minHeightConstraint)
    }
}

// MARK: - KeyboardLogicDelegate
extension KeyboardViewController: KeyboardLogicDelegate {
    func insertText(_ text: String) {
        textDocumentProxy.insertText(text)
        updateDisplay()
    }
    
    func deleteBackward(count: Int) {
        for _ in 0..<count {
            textDocumentProxy.deleteBackward()
        }
        updateDisplay()
    }
    
    func performHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    func updateKeyboardView() {
        DispatchQueue.main.async {
            self.buildKeyboard()
        }
    }
    
    func getCurrentInterfaceStyle() -> UIUserInterfaceStyle {
        return traitCollection.userInterfaceStyle
    }
}

// MARK: - KeyboardThemeObserver
extension KeyboardViewController: KeyboardThemeObserver {
    func themeDidChange() {
        DispatchQueue.main.async {
            // Theme changed - rebuild keyboard with new theme
            self.buildKeyboard()
        }
    }
}

