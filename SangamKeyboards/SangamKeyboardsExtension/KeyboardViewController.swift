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
            appGroupIdentifier: "group.com.murasu.Sangam.keyboardsharing" // Update with your app group
        )
        logicController.delegate = self
        logicController.themeObserver = self
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemGray5
        
        // Keyboard container - takes full space
        keyboardContainer = UIView()
        keyboardContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboardContainer)
        
        // Layout constraints - keyboard fills entire view
        NSLayoutConstraint.activate([
            keyboardContainer.topAnchor.constraint(equalTo: view.topAnchor),
            keyboardContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
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
    }
    
    private func updateShiftKeyAppearance() {
        guard let keyboardView = currentKeyboardView else { return }
        
        KeyboardBuilder.updateAllShiftKeys(
            in: keyboardView,
            shifted: logicController.keyboardState == .shifted,
            locked: logicController.isShiftLocked
        )
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Remove any existing height constraints to avoid conflicts
        view.constraints.forEach { constraint in
            if constraint.firstAttribute == .height && constraint.firstItem === view {
                view.removeConstraint(constraint)
            }
        }
        
        // Set proper keyboard height based on device size and orientation
        let keyboardHeight = getKeyboardHeight()
        
        let heightConstraint = NSLayoutConstraint(
            item: view!,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 0.0,
            constant: keyboardHeight
        )
        heightConstraint.priority = UILayoutPriority(999)
        heightConstraint.identifier = "KeyboardHeight"
        view.addConstraint(heightConstraint)
    }
    
    private func getKeyboardHeight() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let isLandscape = traitCollection.verticalSizeClass == .compact
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            // iPad heights
            if isLandscape {
                return 398 // iPad landscape
            } else {
                return 264 // iPad portrait
            }
        } else {
            // iPhone heights - determine device type by screen dimensions
            let screenSize = max(screenWidth, screenHeight)
            
            if screenSize >= 926 { // iPhone 14 Pro Max, 15 Pro Max, etc.
                return isLandscape ? 172 : 291
            } else if screenSize >= 896 { // iPhone 11, 12, 13, 14, XR, etc.
                return isLandscape ? 172 : 291
            } else if screenSize >= 844 { // iPhone 12 mini, 13 mini
                return isLandscape ? 172 : 291
            } else if screenSize >= 812 { // iPhone X, XS, 11 Pro
                return isLandscape ? 172 : 291
            } else if screenSize >= 736 { // iPhone 6+, 7+, 8+
                return isLandscape ? 172 : 271
            } else if screenSize >= 667 { // iPhone 6, 7, 8, SE 2nd/3rd gen
                return isLandscape ? 172 : 258
            } else { // iPhone SE 1st gen and older
                return isLandscape ? 172 : 253
            }
        }
    }
}

// MARK: - KeyboardLogicDelegate
extension KeyboardViewController: KeyboardLogicDelegate {
    func insertText(_ text: String) {
        textDocumentProxy.insertText(text)
    }
    
    func deleteBackward(count: Int) {
        for _ in 0..<count {
            textDocumentProxy.deleteBackward()
        }
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

