import SwiftUI
import UIKit
import KeyboardCore

struct KeyboardPreviewView: View {
    @State private var inputText: String = ""
    @State private var selectedLanguage: LanguageId = .tamil
    @State private var keyboardState: KeyboardState = .normal
    @State private var isShiftLocked: Bool = false
    @State private var currentComposition: String = ""
    
    // Available languages for testing
    private let availableLanguages: [LanguageId] = [
        .tamil, .tamilAnjal, .malayalam, .malayalamAnjal, .hindi, .bengali,
        .gujarati, .kannada, .kannadaAnjal, .punjabi, .telugu, .teluguAnjal,
        .marathi, .oriya, .assamese, .sinhala, .jawi, .qwertyJawi,
        .grantha, .sanskrit, .nepali, .english
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // Language Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Keyboard:")
                    .font(.headline)
                
                Picker("Language", selection: $selectedLanguage) {
                    ForEach(availableLanguages, id: \.self) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.menu)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
            }
            
            // Input Text Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Input Text:")
                    .font(.headline)
                
                TextEditor(text: $inputText)
                    .padding(8)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                    .frame(minHeight: 100)
                    .font(.system(size: 18))
            }
            
            // Composition Display
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Composition:")
                    .font(.headline)
                
                Text(currentComposition.isEmpty ? "(empty)" : currentComposition)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(8)
                    .font(.system(size: 16))//, family: .monospaced))
            }
            
            // Keyboard State Display
            HStack {
                Text("State: \(keyboardStateText)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Clear All") {
                    inputText = ""
                    currentComposition = ""
                }
                .buttonStyle(.bordered)
            }
            
            // Embedded Keyboard
            KeyboardPreviewContainer(
                selectedLanguage: $selectedLanguage,
                keyboardState: $keyboardState,
                isShiftLocked: $isShiftLocked,
                currentComposition: $currentComposition,
                onTextInput: { text in
                    inputText += text
                },
                onDeleteBackward: { count in
                    for _ in 0..<count {
                        if !inputText.isEmpty {
                            inputText.removeLast()
                        }
                    }
                }
            )
            .frame(height: 200) // Reduced from 220, remove extra padding
            .clipped() // Remove any overflow padding
            
            Spacer()
        }
        .padding()
        .navigationTitle("Keyboard Preview")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var keyboardStateText: String {
        switch keyboardState {
        case .normal:
            return "Normal"
        case .shifted:
            return isShiftLocked ? "CAPS LOCK" : "Shifted"
        case .symbols:
            return "Symbols"
        case .shiftedSymbols:
            return "Shifted Symbols"
        }
    }
}

// MARK: - UIKit Container for Keyboard

struct KeyboardPreviewContainer: UIViewControllerRepresentable {
    @Binding var selectedLanguage: LanguageId
    @Binding var keyboardState: KeyboardState
    @Binding var isShiftLocked: Bool
    @Binding var currentComposition: String
    
    let onTextInput: (String) -> Void
    let onDeleteBackward: (Int) -> Void
    
    func makeUIViewController(context: Context) -> KeyboardPreviewViewController {
        let controller = KeyboardPreviewViewController()
        controller.selectedLanguage = selectedLanguage
        controller.onTextInput = onTextInput
        controller.onDeleteBackward = onDeleteBackward
        controller.onStateChange = { state, locked, composition in
            keyboardState = state
            isShiftLocked = locked
            currentComposition = composition
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: KeyboardPreviewViewController, context: Context) {
        // Update language if changed
        if uiViewController.selectedLanguage != selectedLanguage {
            uiViewController.updateLanguage(selectedLanguage)
        }
    }
}

// MARK: - Preview Controller

class KeyboardPreviewViewController: UIViewController {
    // MARK: - Properties
    var selectedLanguage: LanguageId = .tamil {
        didSet {
            if selectedLanguage != oldValue {
                logicController.setLanguage(selectedLanguage)
            }
        }
    }
    
    // MARK: - Logic Controller
    private var logicController: KeyboardLogicController!
    
    // MARK: - Callbacks
    var onTextInput: ((String) -> Void)?
    var onDeleteBackward: ((Int) -> Void)?
    var onStateChange: ((KeyboardState, Bool, String) -> Void)?
    
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
    
    private func setupLogicController() {
        logicController = KeyboardLogicController(
            language: selectedLanguage,
            appGroupIdentifier: nil // No app group needed for preview
        )
        logicController.delegate = self
        logicController.themeObserver = self
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.clear // Remove background
        
        keyboardContainer = UIView()
        keyboardContainer.translatesAutoresizingMaskIntoConstraints = false
        keyboardContainer.backgroundColor = UIColor.clear // Remove gray background
        view.addSubview(keyboardContainer)
        
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
            print("Failed to get layout from logic controller for language: \(selectedLanguage)")
            return
        }
        
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
        
        // Update shift key appearance
        updateShiftKeys()
    }
    
    private func updateShiftKeys() {
        guard let keyboardView = currentKeyboardView else { return }
        
        KeyboardBuilder.updateAllShiftKeys(
            in: keyboardView,
            shifted: logicController.keyboardState == .shifted,
            locked: logicController.isShiftLocked
        )
    }
    
    // MARK: - Public Methods
    func updateLanguage(_ language: LanguageId) {
        selectedLanguage = language
        logicController.setLanguage(language)
    }
    
    private func notifyStateChange() {
        onStateChange?(
            logicController.keyboardState,
            logicController.isShiftLocked,
            logicController.currentComposition
        )
    }
}

// MARK: - KeyboardLogicDelegate
extension KeyboardPreviewViewController: KeyboardLogicDelegate {
    func insertText(_ text: String) {
        onTextInput?(text)
        notifyStateChange()
    }
    
    func deleteBackward(count: Int) {
        onDeleteBackward?(count)
        notifyStateChange()
    }
    
    func performHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    func updateKeyboardView() {
        DispatchQueue.main.async {
            self.buildKeyboard()
            self.notifyStateChange()
        }
    }
    
    func getCurrentInterfaceStyle() -> UIUserInterfaceStyle {
        return traitCollection.userInterfaceStyle
    }
}

// MARK: - KeyboardThemeObserver
extension KeyboardPreviewViewController: KeyboardThemeObserver {
    func themeDidChange() {
        DispatchQueue.main.async {
            // Theme changed - rebuild keyboard with new theme
            self.buildKeyboard()
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        KeyboardPreviewView()
    }
}
