import SwiftUI
import ChessKit

struct CoordinateLearningView: View {
    @StateObject private var viewModel = CoordinateLearningViewModel()
    @ObservedObject private var scoresStore = CoordinateLearningStore.shared
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("appTheme") private var appTheme = "standard"
    var onBack: (() -> Void)? = nil
    
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        let _ = appLanguage
        let _ = appTheme
        ZStack {
            Theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                switch viewModel.gameState {
                case .menu:
                    menuView
                case .playing:
                    gameView
                case .gameOver:
                    gameOverView
                }
            }
        }
    }
    
    // MARK: - Menu Screen
    private var menuView: some View {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        return ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    ScrollOffsetDetector(coordinateSpace: "coordinateTrainerContainer")
                    
                    Spacer().frame(height: isIPad ? 224 : 216)
                    
                    // Modes Selection / Action Buttons (Packed up high!)
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.tr("select_mode"))
                            .font(.roundedSystem(.headline, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        VStack(spacing: 14) {
                            // Rated Play Button Card (Styled like Endless!)
                            Button(action: { viewModel.startGame(mode: .rated) }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(L10n.tr("start_rated"))
                                            .font(.roundedSystem(.headline, weight: .bold))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "play.fill")
                                            .foregroundColor(Theme.accentColor)
                                    }
                                    
                                    Text(L10n.tr("rated_desc"))
                                        .font(.roundedSystem(.caption))
                                        .foregroundColor(Theme.textSecondary)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Theme.panelBackground)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            // Endless Play Button Card
                            Button(action: { viewModel.startGame(mode: .endless) }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(L10n.tr("start_endless"))
                                            .font(.roundedSystem(.headline, weight: .bold))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "play.fill")
                                            .foregroundColor(Theme.accentColor)
                                    }
                                    
                                    Text(L10n.tr("endless_desc"))
                                        .font(.roundedSystem(.caption))
                                        .foregroundColor(Theme.textSecondary)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Theme.panelBackground)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal)
                    }
                    
                    // Settings Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.tr("settings"))
                            .font(.roundedSystem(.headline, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        Toggle(L10n.tr("board_coordinates"), isOn: $viewModel.showLabels)
                            .toggleStyle(ThemeToggleStyle())
                            .padding(.horizontal)
                    }
                    
                    // High Scores Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.tr("high_scores"))
                            .font(.roundedSystem(.headline, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            // Rated card
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(Theme.accentColor)
                                    Text(appLanguage == "de" ? "Rated (1 Minute)" : "Rated (1 Minute)")
                                        .font(.roundedSystem(.subheadline, weight: .bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                
                                HStack(spacing: 16) {
                                    scoreSubRow(title: L10n.tr("labeled"), value: "\(scoresStore.scores.ratedWithLabels) Elo")
                                    Spacer()
                                    scoreSubRow(title: L10n.tr("unlabeled"), value: "\(scoresStore.scores.ratedWithoutLabels) Elo")
                                }
                            }
                            .padding()
                            .background(Theme.panelBackground)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                            
                            // Endless card
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "infinity")
                                        .foregroundColor(Theme.accentColor)
                                    Text(appLanguage == "de" ? "Endless (Fehlerfrei)" : "Endless (Flawless)")
                                        .font(.roundedSystem(.subheadline, weight: .bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                
                                HStack(spacing: 16) {
                                    endlessScoreSubRow(
                                        title: L10n.tr("labeled"),
                                        score: scoresStore.scores.endlessWithLabels,
                                        time: scoresStore.scores.endlessWithLabelsAvgTime
                                    )
                                    Spacer()
                                    endlessScoreSubRow(
                                        title: L10n.tr("unlabeled"),
                                        score: scoresStore.scores.endlessWithoutLabels,
                                        time: scoresStore.scores.endlessWithoutLabelsAvgTime
                                    )
                                }
                            }
                            .padding()
                            .background(Theme.panelBackground)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 24)
                }
            }
            
            // Collapsible Header View at top
            VStack(spacing: 0) {
                Color.clear.frame(height: 0)
                CollapsibleHeaderView(
                    title: L10n.tr("coord_title"),
                    subtitle: L10n.tr("coord_desc"),
                    iconName: "target",
                    scrollOffset: scrollOffset,
                    backAction: onBack
                )
            }
            .background(
                Theme.background
                    .opacity(scrollOffset < -5 ? 1.0 : 0.0)
                    .ignoresSafeArea(edges: .top)
            )
            .animation(.easeInOut(duration: 0.15), value: scrollOffset < -5)
        }
        .coordinateSpace(name: "coordinateTrainerContainer")
        .onPreferenceChange(TaggedScrollOffsetPreferenceKey.self) { values in
            if let val = values["coordinateTrainerContainer"] {
                self.scrollOffset = val
            }
        }
    }
    
    private func scoreSubRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.roundedSystem(.caption))
                .foregroundColor(Theme.textSecondary)
            Text(value)
                .font(.roundedSystem(.subheadline, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    private func endlessScoreSubRow(title: String, score: Int, time: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.roundedSystem(.caption))
                .foregroundColor(Theme.textSecondary)
            Text("\(score) \(L10n.tr("pts"))")
                .font(.roundedSystem(.subheadline, weight: .bold))
                .foregroundColor(.white)
            if score > 0 {
                Text(L10n.tr("average") + String(format: ": %.2fs", time))
                    .font(.roundedSystem(size: 10))
                    .foregroundColor(Theme.accentColor)
            }
        }
    }
    
    // MARK: - Active Game Screen
    private var gameView: some View {
        VStack(spacing: 0) {
            // Game Header / Stats Bar
            HStack {
                Button(action: { viewModel.reset() }) {
                    Text(L10n.tr("abort"))
                        .font(.roundedSystem(.body, weight: .bold))
                        .foregroundColor(Theme.accentColor)
                }
                .buttonStyle(ScaleButtonStyle())
                
                Spacer()
                
                if viewModel.selectedMode == .rated {
                    HStack(spacing: 16) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(viewModel.currentElo) Elo")
                                .font(.roundedSystem(.headline, weight: .bold))
                                .foregroundColor(Theme.accentColor)
                            Text("\(viewModel.correctCount)✓ \(viewModel.incorrectCount)✗")
                                .font(.roundedSystem(.caption))
                                .foregroundColor(Theme.textSecondary)
                        }
                        
                        Text(String(format: "%02d:%02d", viewModel.timeLeft / 60, viewModel.timeLeft % 60))
                            .font(.system(.title3, design: .monospaced).bold())
                            .foregroundColor(viewModel.timeLeft < 10 ? Theme.lossColor : .white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                    }
                } else {
                    HStack(spacing: 16) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(viewModel.correctCount) \(L10n.tr("squares"))")
                                .font(.roundedSystem(.headline, weight: .bold))
                                .foregroundColor(Theme.accentColor)
                            Text(L10n.tr("average") + String(format: ": %.2fs", viewModel.currentAverageTime))
                                .font(.roundedSystem(.caption))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }
            }
            .padding()
            .background(Theme.panelBackground)
            
            Spacer(minLength: 0)
            
            // Centered target square indicator
            VStack(spacing: 6) {
                Text(L10n.tr("find_square"))
                    .font(.roundedSystem(.subheadline))
                    .foregroundColor(Theme.textSecondary)
                
                Text(viewModel.targetSquare?.coordinateString.uppercased() ?? "")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .scaleEffect(viewModel.showGreenFlash ? 1.15 : (viewModel.showRedFlash ? 0.9 : 1.0))
                    .animation(.spring(response: 0.15, dampingFraction: 0.5), value: viewModel.targetSquare)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                viewModel.showGreenFlash ? Color.green.opacity(0.2) :
                                (viewModel.showRedFlash ? Color.red.opacity(0.2) : Color.white.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                    )
            }
            .padding(.vertical, 20)
            
            Spacer(minLength: 0)
            
            // Empty Board for training
            LearningBoardView(viewModel: viewModel)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            
            Spacer(minLength: 0)
        }
    }
    
    // MARK: - Game Over Screen
    private var gameOverView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: viewModel.isNewHighScore ? "trophy.fill" : "flag.checkered")
                .font(.system(size: 72))
                .foregroundColor(viewModel.isNewHighScore ? Theme.highlightSquare : .white)
                .scaleEffect(viewModel.isNewHighScore ? 1.1 : 1.0)
                .padding(.bottom, 8)
            
            Text(L10n.tr("game_finished"))
                .font(.roundedSystem(.largeTitle, weight: .bold))
                .foregroundColor(.white)
            
            if viewModel.isNewHighScore {
                Text(L10n.tr("new_high_score"))
                    .font(.roundedSystem(.headline, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 16)
                    .background(Theme.accentColor)
                    .cornerRadius(16)
            }
            
            // Score summary card
            VStack(spacing: 16) {
                if viewModel.selectedMode == .rated {
                    scoreSummaryRow(title: L10n.tr("achieved_rating"), value: "\(viewModel.finalElo) Elo")
                    scoreSummaryRow(title: L10n.tr("correct_squares"), value: "\(viewModel.correctCount)")
                    scoreSummaryRow(title: L10n.tr("incorrect_squares"), value: "\(viewModel.incorrectCount)")
                } else {
                    scoreSummaryRow(title: L10n.tr("endless_score"), value: "\(viewModel.finalScore) \(L10n.tr("pts"))")
                    scoreSummaryRow(title: L10n.tr("correct_squares"), value: "\(viewModel.correctCount)")
                    let timeUnit = appLanguage == "de" ? "Feld" : "Square"
                    scoreSummaryRow(title: appLanguage == "de" ? "Durchschnittszeit" : "Average Time", value: String(format: "%.2fs / \(timeUnit)", viewModel.currentAverageTime))
                }
            }
            .padding()
            .background(Theme.panelBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: { viewModel.startGame(mode: viewModel.selectedMode) }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text(L10n.tr("play_again"))
                    }
                    .font(.roundedSystem(.headline, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accentColor)
                    .cornerRadius(16)
                }
                .buttonStyle(ScaleButtonStyle())
                
                Button(action: { viewModel.reset() }) {
                    Text(L10n.tr("main_menu"))
                        .font(.roundedSystem(.headline, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.panelBackground)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
    
    private func scoreSummaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.roundedSystem(.body))
                .foregroundColor(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.roundedSystem(.headline, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Mini empty Chessboard for training
struct LearningBoardView: View {
    @AppStorage("appTheme") private var appTheme = "standard"
    @AppStorage("appLanguage") private var appLanguage = "de"
    @ObservedObject var viewModel: CoordinateLearningViewModel
    
    var body: some View {
        let _ = appLanguage
        let _ = appTheme
        GeometryReader { geometry in
            let boardSize = geometry.size.width
            let squareSize = boardSize / 8
            
            VStack(spacing: 0) {
                ForEach((0..<8).reversed(), id: \.self) { rank in
                    HStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { file in
                            let square = Square("\(Square.File(file + 1).rawValue)\(rank + 1)")
                            let isLight = (file + rank) % 2 != 0
                            
                            let isFlashTarget = viewModel.lastTappedSquare == square
                            
                            ZStack {
                                Rectangle()
                                    .fill(isLight ? Theme.lightSquare : Theme.darkSquare)
                                    .frame(width: squareSize, height: squareSize)
                                
                                // Flash color
                                if isFlashTarget && viewModel.showGreenFlash {
                                    Rectangle()
                                        .fill(Color.green.opacity(0.6))
                                        .frame(width: squareSize, height: squareSize)
                                }
                                if isFlashTarget && viewModel.showRedFlash {
                                    Rectangle()
                                        .fill(Color.red.opacity(0.6))
                                        .frame(width: squareSize, height: squareSize)
                                }
                                
                                if viewModel.showLabels {
                                    if file == 0 {
                                        Text(String(square.rank.value))
                                            .font(.system(size: squareSize * 0.18, weight: .bold, design: .rounded))
                                            .foregroundColor(isLight ? Theme.darkSquare : Theme.lightSquare)
                                            .position(x: squareSize * 0.15, y: squareSize * 0.15)
                                    }
                                    
                                    if rank == 0 {
                                        Text(square.file.rawValue)
                                            .font(.system(size: squareSize * 0.18, weight: .bold, design: .rounded))
                                            .foregroundColor(isLight ? Theme.darkSquare : Theme.lightSquare)
                                            .position(x: squareSize * 0.85, y: squareSize * 0.85)
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectSquare(square)
                            }
                        }
                    }
                }
            }
            .border(Color.black, width: 2)
            .frame(width: boardSize, height: boardSize)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
