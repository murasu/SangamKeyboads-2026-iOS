import Foundation

public enum LanguageId: String, CaseIterable, Identifiable {
    case tamil = "ta"
    case malayalam = "ml"
    case malay = "ms"
    case jawi = "jawi"
    case punjabi = "pa"
    case hindi = "hi"
    case bengali = "bn"
    case kannada = "kn"
    case telugu = "te"
    case gujarati = "gu"
    case oriya = "or"
    case marathi = "mr"
    case nepali = "ne"
    case sanskrit = "sa"
    case sinhala = "si"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .tamil: return "Tamil"
        case .malayalam: return "Malayalam"
        case .malay: return "Malay"
        case .jawi: return "Jawi"
        case .punjabi: return "Punjabi"
        case .hindi: return "Hindi"
        case .bengali: return "Bengali"
        case .kannada: return "Kannada"
        case .telugu: return "Telugu"
        case .gujarati: return "Gujarati"
        case .oriya: return "Oriya"
        case .marathi: return "Marathi"
        case .nepali: return "Nepali"
        case .sanskrit: return "Sanskrit"
        case .sinhala: return "Sinhala"
        }
    }
    
    public var nativeName: String {
        switch self {
        case .tamil: return "தமிழ்"
        case .malayalam: return "മലയാളം"
        case .malay: return "Bahasa Melayu"
        case .jawi: return "جاوي"
        case .punjabi: return "ਪੰਜਾਬੀ"
        case .hindi: return "हिन्दी"
        case .bengali: return "বাংলা"
        case .kannada: return "ಕನ್ನಡ"
        case .telugu: return "తెలుగు"
        case .gujarati: return "ગુજરાતી"
        case .oriya: return "ଓଡ଼ିଆ"
        case .marathi: return "मराठी"
        case .nepali: return "नेपाली"
        case .sanskrit: return "संस्कृतम्"
        case .sinhala: return "සිංහල"
        }
    }
}
