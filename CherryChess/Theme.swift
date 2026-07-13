import SwiftUI

struct Theme {
    enum ThemeType: String, CaseIterable, Identifiable {
        case cherry = "cherry"
        case standard = "standard"
        case darkNeon = "darkNeon"
        case midnightGold = "midnightGold"
        case sweetRose = "sweetRose"
        case onyx = "onyx"
        case aquamarine = "aquamarine"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .cherry: return L10n.tr("cherry")
            case .standard: return L10n.tr("standard")
            case .darkNeon: return L10n.tr("dark_neon")
            case .midnightGold: return L10n.tr("midnight_gold")
            case .sweetRose: return L10n.tr("sweet_rose")
            case .onyx: return L10n.tr("onyx")
            case .aquamarine: return L10n.tr("aquamarine")
            }
        }
    }

    static var current: ThemeType {
        let saved = UserDefaults.standard.string(forKey: "appTheme") ?? "cherry"
        return ThemeType(rawValue: saved) ?? .cherry
    }
    
    static var darkSquare: Color {
        switch current {
        case .cherry:
            return Color(red: 150/255, green: 55/255, blue: 68/255) // Maroon cherry dark square
        case .standard:
            return Color(red: 119/255, green: 149/255, blue: 86/255) // #779556
        case .darkNeon:
            return Color(red: 24/255, green: 30/255, blue: 46/255) // #181E2E
        case .midnightGold:
            return Color(red: 77/255, green: 58/255, blue: 47/255) // #4D3A2F
        case .sweetRose:
            return Color(red: 196/255, green: 115/255, blue: 140/255) // #C4738C
        case .onyx:
            return Color(red: 43/255, green: 43/255, blue: 43/255) // #2B2B2B
        case .aquamarine:
            return Color(red: 128/255, green: 181/255, blue: 214/255) // #80B5D6
        }
    }

    static var lightSquare: Color {
        switch current {
        case .cherry:
            return Color(red: 244/255, green: 227/255, blue: 230/255) // Soft blush light square
        case .standard:
            return Color(red: 235/255, green: 236/255, blue: 208/255) // #ebecd0
        case .darkNeon:
            return Color(red: 45/255, green: 55/255, blue: 80/255) // #2D3750
        case .midnightGold:
            return Color(red: 205/255, green: 186/255, blue: 150/255) // #CDBA96
        case .sweetRose:
            return Color(red: 251/255, green: 228/255, blue: 236/255) // #FBE4EC
        case .onyx:
            return Color(red: 237/255, green: 237/255, blue: 237/255) // #EDEDED
        case .aquamarine:
            return Color(red: 234/255, green: 242/255, blue: 248/255) // #EAF2F8
        }
    }

    static func lightSquareForPreview(_ type: ThemeType) -> Color {
        switch type {
        case .cherry:
            return Color(red: 244/255, green: 227/255, blue: 230/255)
        case .standard:
            return Color(red: 235/255, green: 236/255, blue: 208/255)
        case .darkNeon:
            return Color(red: 45/255, green: 55/255, blue: 80/255)
        case .midnightGold:
            return Color(red: 205/255, green: 186/255, blue: 150/255)
        case .sweetRose:
            return Color(red: 251/255, green: 228/255, blue: 236/255)
        case .onyx:
            return Color(red: 237/255, green: 237/255, blue: 237/255)
        case .aquamarine:
            return Color(red: 234/255, green: 242/255, blue: 248/255)
        }
    }

    static func darkSquareForPreview(_ type: ThemeType) -> Color {
        switch type {
        case .cherry:
            return Color(red: 150/255, green: 55/255, blue: 68/255)
        case .standard:
            return Color(red: 119/255, green: 149/255, blue: 86/255)
        case .darkNeon:
            return Color(red: 24/255, green: 30/255, blue: 46/255)
        case .midnightGold:
            return Color(red: 77/255, green: 58/255, blue: 47/255)
        case .sweetRose:
            return Color(red: 196/255, green: 115/255, blue: 140/255)
        case .onyx:
            return Color(red: 43/255, green: 43/255, blue: 43/255)
        case .aquamarine:
            return Color(red: 128/255, green: 181/255, blue: 214/255)
        }
    }

    static var highlightSquare: Color {
        switch current {
        case .cherry:
            return Color(red: 204/255, green: 42/255, blue: 60/255).opacity(0.6) // Cherry selection
        case .standard:
            return Color(red: 245/255, green: 246/255, blue: 130/255).opacity(0.8) // #f5f682
        case .darkNeon:
            return Color(red: 222/255, green: 62/255, blue: 130/255).opacity(0.6) // Muted magenta selection
        case .midnightGold:
            return Color(red: 212/255, green: 175/255, blue: 55/255).opacity(0.65) // Soft Amber/Gold selection
        case .sweetRose:
            return Color(red: 255/255, green: 92/255, blue: 138/255).opacity(0.65) // Hot pink selection
        case .onyx:
            return Color(red: 190/255, green: 190/255, blue: 190/255).opacity(0.55) // Silver selection
        case .aquamarine:
            return Color(red: 90/255, green: 190/255, blue: 240/255).opacity(0.6) // Sky blue selection
        }
    }
    
    static var lastMoveHighlight: Color {
        switch current {
        case .cherry:
            return Color(red: 214/255, green: 96/255, blue: 112/255).opacity(0.3) // Soft cherry last move
        case .standard:
            return Color(red: 245/255, green: 246/255, blue: 130/255).opacity(0.4) // Subtle standard yellow
        case .darkNeon:
            return Color(red: 0/255, green: 255/255, blue: 200/255).opacity(0.25) // Neon Cyan last move highlight
        case .midnightGold:
            return Color(red: 255/255, green: 179/255, blue: 0/255).opacity(0.25) // Warm Gold last move highlight
        case .sweetRose:
            return Color(red: 255/255, green: 133/255, blue: 162/255).opacity(0.3) // Soft rose last move highlight
        case .onyx:
            return Color(red: 200/255, green: 200/255, blue: 200/255).opacity(0.3) // Soft gray last move highlight
        case .aquamarine:
            return Color(red: 90/255, green: 190/255, blue: 240/255).opacity(0.3) // Soft sky blue last move highlight
        }
    }
    
    static var background: Color {
        switch current {
        case .cherry:
            return Color(red: 23/255, green: 11/255, blue: 14/255) // Deep wine-black
        case .standard:
            return Color(red: 48/255, green: 46/255, blue: 43/255) // #302E2B
        case .darkNeon:
            return Color(red: 11/255, green: 13/255, blue: 24/255) // #0B0D18
        case .midnightGold:
            return Color(red: 13/255, green: 13/255, blue: 17/255) // #0D0D11
        case .sweetRose:
            return Color(red: 31/255, green: 17/255, blue: 22/255) // #1F1116
        case .onyx:
            return Color(red: 18/255, green: 18/255, blue: 18/255) // #121212
        case .aquamarine:
            return Color(red: 14/255, green: 22/255, blue: 32/255) // #0E1620
        }
    }
    
    static var panelBackground: Color {
        switch current {
        case .cherry:
            return Color(red: 42/255, green: 22/255, blue: 26/255) // Dark wine panel
        case .standard:
            return Color(red: 38/255, green: 37/255, blue: 34/255) // #262522
        case .darkNeon:
            return Color(red: 18/255, green: 22/255, blue: 36/255) // #121624
        case .midnightGold:
            return Color(red: 24/255, green: 24/255, blue: 32/255) // #181820
        case .sweetRose:
            return Color(red: 45/255, green: 25/255, blue: 33/255) // #2D1921
        case .onyx:
            return Color(red: 30/255, green: 30/255, blue: 30/255) // #1E1E1E
        case .aquamarine:
            return Color(red: 22/255, green: 32/255, blue: 46/255) // #16202E
        }
    }
    
    static var textMain: Color {
        return Color.white
    }
    
    static var textSecondary: Color {
        switch current {
        case .cherry:
            return Color(red: 195/255, green: 154/255, blue: 160/255) // Dusty rose-gray
        case .standard:
            return Color(white: 0.6)
        case .darkNeon:
            return Color(red: 148/255, green: 163/255, blue: 184/255) // Slate 400
        case .midnightGold:
            return Color(red: 168/255, green: 158/255, blue: 140/255) // Slate-Sand
        case .sweetRose:
            return Color(red: 212/255, green: 168/255, blue: 182/255) // Dusty rose-gray
        case .onyx:
            return Color(red: 160/255, green: 160/255, blue: 160/255) // Neutral gray
        case .aquamarine:
            return Color(red: 150/255, green: 178/255, blue: 200/255) // Steel blue-gray
        }
    }
    
    // Dynamic Accent Colors (e.g. for buttons, sliders, active states)
    static var accentColor: Color {
        switch current {
        case .cherry:
            return Color(red: 204/255, green: 42/255, blue: 60/255) // Cherry red #CC2A3C
        case .standard:
            return Color(red: 119/255, green: 149/255, blue: 86/255) // Standard green
        case .darkNeon:
            return Color(red: 222/255, green: 62/255, blue: 130/255) // Muted Magenta #DE3E82
        case .midnightGold:
            return Color(red: 212/255, green: 175/255, blue: 55/255) // Burnished Gold #D4AF37
        case .sweetRose:
            return Color(red: 255/255, green: 82/255, blue: 123/255) // Sweet Pink #FF527B
        case .onyx:
            return Color(red: 224/255, green: 224/255, blue: 224/255) // Silver White #E0E0E0
        case .aquamarine:
            return Color(red: 79/255, green: 163/255, blue: 227/255) // Light Blue #4FA3E3
        }
    }
    
    // Theme-based result outcomes (Win/Loss)
    static var winColor: Color {
        switch current {
        case .cherry:
            return Color(red: 111/255, green: 203/255, blue: 147/255) // Fresh green (contrast)
        case .standard:
            return Color(red: 129/255, green: 182/255, blue: 76/255) // Green
        case .darkNeon:
            return Color(red: 0/255, green: 255/255, blue: 200/255) // Cyan
        case .midnightGold:
            return Color(red: 212/255, green: 175/255, blue: 55/255) // Gold
        case .sweetRose:
            return Color(red: 107/255, green: 224/255, blue: 163/255) // Minty Green
        case .onyx:
            return Color(red: 240/255, green: 240/255, blue: 240/255) // Bright White
        case .aquamarine:
            return Color(red: 56/255, green: 193/255, blue: 182/255) // Aqua Teal
        }
    }
    
    static var lossColor: Color {
        switch current {
        case .cherry:
            return Color(red: 204/255, green: 42/255, blue: 60/255) // Cherry red
        case .standard:
            return Color(red: 225/255, green: 61/255, blue: 61/255) // Red
        case .darkNeon:
            return Color(red: 222/255, green: 62/255, blue: 130/255) // Muted Magenta
        case .midnightGold:
            return Color(red: 192/255, green: 57/255, blue: 43/255) // Soft Crimson
        case .sweetRose:
            return Color(red: 255/255, green: 75/255, blue: 114/255) // Hot Crimson/Cherry
        case .onyx:
            return Color(red: 120/255, green: 120/255, blue: 120/255) // Dim Gray
        case .aquamarine:
            return Color(red: 240/255, green: 110/255, blue: 110/255) // Soft Coral
        }
    }
    
    // Board premove highlight color
    static var premoveColor: Color {
        switch current {
        case .cherry:
            return Color(red: 204/255, green: 42/255, blue: 60/255).opacity(0.25) // Cherry premove
        case .standard:
            return Color.red.opacity(0.25)
        case .darkNeon:
            return Color(red: 222/255, green: 62/255, blue: 130/255).opacity(0.25) // Muted magenta
        case .midnightGold:
            return Color(red: 230/255, green: 81/255, blue: 0/255).opacity(0.25) // Burnt Orange
        case .sweetRose:
            return Color(red: 255/255, green: 102/255, blue: 178/255).opacity(0.3) // Bubblegum Pink
        case .onyx:
            return Color(red: 220/255, green: 220/255, blue: 220/255).opacity(0.28) // Silver premove
        case .aquamarine:
            return Color(red: 255/255, green: 130/255, blue: 130/255).opacity(0.28) // Soft coral premove
        }
    }
    
    // Board hint highlight color
    static var hintColor: Color {
        switch current {
        case .cherry:
            return Color(red: 230/255, green: 192/255, blue: 121/255).opacity(0.6) // Warm gold hint
        case .standard:
            return Color.blue.opacity(0.55)
        case .darkNeon:
            return Color(red: 72/255, green: 214/255, blue: 188/255).opacity(0.6) // Soft teal hint
        case .midnightGold:
            return Color(red: 255/255, green: 179/255, blue: 0/255).opacity(0.6) // Glowing Warm Amber/Gold
        case .sweetRose:
            return Color(red: 214/255, green: 162/255, blue: 232/255).opacity(0.65) // Glowing Sweet Lavender
        case .onyx:
            return Color(red: 200/255, green: 200/255, blue: 200/255).opacity(0.55) // Glowing Silver
        case .aquamarine:
            return Color(red: 60/255, green: 160/255, blue: 240/255).opacity(0.6) // Glowing Sky Blue
        }
    }
    
    // Modern gradients for UI accents
    static var primaryGradient: LinearGradient {
        switch current {
        case .cherry:
            return LinearGradient(
                colors: [Color(red: 204/255, green: 42/255, blue: 60/255), Color(red: 156/255, green: 28/255, blue: 54/255)], // Cherry to wine
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .standard:
            return LinearGradient(
                colors: [Color(red: 119/255, green: 149/255, blue: 86/255), Color(red: 95/255, green: 120/255, blue: 68/255)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .darkNeon:
            return LinearGradient(
                colors: [Color(red: 219/255, green: 54/255, blue: 132/255), Color(red: 172/255, green: 48/255, blue: 142/255)], // Muted magenta to plum
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .midnightGold:
            return LinearGradient(
                colors: [Color(red: 206/255, green: 170/255, blue: 80/255), Color(red: 184/255, green: 141/255, blue: 62/255)], // Gold to muted bronze
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sweetRose:
            return LinearGradient(
                colors: [Color(red: 235/255, green: 110/255, blue: 135/255), Color(red: 222/255, green: 127/255, blue: 146/255)], // Rose to muted blush
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .onyx:
            return LinearGradient(
                colors: [Color(red: 224/255, green: 224/255, blue: 224/255), Color(red: 154/255, green: 154/255, blue: 154/255)], // Silver to graphite
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .aquamarine:
            return LinearGradient(
                colors: [Color(red: 79/255, green: 163/255, blue: 227/255), Color(red: 111/255, green: 211/255, blue: 232/255)], // Light blue to cyan
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

extension View {
    /// Subtle neutral elevation shadow for cards and primary buttons.
    func themedCardShadow() -> some View {
        shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}

struct ClassificationColor {
    static let brilliant = Color(red: 27/255, green: 172/255, blue: 166/255) // Teal
    static let great = Color(red: 92/255, green: 139/255, blue: 181/255) // Blue
    static let best = Color(red: 163/255, green: 206/255, blue: 39/255) // Green
    static let excellent = Color(red: 155/255, green: 199/255, blue: 0/255) // Light Green
    static let good = Color(red: 150/255, green: 175/255, blue: 139/255) // Grayish green
    static let inaccuracy = Color(red: 240/255, green: 193/255, blue: 92/255) // Yellow
    static let mistake = Color(red: 230/255, green: 145/255, blue: 44/255) // Orange
    static let blunder = Color(red: 202/255, green: 52/255, blue: 49/255) // Red
    static let missed = Color(red: 255/255, green: 119/255, blue: 105/255) // Pink/Red
    static let forced = Color(red: 140/255, green: 150/255, blue: 160/255) // Gray
    static let book = Color(red: 168/255, green: 136/255, blue: 101/255) // Brown
}

extension Font {
    static func roundedSystem(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        return Font.system(style, design: .rounded).weight(weight)
    }
    static func roundedSystem(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return Font.system(size: size, weight: weight, design: .rounded)
    }
}

struct ThemeToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                configuration.isOn.toggle()
            }
        }) {
            HStack {
                configuration.label
                    .font(.roundedSystem(.body, weight: .bold))
                    .foregroundColor(configuration.isOn ? Theme.textMain : Theme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    Theme.panelBackground
                    if configuration.isOn {
                        Theme.accentColor.opacity(0.12)
                    }
                }
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(configuration.isOn ? Theme.accentColor : Color.white.opacity(0.08), lineWidth: configuration.isOn ? 1.5 : 1)
            )
        }
        .buttonStyle(ThemeToggleButtonStyle())
    }
}

struct ThemeToggleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// Global uniform scale button style for consistent press feedback
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}


struct ScrollOffsetDetector: View {
    let coordinateSpace: String
    let tag: String
    
    init(coordinateSpace: String, tag: String? = nil) {
        self.coordinateSpace = coordinateSpace
        self.tag = tag ?? coordinateSpace
    }
    
    var body: some View {
        GeometryReader { geo in
            let val = geo.frame(in: .named(coordinateSpace)).minY
            Color.clear
                .preference(
                    key: TaggedScrollOffsetPreferenceKey.self,
                    value: [tag: val]
                )
        }
        .frame(height: 0)
    }
}

struct TaggedScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

// Backwards-compatible single-value preference key (kept for any legacy usage)
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct CollapsibleHeaderView: View {
    let title: String
    let subtitle: String
    let iconName: String
    /// Optional emoji shown instead of the SF Symbol (e.g. a cherry, for which no SF Symbol exists).
    var emojiIcon: String? = nil
    let scrollOffset: CGFloat
    var backAction: (() -> Void)? = nil
    
    // React to theme changes immediately
    @AppStorage("appTheme") private var appTheme = "cherry"
    
    var body: some View {
        let _ = appTheme // force dependency
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        let progress = min(1.0, max(0.0, -scrollOffset / 120.0))
        let cardRadius: CGFloat = isIPad ? 24 : 16
        
        // Interpolated values
        let iconSize: CGFloat = 48 - (progress * 24) // 48 → 24
        let titleSize: CGFloat = isIPad ? 34 : 28  // largeTitle base
        let collapsedTitleSize: CGFloat = isIPad ? 22 : 20  // title3 base
        let interpolatedTitleSize = titleSize - (progress * (titleSize - collapsedTitleSize))
        let totalHeight: CGFloat = 64 + (1.0 - progress) * 136 // 200 → 64
        let horizontalPadding: CGFloat = isIPad ? 24 : 16
        
        ZStack(alignment: .top) {
            // Floating Card Background (matching tab bar)
            RoundedRectangle(cornerRadius: cardRadius)
                .fill(Theme.panelBackground)
                .opacity(progress)
                .overlay(
                    RoundedRectangle(cornerRadius: cardRadius)
                        .stroke(Color.white.opacity(0.06 * progress), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2 * progress), radius: 8, x: 0, y: 3)
            
            // Content that morphs from centered to left-aligned
            GeometryReader { geo in
                let containerWidth = geo.size.width
                let innerPadding: CGFloat = isIPad ? 24 : 20
                
                let hasBack = backAction != nil
                let backButtonWidth: CGFloat = 75
                let backButtonHeight: CGFloat = 34
                let backShift: CGFloat = hasBack ? (backButtonWidth + 12) : 0
                
                // Back Button (if provided)
                if let backAction = backAction {
                    let expandedY: CGFloat = 16 + backButtonHeight / 2
                    let collapsedY: CGFloat = totalHeight / 2
                    let backY = expandedY + progress * (collapsedY - expandedY)
                    let backX = innerPadding + backButtonWidth / 2
                    
                    Button(action: backAction) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text(L10n.tr("back"))
                                .font(.roundedSystem(.subheadline, weight: .bold))
                        }
                        .foregroundColor(Theme.textMain)
                        .frame(width: backButtonWidth, height: backButtonHeight)
                        .background(progress > 0.5 ? Color.white.opacity(0.08) : Theme.panelBackground)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(progress > 0.5 ? 0.08 : 0.0), lineWidth: 1)
                        )
                    }
                    .position(x: backX, y: backY)
                }
                
                // Icon
                let iconExpandedX = containerWidth / 2
                let iconCollapsedX = innerPadding + backShift + iconSize / 2
                let iconX = iconExpandedX + progress * (iconCollapsedX - iconExpandedX)
                
                let iconExpandedY: CGFloat = totalHeight * 0.28
                let iconCollapsedY: CGFloat = totalHeight / 2
                let iconY = iconExpandedY + progress * (iconCollapsedY - iconExpandedY)
                
                Group {
                    if let emojiIcon = emojiIcon {
                        Text(emojiIcon)
                            .font(.system(size: iconSize))
                    } else {
                        Image(systemName: iconName)
                            .font(.system(size: iconSize, weight: .medium))
                            .foregroundStyle(Theme.accentColor)
                    }
                }
                .position(x: iconX, y: iconY)
                
                // Title
                let titleExpandedX = containerWidth / 2
                let titleCollapsedX = innerPadding + backShift + iconSize + 16 + estimateTextWidth(title, size: interpolatedTitleSize) / 2
                let titleX = titleExpandedX + progress * (titleCollapsedX - titleExpandedX)
                
                let titleExpandedY: CGFloat = totalHeight * 0.56
                let titleCollapsedY: CGFloat = totalHeight / 2
                let titleY = titleExpandedY + progress * (titleCollapsedY - titleExpandedY)
                
                Text(title)
                    .font(.system(size: interpolatedTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textMain)
                    .position(x: titleX, y: titleY)
                
                // Subtitle (fades out)
                Text(subtitle)
                    .font(.roundedSystem(.subheadline))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .frame(width: containerWidth)
                    .position(x: containerWidth / 2, y: totalHeight * 0.76)
                    .opacity(Double(1.0 - min(1.0, progress * 2.5)))
            }
        }
        .frame(height: totalHeight)
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isIPad ? 16 : 8)
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: progress)
    }
    
    private func estimateTextWidth(_ text: String, size: CGFloat) -> CGFloat {
        // Rough estimate: average character width ≈ 0.58 * font size for bold rounded
        return CGFloat(text.count) * size * 0.58
    }
}

