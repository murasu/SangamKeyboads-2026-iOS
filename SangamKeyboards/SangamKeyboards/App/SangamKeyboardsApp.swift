import SwiftUI
import KeyboardCore

@main
struct SangamKeyboardsApp: App {
    
    init() {
        // Configure for multi-language support
        SupportedLanguages.configure(supportedLanguages: SupportedLanguages.all)
        AppConfiguration.shared.appVariant = .multiLanguage
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
