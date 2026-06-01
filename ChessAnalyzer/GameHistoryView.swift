import SwiftUI

struct GameHistoryView: View {
    @ObservedObject var store = GameHistoryStore.shared
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("appTheme") private var appTheme = "standard"
    
    private let displayOrder: [MoveClassification] = [
        .brilliant, .great, .best, .excellent, .good, .book, .inaccuracy, .mistake, .blunder
    ]
    
    var body: some View {
        let _ = appLanguage
        let _ = appTheme
        ZStack {
            Theme.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Centered Header
                    VStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundStyle(Theme.primaryGradient)
                            .padding(.bottom, 8)
                        
                        Text(L10n.tr("game_history"))
                            .font(.largeTitle.bold())
                            .foregroundColor(Theme.textMain)
                        
                        Text(L10n.tr("game_history_desc"))
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .padding(.top, 24)
                    
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
                                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }
}

struct GameRowView: View {
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("appTheme") private var appTheme = "standard"
    let game: SavedGame
    let displayOrder: [MoveClassification]
    @ObservedObject var store = GameHistoryStore.shared
    
    private var colorCircle: some View {
        Circle()
            .fill(game.playerColor == "white" ? Color.white : Color.black)
            .frame(width: 14, height: 14)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.4), lineWidth: game.playerColor == "black" ? 1 : 0)
            )
    }
    
    private var resultColor: Color {
        if game.gameResult.contains("Schachmatt") {
            return game.gameResult.contains("Weiß") && game.playerColor == "white" ? Theme.winColor :
                   game.gameResult.contains("Schwarz") && game.playerColor == "black" ? Theme.winColor : Theme.lossColor
        }
        return .gray
    }
    
    var body: some View {
        let _ = appLanguage
        let _ = appTheme
        VStack(alignment: .leading, spacing: 8) {
            // Top row: date + color + result
            HStack(spacing: 12) {
                colorCircle
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.translateResult(game.gameResult))
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundColor(resultColor)
                    Text(game.date, style: .date)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
                
                // Final Elo
                VStack(alignment: .trailing, spacing: 2) {
                    Text(L10n.tr("final_elo"))
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                    Text("\(game.finalElo)")
                        .font(.system(.headline, design: .rounded).bold())
                        .foregroundColor(Theme.accentColor)
                }
                
                Button(action: {
                    store.delete(game: game)
                }) {
                    Image(systemName: "trash")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(Theme.lossColor.opacity(0.8))
                        .padding(6)
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
                    HStack(spacing: 6) {
                        ForEach(nonZero, id: \.self) { cls in
                            HStack(spacing: 3) {
                                MoveClassificationBadge(classification: cls, size: 14)
                                Text("\(counts[cls]!)")
                                    .font(.system(.caption2, design: .rounded).monospacedDigit().bold())
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.07))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}
