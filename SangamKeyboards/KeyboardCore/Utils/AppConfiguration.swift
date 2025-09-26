import Foundation

public class AppConfiguration {
    public static let shared = AppConfiguration()
    
    public var enabledLanguages: Set<LanguageId> = []
    public var appVariant: AppVariant = .multiLanguage
    
    private init() {}
    
    public func isLanguageEnabled(_ language: LanguageId) -> Bool {
        return enabledLanguages.contains(language)
    }
    
    public func enableLanguage(_ language: LanguageId) {
        enabledLanguages.insert(language)
    }
    
    public func disableLanguage(_ language: LanguageId) {
        enabledLanguages.remove(language)
    }
}

public enum AppVariant {
    case multiLanguage
    case tamilOnly
    case jawiOnly
}

public struct SupportedLanguages {
    public static let all: Set<LanguageId> = Set(LanguageId.allCases)
    public static let tamilOnly: Set<LanguageId> = [.tamil]
    public static let jawiOnly: Set<LanguageId> = [.jawi]
    
    public static func configure(supportedLanguages: Set<LanguageId>) {
        AppConfiguration.shared.enabledLanguages = supportedLanguages
    }
}
