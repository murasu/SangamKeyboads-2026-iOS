import Foundation

public enum LanguageId: String, CaseIterable, Codable {
    // Primary South Asian Languages
    case tamil = "tamil"
    case hindi = "hindi"
    case bengali = "bengali"
    case gujarati = "gujarati"
    case kannada = "kannada"
    case malayalam = "malayalam"
    case marathi = "marathi"
    case punjabi = "punjabi"
    case telugu = "telugu"
    case oriya = "oriya"
    case assamese = "assamese"
    case sinhala = "sinhala"
    
    // Tamil Variants
    case tamilAnjal = "tamil_anjal"
    
    // Other Scripts
    case jawi = "jawi"
    case grantha = "grantha"
    case sanskrit = "sanskrit"
    case nepali = "nepali"
    
    // QWERTY Variants
    case qwerty = "qwerty"
    case qwertyJawi = "qwerty_jawi"
    
    // Anjal Variants
    case malayalamAnjal = "malayalam_anjal"
    case kannadaAnjal = "kannada_anjal"
    case teluguAnjal = "telugu_anjal"
    
    // English
    case english = "english"
    
    public var displayName: String {
        switch self {
        case .tamil: return "தமிழ்"
        case .tamilAnjal: return "Tamil Anjal"
        case .hindi: return "हिन्दी"
        case .bengali: return "বাংলা"
        case .gujarati: return "ગુજરાતી"
        case .kannada: return "ಕನ್ನಡ"
        case .kannadaAnjal: return "Kannada Anjal"
        case .malayalam: return "മലയാളം"
        case .malayalamAnjal: return "Malayalam Anjal"
        case .marathi: return "मराठी"
        case .punjabi: return "ਪੰਜਾਬੀ"
        case .telugu: return "తెలుగు"
        case .teluguAnjal: return "Telugu Anjal"
        case .oriya: return "ଓଡିଆ"
        case .assamese: return "অসমীয়া"
        case .sinhala: return "සිංහල"
        case .jawi: return "جاوي"
        case .grantha: return "𑌗𑍍𑌰𑌨𑍍𑌥"
        case .sanskrit: return "संस्कृत"
        case .nepali: return "नेपाली"
        case .qwerty: return "QWERTY"
        case .qwertyJawi: return "QWERTY Jawi"
        case .english: return "English"
        }
    }
}
