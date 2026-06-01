import SwiftUI

enum MoveClassification: String {
    case brilliant = "Brillant"
    case great = "Großartiger Zug"
    case best = "Bester Zug"
    case excellent = "Exzellent"
    case good = "Gut"
    case inaccuracy = "Ungenauigkeit"
    case mistake = "Fehler"
    case blunder = "Grober Fehler"
    case missed = "Verpasst"
    case forced = "Forciert"
    case book = "Buch"
    case none = "Keine"
    
    var displayName: String {
        switch self {
        case .brilliant: return L10n.tr("brilliant")
        case .great: return L10n.tr("great")
        case .best: return L10n.tr("best")
        case .excellent: return L10n.tr("excellent")
        case .good: return L10n.tr("good")
        case .inaccuracy: return L10n.tr("inaccuracy")
        case .mistake: return L10n.tr("mistake")
        case .blunder: return L10n.tr("blunder")
        case .missed: return L10n.tr("missed")
        case .forced: return L10n.tr("forced")
        case .book: return L10n.tr("book")
        case .none: return L10n.tr("none")
        }
    }
    
    var color: Color {
        switch self {
        case .brilliant: return ClassificationColor.brilliant
        case .great: return ClassificationColor.great
        case .best: return ClassificationColor.best
        case .excellent: return ClassificationColor.excellent
        case .good: return ClassificationColor.good
        case .inaccuracy: return ClassificationColor.inaccuracy
        case .mistake: return ClassificationColor.mistake
        case .blunder: return ClassificationColor.blunder
        case .missed: return ClassificationColor.missed
        case .forced: return ClassificationColor.forced
        case .book: return ClassificationColor.book
        case .none: return .clear
        }
    }
    
    var symbol: String {
        switch self {
        case .brilliant: return "!!"
        case .great: return "!"
        case .best: return "★"
        case .excellent: return "👍"
        case .good: return "✓"
        case .inaccuracy: return "?!"
        case .mistake: return "?"
        case .blunder: return "??"
        case .missed: return "X"
        case .forced: return "⚑"
        case .book: return "📖"
        case .none: return ""
        }
    }
    
    var iconName: String? {
        switch self {
        case .excellent: return "hand.thumbsup.fill"
        case .book: return "book.fill"
        case .missed: return "xmark"
        default: return nil
        }
    }
}

struct MoveClassificationBadge: View {
    let classification: MoveClassification
    var size: CGFloat = 24
    
    var body: some View {
        if classification != .none {
            ZStack {
                // Sticker White Border with Drop Shadow
                Circle()
                    .fill(Color.white)
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(0.22), radius: size * 0.08, x: 0, y: size * 0.04)
                
                // Colored Circle
                Circle()
                    .fill(classification.color)
                    .frame(width: size * 0.82, height: size * 0.82)
                
                // Symbol/Icon with subtle 3D shadow
                Group {
                    if let icon = classification.iconName {
                        Image(systemName: icon)
                            .font(.system(size: size * 0.44, weight: .bold))
                    } else {
                        Text(classification.symbol)
                            .font(.system(size: size * 0.44, weight: .black, design: .rounded))
                    }
                }
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.3), radius: size * 0.02, x: 0, y: size * 0.03)
            }
        }
    }
}

struct CheckmateBadge: View {
    var size: CGFloat = 24
    
    var body: some View {
        ZStack {
            // Sticker White Border with Drop Shadow
            Circle()
                .fill(Color.white)
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.22), radius: size * 0.08, x: 0, y: size * 0.04)
            
            // Red Colored Circle (blunder color)
            Circle()
                .fill(ClassificationColor.blunder)
                .frame(width: size * 0.82, height: size * 0.82)
            
            Text("#")
                .font(.system(size: size * 0.46, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.3), radius: size * 0.02, x: 0, y: size * 0.03)
        }
    }
}

struct DrawBadge: View {
    var size: CGFloat = 24
    
    var body: some View {
        ZStack {
            // Sticker White Border with Drop Shadow
            Circle()
                .fill(Color.white)
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.22), radius: size * 0.08, x: 0, y: size * 0.04)
            
            // Gray Colored Circle
            Circle()
                .fill(Color.gray)
                .frame(width: size * 0.82, height: size * 0.82)
            
            Text("½")
                .font(.system(size: size * 0.46, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.3), radius: size * 0.02, x: 0, y: size * 0.03)
        }
    }
}
