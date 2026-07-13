import SwiftUI

struct GameHistoryView: View {
    var isActive: Bool = true
    @ObservedObject var store = GameHistoryStore.shared
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("appTheme") private var appTheme = "cherry"
    
    private let displayOrder: [MoveClassification] = [
        .brilliant, .great, .best, .excellent, .good, .book, .inaccuracy, .mistake, .blunder
    ]
    
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        let _ = appLanguage
        let _ = appTheme
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        ZStack(alignment: .top) {
            Theme.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    if isActive {
                        ScrollOffsetDetector(coordinateSpace: "historyContainer")
                    }
                    
                    Spacer().frame(height: isIPad ? 224 : 216)
                    
                    if !store.games.isEmpty {
                        Button(action: {
                            store.clearAll()
                            HapticManager.shared.playNotification(.warning)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                Text(L10n.tr("clear_history"))
                            }
                            .font(.roundedSystem(.subheadline, weight: .bold))
                            .foregroundColor(Theme.lossColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Theme.lossColor.opacity(0.12))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.lossColor.opacity(0.25), lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.bottom, 4)
                    }
                    
                    if store.games.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 48))
                                .foregroundColor(Theme.textSecondary.opacity(0.3))
                            Text(L10n.tr("no_saved_games"))
                                .font(.roundedSystem(.headline))
                                .foregroundColor(Theme.textSecondary)
                            Text(L10n.tr("complete_game_to_view"))
                                .font(.roundedSystem(.subheadline))
                                .foregroundColor(Theme.textSecondary.opacity(0.6))
                        }
                        .padding(.vertical, 32)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(store.games) { game in
                                GameRowView(game: game, displayOrder: displayOrder)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Theme.panelBackground)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Theme.line.opacity(0.06), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24)
            }
            
            // Collapsible Header View at top
            VStack(spacing: 0) {
                Color.clear.frame(height: 0)
                CollapsibleHeaderView(
                    title: L10n.tr("game_history"),
                    subtitle: L10n.tr("game_history_desc"),
                    iconName: "clock.arrow.circlepath",
                    scrollOffset: scrollOffset
                )
            }
            .background(
                Theme.background
                    .opacity(scrollOffset < -5 ? 1.0 : 0.0)
                    .ignoresSafeArea(edges: .top)
            )
            .animation(.easeInOut(duration: 0.15), value: scrollOffset < -5)
        }
        .coordinateSpace(name: "historyContainer")
        .onPreferenceChange(TaggedScrollOffsetPreferenceKey.self) { values in
            if let val = values["historyContainer"] {
                self.scrollOffset = val
            }
        }
    }
}

struct GameRowView: View {
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("appTheme") private var appTheme = "cherry"
    let game: SavedGame
    let displayOrder: [MoveClassification]
    @ObservedObject var store = GameHistoryStore.shared
    
    private var colorCircle: some View {
        Circle()
            .fill(game.playerColor == "white" ? Color.white : Color.black)
            .frame(width: 20, height: 20)
            .overlay(
                Circle()
                    .stroke(Theme.line.opacity(0.4), lineWidth: game.playerColor == "black" ? 1 : 0)
            )
    }
    
    private var gameModeBadge: some View {
        let isChallenge = game.isChallenge
        return HStack(spacing: 4) {
            Image(systemName: isChallenge ? "flag.checkered" : "cpu")
                .font(.system(size: 9, weight: .bold))
            Text(isChallenge ? L10n.tr("challenge_mode") : L10n.tr("normal_game"))
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundColor(isChallenge ? Theme.accentColor : Theme.textSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background((isChallenge ? Theme.accentColor : Theme.textSecondary).opacity(0.15))
        .cornerRadius(6)
    }

    private var resultColor: Color {
        if game.gameResult.contains("Schachmatt") || game.gameResult.lowercased().contains("mate") {
            let isWhiteWinner = game.gameResult.contains("Weiß") || game.gameResult.lowercased().contains("white")
            let won = (isWhiteWinner && game.playerColor == "white") || (!isWhiteWinner && game.playerColor == "black")
            return won ? Theme.winColor : Theme.lossColor
        }
        if game.gameResult.contains("Zeitüberschreitung") || game.gameResult.lowercased().contains("time") {
            let isWhiteLoser = game.gameResult.contains("Weiß") || game.gameResult.lowercased().contains("white")
            let won = (isWhiteLoser && game.playerColor == "black") || (!isWhiteLoser && game.playerColor == "white")
            return won ? Theme.winColor : Theme.lossColor
        }
        return .gray
    }
    
    var body: some View {
        let _ = appLanguage
        let _ = appTheme
        VStack(alignment: .leading, spacing: 12) {
            // Top row: date + color + result
            HStack(spacing: 16) {
                colorCircle
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.translateResult(game.gameResult))
                        .font(.system(.headline, design: .rounded).bold())
                        .foregroundColor(resultColor)
                    HStack(spacing: 8) {
                        Text(game.date, style: .date)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(Theme.textSecondary)
                        gameModeBadge
                    }
                }
                
                Spacer()
                
                // Final Elo
                VStack(alignment: .trailing, spacing: 4) {
                    Text(L10n.tr("final_elo"))
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                    Text("\(game.finalElo)")
                        .font(.system(.title2, design: .rounded).bold())
                        .foregroundColor(Theme.accentColor)
                }
                
                Button(action: {
                    store.delete(game: game)
                }) {
                    Image(systemName: "trash")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(Theme.lossColor.opacity(0.8))
                        .padding(8)
                        .background(Theme.lossColor.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Classification badges
            let counts = game.countsDict
            let nonZero = displayOrder.filter { (counts[$0] ?? 0) > 0 }
            if !nonZero.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(nonZero, id: \.self) { cls in
                            HStack(spacing: 5) {
                                MoveClassificationBadge(classification: cls, size: 22)
                                Text("\(counts[cls]!)")
                                    .font(.system(.body, design: .rounded).monospacedDigit().bold())
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.line.opacity(0.07))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Theme.line.opacity(0.06), lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
        .padding(.vertical, 12)
    }
}
