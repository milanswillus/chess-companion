//
//  ContentView.swift
//  ChessAnalyzer
//
//  Created by milxn on 12.05.26.
//

import SwiftUI
import ChessKit

enum PlayGameMode {
    case none
    case bot
    case friend
}

struct ContentView: View {
    @Namespace private var tabNamespace
    @StateObject private var viewModel = GameViewModel()
    @StateObject private var analyzer = StockfishAnalyzer()
    @ObservedObject private var historyStore = GameHistoryStore.shared
    @State private var selectedTab: Int = {
        if FileManager.default.fileExists(atPath: "/Users/milanswillus/dev/ChessAnalyzer/run_simulation.txt") {
            return 2
        }
        return 0
    }()
    @State private var gameSaved = false
    
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("appTheme") private var appTheme = "standard"
    @State private var isGameActive = false
    @State private var evaluationCache: [String: (bestMove: String, score: Int, mate: Int?)] = [:]
    @State private var selectedElo: Double = 1500
    
    @State private var isTimed = false
    @State private var timeControlMinutes: Double = 10
    @State private var timeControlIncrementSeconds: Double = 3
    @State private var showAnalysis = true
    @State private var lastClassification: MoveClassification? = nil
    @State private var showClassificationBadge = false
    @State private var showBestMoveArrow: (start: Square, end: Square)? = nil
    @State private var isAnalyzingHint = false
    @State private var hintBestMove: (start: Square, end: Square)? = nil
    @AppStorage("showCounters") private var showCounters = true
    @AppStorage("showEvalBar") private var showEvalBar = false
    @AppStorage("showLiveElo") private var showAccuracy = false
    @AppStorage("botName") private var botName = "Stockfish"
    
    // Game Mode Selection and Setup
    @State private var selectedGameMode: PlayGameMode = .none
    @State private var allowHints = true
    @State private var showBestMovesRetrospectively = false
    @State private var flipBoardAfterMoves = true
    
    // Analysis Tab State
    @StateObject private var analysisViewModel: GameViewModel = {
        let vm = GameViewModel()
        vm.isAnalysisMode = true
        return vm
    }()
    @State private var isAnalysisGameActive = false
    @State private var showAnalysisClassificationBadge = false
    @State private var lastAnalysisClassification: MoveClassification? = nil
    @State private var showAnalysisBestMoveArrow: (start: Square, end: Square)? = nil
    @State private var isCalculatingAnalysisBestMove: Piece.Color? = nil
    @State private var activeBestMoveArrowOwner: (color: Piece.Color, isCurrent: Bool)? = nil
    @State private var showAnalysisTabAnalysis = true
    @State private var showAnalysisEvalBar = false
    @State private var analysisSelectedElo: Double = 1500
    @State private var isAnalysisTimed = false
    @State private var analysisTimeControlMinutes: Double = 10
    @State private var isAnalyzingAnalysisHint = false
    @State private var analysisHintBestMove: (start: Square, end: Square)? = nil
    @State private var analysisScrollOffset: CGFloat = 0
    @State private var modeSelectionScrollOffset: CGFloat = 0
    @State private var setupScrollOffset: CGFloat = 0
    @State private var friendSetupScrollOffset: CGFloat = 0
    
    // Computed properties for history explorer
    var displayClassification: MoveClassification? {
        if viewModel.isExploringHistory {
            return viewModel.history[viewModel.historyIndex].classification
        }
        return lastClassification
    }
    
    var currentOpeningName: String? {
        openingName(for: viewModel)
    }
    
    func openingName(for vm: GameViewModel) -> String? {
        if vm.history.isEmpty {
            let fen = vm.displayBoard.position.fen
            let simp = Opening.simplifiedFEN(fen)
            if let opening = Opening.fenToOpeningMap[simp] {
                return appLanguage == "de" ? opening.nameGerman : opening.name
            }
            return nil
        }
        
        let maxIndex = min(vm.historyIndex, vm.history.count - 1)
        for index in stride(from: maxIndex, through: 0, by: -1) {
            let fen = vm.history[index].board.position.fen
            let simp = Opening.simplifiedFEN(fen)
            if let opening = Opening.fenToOpeningMap[simp] {
                return appLanguage == "de" ? opening.nameGerman : opening.name
            }
        }
        
        let fen = vm.displayBoard.position.fen
        let simp = Opening.simplifiedFEN(fen)
        if let opening = Opening.fenToOpeningMap[simp] {
            return appLanguage == "de" ? opening.nameGerman : opening.name
        }
        
        return nil
    }
    
    var hindsightNode: HistoryNode? {
        if viewModel.isExploringHistory {
            if viewModel.historyIndex < viewModel.history.count {
                return viewModel.history[viewModel.historyIndex]
            }
        } else {
            if viewModel.history.count >= 2 {
                let lastNode = viewModel.history.last
                if lastNode?.movingColor == viewModel.engineColor {
                    return viewModel.history[viewModel.history.count - 2]
                }
            }
        }
        return nil
    }
    
    func lastHistoryNode(for color: Piece.Color) -> HistoryNode? {
        let maxIndex = viewModel.isExploringHistory ? viewModel.historyIndex : (viewModel.history.count - 1)
        guard maxIndex >= 0, maxIndex < viewModel.history.count else { return nil }
        for index in (0...maxIndex).reversed() {
            let node = viewModel.history[index]
            if node.movingColor == color {
                return node
            }
        }
        return nil
    }
    
    var isCheckmate: Bool {
        isCheckmate(for: viewModel)
    }
    
    func isCheckmate(for vm: GameViewModel) -> Bool {
        if case .checkmate = vm.board.state {
            return true
        }
        if case .checkmate = vm.displayBoard.state {
            return true
        }
        if vm.gameResult.contains("Schachmatt") || vm.gameResult.lowercased().contains("mate") {
            return true
        }
        return false
    }
    
    var displayBestMoveStr: String? {
        if viewModel.isExploringHistory {
            return viewModel.history[viewModel.historyIndex].bestMoveStr
        }
        return viewModel.lastBestMoveStr
    }
    
    var displayFenBefore: String? {
        if viewModel.isExploringHistory {
            return viewModel.history[viewModel.historyIndex].fenBefore
        }
        return viewModel.lastPlayerMoveFenBefore
    }
    
    var displayMovingColor: Piece.Color {
        if viewModel.isExploringHistory {
            return viewModel.history[viewModel.historyIndex].movingColor ?? viewModel.playerColor
        }
        return viewModel.history.last?.movingColor ?? viewModel.playerColor
    }
    
    var displayMate: Int? {
        if viewModel.isExploringHistory {
            return viewModel.history[viewModel.historyIndex].mate
        }
        return viewModel.history.last?.mate
    }
    
    func mateIn(for color: Piece.Color, vm: GameViewModel) -> Int? {
        let displayMate = vm.isExploringHistory ? vm.history[vm.historyIndex].mate : vm.history.last?.mate
        guard let m = displayMate else { return nil }
        if color == .white && m > 0 { return m }
        if color == .black && m < 0 { return abs(m) }
        return nil
    }
    
    func mateIn(for color: Piece.Color) -> Int? {
        mateIn(for: color, vm: viewModel)
    }
    
    // Computed properties for Analysis Tab
    var displayAnalysisClassification: MoveClassification? {
        if analysisViewModel.isExploringHistory {
            return analysisViewModel.history[analysisViewModel.historyIndex].classification
        }
        return lastAnalysisClassification
    }
    
    var analysisCurrentOpeningName: String? {
        openingName(for: analysisViewModel)
    }
    
    var analysisHindsightNode: HistoryNode? {
        if analysisViewModel.isExploringHistory {
            if analysisViewModel.historyIndex < analysisViewModel.history.count {
                return analysisViewModel.history[analysisViewModel.historyIndex]
            }
        } else {
            if analysisViewModel.history.count >= 2 {
                return analysisViewModel.history[analysisViewModel.history.count - 2]
            }
        }
        return nil
    }
    
    var isAnalysisCheckmate: Bool {
        isCheckmate(for: analysisViewModel)
    }
    
    var displayAnalysisBestMoveStr: String? {
        if analysisViewModel.isExploringHistory {
            return analysisViewModel.history[analysisViewModel.historyIndex].bestMoveStr
        }
        return analysisViewModel.lastBestMoveStr
    }
    
    var displayAnalysisFenBefore: String? {
        if analysisViewModel.isExploringHistory {
            return analysisViewModel.history[analysisViewModel.historyIndex].fenBefore
        }
        return analysisViewModel.lastPlayerMoveFenBefore
    }
    
    var displayAnalysisMovingColor: Piece.Color {
        if analysisViewModel.isExploringHistory {
            return analysisViewModel.history[analysisViewModel.historyIndex].movingColor ?? analysisViewModel.playerColor
        }
        return analysisViewModel.history.last?.movingColor ?? analysisViewModel.playerColor
    }
    
    private func findKingSquare(for color: Piece.Color, on board: Board) -> Square? {
        for square in Square.allCases {
            if let piece = board.position.piece(at: square),
               piece.kind == .king,
               piece.color == color {
                return square
            }
        }
        return nil
    }
    
    private func resetHints() {
        viewModel.hintStep = 0
        viewModel.hintCorrectSquare = nil
        viewModel.hintAlternativeSquare = nil
        showBestMoveArrow = nil
        hintBestMove = nil
        isAnalyzingHint = false
    }
    
    private func findPlausiblePawnOrPiece(correctSquare: Square, board: Board, playerColor: Piece.Color) -> Square? {
        for square in Square.allCases {
            if square != correctSquare,
               let piece = board.position.piece(at: square),
               piece.color == playerColor,
               !board.legalMoves(forPieceAt: square).isEmpty {
                return square
            }
        }
        return nil
    }
    
    private func requestHint() {
        guard viewModel.isPlayerTurn && !viewModel.isProcessing else { return }
        
        if viewModel.hintStep == 0 {
            isAnalyzingHint = true
            let fen = viewModel.board.position.fen
            let activeColor = viewModel.isFriendMode ? viewModel.board.position.sideToMove : viewModel.playerColor
            Task {
                let result = await evaluateWithCache(fen: fen, depth: 10, limitSkill: false, movetime: 300)
                
                await MainActor.run {
                    isAnalyzingHint = false
                    guard viewModel.board.position.fen == fen else { return }
                    
                    if let bestMoveStr = result?.bestMove,
                       let move = EngineLANParser.parse(move: bestMoveStr, for: activeColor, in: viewModel.board.position) {
                        
                        hintBestMove = (start: move.start, end: move.end)
                        viewModel.hintCorrectSquare = move.start
                        viewModel.hintAlternativeSquare = findPlausiblePawnOrPiece(correctSquare: move.start, board: viewModel.board, playerColor: activeColor)
                        withAnimation {
                            viewModel.hintStep = 1
                            showBestMoveArrow = nil
                        }
                    }
                }
            }
        } else if viewModel.hintStep == 1 {
            withAnimation {
                viewModel.hintStep = 2
                showBestMoveArrow = nil
            }
        } else if viewModel.hintStep == 2 {
            withAnimation {
                viewModel.hintStep = 3
                if let bestMove = hintBestMove {
                    showBestMoveArrow = bestMove
                }
            }
        } else {
            withAnimation {
                resetHints()
            }
        }
    }
    
    var tabBarHeightPadding: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 92 : 74
    }

    var body: some View {
        let _ = appLanguage
        let _ = appTheme
        ZStack(alignment: .bottom) {
            Theme.background
                .ignoresSafeArea()
            
            // Tab Contents
            ZStack {
                gameTab
                    .opacity(selectedTab == 0 ? 1 : 0)
                    .disabled(selectedTab != 0)
                    .padding(.bottom, tabBarHeightPadding)
                
                GameHistoryView(isActive: selectedTab == 1)
                    .opacity(selectedTab == 1 ? 1 : 0)
                    .disabled(selectedTab != 1)
                    .padding(.bottom, tabBarHeightPadding)
                
                OpeningTrainerView(isActive: selectedTab == 2)
                    .opacity(selectedTab == 2 ? 1 : 0)
                    .disabled(selectedTab != 2)
                    .padding(.bottom, tabBarHeightPadding)
                
                analysisTab
                    .opacity(selectedTab == 3 ? 1 : 0)
                    .disabled(selectedTab != 3)
                    .padding(.bottom, tabBarHeightPadding)
                
                SettingsView(isActive: selectedTab == 4)
                    .opacity(selectedTab == 4 ? 1 : 0)
                    .disabled(selectedTab != 4)
                    .padding(.bottom, tabBarHeightPadding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transaction { $0.animation = nil }
            
            // Custom floating tab bar overlay
            customTabBar
            
            // Promotion Picker Overlay (Clean, premium custom modal)
            let activePromoVM = (selectedTab == 3) ? analysisViewModel : viewModel
            if activePromoVM.showPromotionPicker || activePromoVM.showPremovePromotionPicker {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Text(appLanguage == "de" ? "Bauernumwandlung" : "Pawn Promotion")
                            .font(.system(.headline, design: .rounded).bold())
                            .foregroundColor(.white)
                            .tracking(1.0)
                        
                        HStack(spacing: 16) {
                            let promotingColor = activePromoVM.showPremovePromotionPicker ? activePromoVM.playerColor : activePromoVM.board.position.sideToMove
                            let colorPrefix = promotingColor == .white ? "w" : "b"
                            let options: [(Piece.Kind, String)] = [
                                (.queen, "q"),
                                (.rook, "r"),
                                (.bishop, "b"),
                                (.knight, "n")
                            ]
                            
                            ForEach(options, id: \.0) { kind, suffix in
                                Button(action: {
                                    withAnimation {
                                        if activePromoVM.showPremovePromotionPicker {
                                            activePromoVM.completePremovePromotion(to: kind)
                                        } else {
                                            activePromoVM.completePromotion(to: kind)
                                        }
                                    }
                                }) {
                                    VStack(spacing: 8) {
                                        Image(colorPrefix + suffix)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 44, height: 44)
                                            .padding(10)
                                            .background(Theme.panelBackground)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                        
                                        Text(pieceKindName(kind))
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundColor(Theme.textSecondary)
                                    }
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 28)
                    .background(Theme.panelBackground)
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.55), radius: 20, x: 0, y: 10)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
                .zIndex(200)
            }
        }
        .environmentObject(analyzer)
        .onReceive(NotificationCenter.default.publisher(for: .didMakeMove)) { notification in
            guard notification.object as? GameViewModel === viewModel else { return }
            if viewModel.isProcessing { return }
            viewModel.isProcessing = true
            showClassificationBadge = false
            lastClassification = nil
            resetHints()
            Task {
                await processMoveSequence()
                viewModel.isProcessing = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didMakeMove)) { notification in
            guard notification.object as? GameViewModel === analysisViewModel else { return }
            if analysisViewModel.isProcessing { return }
            analysisViewModel.isProcessing = true
            showAnalysisClassificationBadge = false
            lastAnalysisClassification = nil
            resetAnalysisHints()
            Task {
                await processAnalysisMoveSequence()
                analysisViewModel.isProcessing = false
            }
        }
        .onChange(of: viewModel.gameOver) { oldValue, isOver in
            if isOver && !gameSaved {
                gameSaved = true
                let counts = viewModel.classificationCounts(for: viewModel.playerColor)
                let game = SavedGame(
                    playerColor: viewModel.playerColor == .white ? "white" : "black",
                    finalElo: viewModel.displayLiveElo,
                    gameResult: viewModel.gameResult,
                    counts: counts
                )
                GameHistoryStore.shared.save(game: game)
            }
        }
    }
    
    // MARK: - Game Tab
    var gameTab: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            if !isGameActive {
                switch selectedGameMode {
                case .none:
                    modeSelectionView
                case .bot:
                    setupView
                        .onAppear {
                            // Keep setupElo synced with analyzer
                            selectedElo = Double(analyzer.currentElo)
                        }
                case .friend:
                    friendSetupView
                }
            } else {
                GeometryReader { screenGeo in
                    let screenWidth = screenGeo.size.width
                    let screenHeight = screenGeo.size.height
                    let isIPad = UIDevice.current.userInterfaceIdiom == .pad
                    let maxBoardSize = isIPad ? (screenHeight * 0.68) : (screenHeight * 0.55)
                    let baseBoardWidth = showEvalBar ? (screenWidth - 56) : (screenWidth - 32)
                    let boardWidth = min(baseBoardWidth, maxBoardSize)
                    let topColor = viewModel.boardFlipped ? Piece.Color.white : Piece.Color.black
                    let bottomColor = viewModel.boardFlipped ? Piece.Color.black : Piece.Color.white
                    
                    VStack(spacing: 8) {
                    // Top controls
                    HStack(spacing: isIPad ? 12 : 6) {
                        Button(action: {
                            isGameActive = false
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text(L10n.tr("back"))
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .font(isIPad ? .title3.bold() : .body.bold())
                            .foregroundColor(Theme.textMain)
                            .padding(.horizontal, isIPad ? 18 : 12)
                            .frame(height: isIPad ? 52 : 44)
                            .background(Theme.panelBackground)
                            .cornerRadius(isIPad ? 12 : 8)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        let dispOpeningName = currentOpeningName ?? (appLanguage == "de" ? "Partie" : "Game")
                        Text(dispOpeningName)
                            .font(.roundedSystem(isIPad ? .title3 : .body, weight: .bold))
                            .foregroundColor(Theme.accentColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .padding(.horizontal, isIPad ? 8 : 6)
                            .frame(maxWidth: .infinity)
                            .frame(height: isIPad ? 52 : 44)
                            .background(Theme.panelBackground)
                            .cornerRadius(isIPad ? 12 : 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: isIPad ? 12 : 8)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                        
                        Button(action: { showEvalBar.toggle() }) {
                            Image(systemName: showEvalBar ? "ruler.fill" : "ruler")
                                .font(.system(size: isIPad ? 22 : 18, weight: .bold))
                                .foregroundColor(Theme.textSecondary)
                                .padding(.horizontal, isIPad ? 18 : 12)
                                .frame(height: isIPad ? 52 : 44)
                                .background(Theme.panelBackground)
                                .cornerRadius(isIPad ? 12 : 8)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: {
                            isGameActive = false
                        }) {
                            Text(L10n.tr("new_game"))
                                .font(isIPad ? .title3.bold() : .body.bold())
                                .foregroundColor(Theme.textMain)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, isIPad ? 20 : 14)
                                .frame(height: isIPad ? 52 : 44)
                                .background(Theme.accentColor.opacity(0.4))
                                .cornerRadius(isIPad ? 12 : 8)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    
                    if viewModel.expiredPlayerColor != nil {
                        Button(action: {
                            withAnimation {
                                viewModel.continueWithoutTime()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "play.fill")
                                Text(appLanguage == "de" ? "Ohne Zeit weiterspielen" : "Continue without clock")
                            }
                            .font(isIPad ? .title3.bold() : .headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, isIPad ? 16 : 14)
                            .background(Theme.accentColor)
                            .cornerRadius(isIPad ? 12 : 8)
                            .shadow(color: Theme.accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
                        }
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    Spacer(minLength: 0)
                    
                    // Opponent/Top Profile
                    VStack(spacing: 4) {
                        PlayerProfileView(
                            name: viewModel.isFriendMode ? 
                                (topColor == .white ? L10n.tr("white") : L10n.tr("black")) :
                                "\(botName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Stockfish" : botName) \(analyzer.currentElo >= 3190 ? "(Max)" : "(Elo \(analyzer.currentElo))")",
                            rating: viewModel.isFriendMode ? "" : (analyzer.currentElo >= 3190 ? "Max" : "\(analyzer.currentElo)"),
                            avatarImage: viewModel.isFriendMode ? "person" : "desktopcomputer",
                            isEngine: viewModel.isFriendMode ? false : true,
                            timeRemaining: viewModel.isTimed ? viewModel.formatTime(topColor == .white ? viewModel.whiteTimeRemaining : viewModel.blackTimeRemaining) : nil,
                            isActive: viewModel.board.position.sideToMove == topColor,
                            mateIn: viewModel.allowHints ? mateIn(for: topColor) : nil,
                            hintAction: {
                                requestHint()
                            },
                            hintStep: viewModel.hintStep,
                            isAnalyzingHint: isAnalyzingHint,
                            isBestMoveDisabled: lastHistoryNode(for: topColor) == nil || lastHistoryNode(for: topColor)?.bestMoveStr == nil,
                            bestMoveAction: {
                                let node = lastHistoryNode(for: topColor)
                                if let node = node,
                                   let bestMoveStr = node.bestMoveStr,
                                   let fen = node.fenBefore,
                                   let position = Position(fen: fen),
                                   let move = EngineLANParser.parse(move: bestMoveStr, for: node.movingColor ?? topColor, in: position) {
                                    withAnimation {
                                        showBestMoveArrow = (start: move.start, end: move.end)
                                    }
                                }
                            },
                            showBestMoveButton: {
                                if viewModel.isFriendMode {
                                    return viewModel.showBestMovesRetrospectively
                                }
                                if viewModel.showBestMovesRetrospectively {
                                    return true
                                }
                                if showAnalysis,
                                   let node = lastHistoryNode(for: topColor),
                                   let classification = node.classification,
                                   let bestMoveStr = node.bestMoveStr, !bestMoveStr.isEmpty,
                                   (classification == .blunder || classification == .mistake || classification == .inaccuracy) {
                                    return true
                                }
                                return false
                            }(),
                            showHintButton: viewModel.isFriendMode ? (viewModel.allowHints && viewModel.board.position.sideToMove == topColor) : false,
                            showAccuracy: true,
                            accuracyValue: viewModel.accuracy(for: topColor, upTo: viewModel.isExploringHistory ? viewModel.historyIndex : (viewModel.history.count - 1))
                        )
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .center, spacing: 12) {
                                MaterialCounterView(
                                    capturedPieces: viewModel.capturedPieces(for: bottomColor, on: viewModel.board),
                                    capturedColor: bottomColor,
                                    advantage: viewModel.materialScore(for: topColor, on: viewModel.board)
                                )
                                
                                ClassificationCounterView(counts: viewModel.classificationCounts(for: topColor))
                                    .frame(height: 28)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Chess Board
                    HStack(spacing: 8) {
                        ChessBoardView(
                            viewModel: viewModel,
                            bestMoveArrow: showBestMoveArrow,
                            showAnalysis: showAnalysis,
                            showClassificationBadge: showClassificationBadge,
                            displayClassification: displayClassification
                        )
                        .frame(width: boardWidth, height: boardWidth)
                        
                        if showEvalBar {
                            EvalBarView(eval: viewModel.displayEvalScore, isFlipped: viewModel.boardFlipped)
                                .frame(height: boardWidth)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 0)
                    
                    // Player/Bottom Profile
                    VStack(spacing: 4) {
                        PlayerProfileView(
                            name: viewModel.isFriendMode ?
                                (bottomColor == .white ? L10n.tr("white") : L10n.tr("black")) :
                                L10n.tr("user_player"),
                            rating: viewModel.isFriendMode ? "" : "\(viewModel.displayLiveElo)",
                            avatarImage: "person.fill",
                            isEngine: false,
                            timeRemaining: viewModel.isTimed ? viewModel.formatTime(bottomColor == .white ? viewModel.whiteTimeRemaining : viewModel.blackTimeRemaining) : nil,
                            isActive: viewModel.board.position.sideToMove == bottomColor,
                            mateIn: viewModel.allowHints ? mateIn(for: bottomColor) : nil,
                            hintAction: {
                                requestHint()
                            },
                            hintStep: viewModel.hintStep,
                            isAnalyzingHint: isAnalyzingHint,
                            isBestMoveDisabled: lastHistoryNode(for: bottomColor) == nil || lastHistoryNode(for: bottomColor)?.bestMoveStr == nil,
                            bestMoveAction: {
                                let node = lastHistoryNode(for: bottomColor)
                                if let node = node,
                                   let bestMoveStr = node.bestMoveStr,
                                   let fen = node.fenBefore,
                                   let position = Position(fen: fen),
                                   let move = EngineLANParser.parse(move: bestMoveStr, for: node.movingColor ?? bottomColor, in: position) {
                                    withAnimation {
                                        showBestMoveArrow = (start: move.start, end: move.end)
                                    }
                                }
                            },
                            showBestMoveButton: {
                                if viewModel.isFriendMode {
                                    return viewModel.showBestMovesRetrospectively
                                }
                                if viewModel.showBestMovesRetrospectively {
                                    return true
                                }
                                if showAnalysis,
                                   let node = lastHistoryNode(for: bottomColor),
                                   let classification = node.classification,
                                   let bestMoveStr = node.bestMoveStr, !bestMoveStr.isEmpty,
                                   (classification == .blunder || classification == .mistake || classification == .inaccuracy) {
                                    return true
                                }
                                return false
                            }(),
                            showHintButton: viewModel.isFriendMode ? (viewModel.allowHints && viewModel.board.position.sideToMove == bottomColor) : viewModel.allowHints,
                            showAccuracy: true,
                            accuracyValue: viewModel.isFriendMode ? viewModel.accuracy(for: bottomColor, upTo: viewModel.isExploringHistory ? viewModel.historyIndex : (viewModel.history.count - 1)) : viewModel.playerAccuracy
                        )
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .center, spacing: 12) {
                                MaterialCounterView(
                                    capturedPieces: viewModel.capturedPieces(for: topColor, on: viewModel.board),
                                    capturedColor: topColor,
                                    advantage: viewModel.materialScore(for: bottomColor, on: viewModel.board)
                                )
                                
                                ClassificationCounterView(counts: viewModel.classificationCounts(for: bottomColor))
                                    .frame(height: 28)
                            }
                        }
                    }
                    .padding(.horizontal)
                    Group {
                        if !viewModel.history.isEmpty {
                            HStack(spacing: 12) {
                                Button(action: {
                                    if viewModel.historyIndex > 0 {
                                        viewModel.historyIndex -= 1
                                        resetHints()
                                    }
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.body.bold())
                                        .foregroundColor(viewModel.historyIndex > 0 ? .white : .gray)
                                        .padding(10)
                                        .background(Theme.panelBackground)
                                        .clipShape(Circle())
                                }
                                .disabled(viewModel.historyIndex == 0)
                                
                                HStack {
                                    Spacer()
                                    Text(appLanguage == "de" ? 
                                        "Zug \(viewModel.historyIndex) / \(max(0, viewModel.history.count - 1))" : 
                                        "Move \(viewModel.historyIndex) / \(max(0, viewModel.history.count - 1))")
                                        .font(.caption.bold())
                                        .foregroundColor(viewModel.isExploringHistory ? Theme.accentColor : Theme.textSecondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.15))
                                .cornerRadius(8)
                                
                                Button(action: {
                                    if viewModel.historyIndex < viewModel.history.count - 1 {
                                        viewModel.historyIndex += 1
                                        resetHints()
                                    }
                                }) {
                                    Image(systemName: "chevron.right")
                                        .font(.body.bold())
                                        .foregroundColor(viewModel.historyIndex < viewModel.history.count - 1 ? .white : .gray)
                                        .padding(10)
                                        .background(Theme.panelBackground)
                                        .clipShape(Circle())
                                }
                                .disabled(viewModel.historyIndex == viewModel.history.count - 1)
                            }
                        } else if !viewModel.isFriendMode {
                            HStack {
                                Text(L10n.tr("accuracy"))
                                    .font(.caption.bold())
                                    .foregroundColor(Theme.textSecondary)
                                Spacer()
                                AccuracyCounterView(accuracy: viewModel.playerAccuracy)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.15))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    }
                    .padding(.top, screenGeo.safeAreaInsets.top)
                    .padding(.bottom, 12)
                    .frame(width: screenGeo.size.width, height: screenGeo.size.height)
                }
            }
            
            // Game Over Overlay
            if viewModel.gameOver && !isCheckmate && viewModel.expiredPlayerColor == nil {
                VStack(spacing: 16) {
                    Text(L10n.tr("game_over"))
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    
                    Text(translatedResult(viewModel.gameResult))
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Button(L10n.tr("play_again")) {
                        analyzer.reset()
                        evaluationCache.removeAll()
                        viewModel.startGame(timed: isTimed, durationSeconds: Int(timeControlMinutes * 60), incrementSeconds: Int(timeControlIncrementSeconds))
                        lastClassification = nil
                        showClassificationBadge = false
                        resetHints()
                        if viewModel.isEngineTurn {
                            viewModel.isProcessing = true
                            Task {
                                await processMoveSequence()
                                viewModel.isProcessing = false
                            }
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(8)
                }
                .padding(32)
                .background(Color.black.opacity(0.8))
                .cornerRadius(16)
                .shadow(radius: 10)
                .transition(.scale.combined(with: .opacity))
                .zIndex(100)
            }
        }
        .coordinateSpace(name: "gameTabContainer")
    }
    
    private func evaluateWithCache(fen: String, depth: Int = 10, limitSkill: Bool = false, movetime: Int? = nil) async -> (bestMove: String, score: Int, mate: Int?)? {
        let isCacheable = (depth == 10 && !limitSkill)
        if isCacheable, let cached = evaluationCache[fen] {
            return cached
        }
        
        let result = await analyzer.evaluate(fen: fen, depth: depth, limitSkill: limitSkill, movetime: movetime)
        
        if isCacheable, let res = result {
            await MainActor.run {
                evaluationCache[fen] = res
            }
        }
        return result
    }
    
    private func checkIfBookMove(playedMoves: [Move]) -> Bool {
        if playedMoves.isEmpty {
            return false
        }
        
        var board = Board()
        for move in playedMoves {
            _ = board.move(pieceAt: move.start, to: move.end)
        }
        
        let simplified = Opening.simplifiedFEN(board.position.fen)
        return Opening.bookFENs.contains(simplified)
    }
    
    private func processMoveSequence() async {
        let isMaxElo = analyzer.currentElo >= 3190
        var evalAfter: Int = 0
        
        // 1. Analyze the player's move
        if let lastMove = viewModel.lastMove, let fenBefore = viewModel.lastPlayerMoveFenBefore {
            let fenAfterPlayer = viewModel.board.position.fen
            if showAnalysis {
                analyzer.debugStatus = "Analysiere Zug..."
                let evalBeforeResult = await evaluateWithCache(fen: fenBefore, depth: 10, limitSkill: false, movetime: 300)
                let evalBefore = evalBeforeResult?.score ?? 0
                
                await MainActor.run {
                    viewModel.lastBestMoveStr = evalBeforeResult?.bestMove
                }
                
                let movingColor = Position(fen: fenBefore)?.sideToMove ?? viewModel.playerColor
                
                let pureEvalAfterResult: (bestMove: String, score: Int, mate: Int?)?
                if case .checkmate = viewModel.board.state {
                    pureEvalAfterResult = (bestMove: "", score: -10000, mate: nil)
                } else if viewModel.gameOver {
                    pureEvalAfterResult = (bestMove: "", score: 0, mate: nil)
                } else {
                    pureEvalAfterResult = await evaluateWithCache(fen: fenAfterPlayer, depth: 10, limitSkill: false, movetime: 300)
                }
                
                evalAfter = pureEvalAfterResult?.score ?? 0
                let playerEvalAfter = -evalAfter
                let evalDrop = evalBefore - playerEvalAfter
                
                let newSideToMove = Position(fen: fenAfterPlayer)?.sideToMove ?? .white
                let mateWhitePOV = pureEvalAfterResult?.mate.map { newSideToMove == .white ? $0 : -$0 }
                
                let isBook = checkIfBookMove(playedMoves: viewModel.history.compactMap { $0.lastMove } + [lastMove])
                await MainActor.run { viewModel.inOpening = isBook }
                
                let isBest = {
                    if let bestMoveStr = evalBeforeResult?.bestMove,
                       let move = EngineLANParser.parse(move: bestMoveStr, for: movingColor, in: Position(fen: fenBefore) ?? viewModel.board.position) {
                        return lastMove.start == move.start && lastMove.end == move.end
                    }
                    return false
                }()
                let classification = analyzer.classifyMove(
                    evalBefore: evalBefore,
                    evalAfter: playerEvalAfter,
                    isBook: isBook,
                    isBest: isBest,
                    move: lastMove,
                    boardBefore: Position(fen: fenBefore).map { Board(position: $0) } ?? viewModel.board,
                    boardAfter: viewModel.board
                )
                
                let evalWhitePOV = newSideToMove == .white ? (pureEvalAfterResult?.score ?? 0) : -(pureEvalAfterResult?.score ?? 0)
                
                await MainActor.run {
                    withAnimation {
                        lastClassification = classification
                        showClassificationBadge = true
                    }
                    viewModel.moveClassifications[lastMove] = classification
                    viewModel.pushHistory(classification: classification, bestMoveStr: evalBeforeResult?.bestMove, movingColor: movingColor, evalScore: evalWhitePOV, mate: mateWhitePOV, evalDrop: evalDrop)
                }
                
                try? await Task.sleep(nanoseconds: 800_000_000)
            }
        }        
        // 2. Make engine move
        if viewModel.isEngineTurn && !viewModel.gameOver {
            analyzer.debugStatus = "Engine überlegt..."
            let fen = viewModel.board.position.fen
            
            let engineResult: (bestMove: String, score: Int, mate: Int?)?
            let totalPieces = Square.allCases.compactMap { viewModel.board.position.piece(at: $0) }.count
            let isEndgame = totalPieces < 10
            
            let engineDepth: Int
            let maxMoveTime: Int
            
            if isMaxElo {
                engineDepth = isEndgame ? 18 : 15
                maxMoveTime = 1000
            } else {
                let elo = analyzer.currentElo
                if elo < 800 {
                    engineDepth = isEndgame ? 6 : 4
                    maxMoveTime = 150
                } else if elo < 1400 {
                    engineDepth = isEndgame ? 10 : 7
                    maxMoveTime = 300
                } else if elo < 2000 {
                    engineDepth = isEndgame ? 13 : 10
                    maxMoveTime = 500
                } else {
                    engineDepth = isEndgame ? 16 : 12
                    maxMoveTime = 800
                }
            }
            
            engineResult = await evaluateWithCache(fen: fen, depth: engineDepth, limitSkill: !isMaxElo, movetime: maxMoveTime)
            
            if let result = engineResult,
               let move = EngineLANParser.parse(move: result.bestMove, for: viewModel.engineColor, in: viewModel.board.position) {
                
                await MainActor.run {
                    viewModel.lastPlayerMoveFenBefore = fen
                    viewModel.makeEngineMove(start: move.start, end: move.end, promoteTo: move.promotedPiece?.kind)
                    showClassificationBadge = false
                    lastClassification = nil
                }
                
                // 3. Analyze engine's move
                if showAnalysis, let engineMove = viewModel.lastMove {
                    analyzer.debugStatus = "Analysiere gegnerischen Zug..."
                    
                    let engineEvalBefore = evalAfter
                    let postEngineResult = await evaluateWithCache(fen: viewModel.board.position.fen, depth: 10, limitSkill: false, movetime: 300)
                    let engineEvalAfterScore: Int = {
                        if case .checkmate = viewModel.board.state {
                            return -10000 // Player is checkmated, player's POV is -10000
                        } else if viewModel.gameOver {
                            return 0
                        } else {
                            return postEngineResult?.score ?? 0
                        }
                    }()
                    
                    let engineEvalDrop = engineEvalBefore + engineEvalAfterScore
                    
                    let newSideToMove = viewModel.board.position.sideToMove
                    let engineMateWhitePOV = postEngineResult?.mate.map { newSideToMove == .white ? $0 : -$0 }
                    
                    let engineIsBook = checkIfBookMove(playedMoves: viewModel.history.compactMap { $0.lastMove } + [engineMove])
                    await MainActor.run { viewModel.inOpening = engineIsBook }
                    
                    let cachedEvalBefore = evaluationCache[fen]
                    let isEngineBest = {
                        if let bestMoveStr = cachedEvalBefore?.bestMove,
                           let move = EngineLANParser.parse(move: bestMoveStr, for: viewModel.engineColor, in: Position(fen: fen) ?? viewModel.board.position) {
                            return engineMove.start == move.start && engineMove.end == move.end
                        }
                        return false
                    }()
                    
                    let engineClass: MoveClassification
                    if isMaxElo {
                        // Max strength bot always plays best moves
                        engineClass = engineIsBook ? .book : .best
                    } else {
                        engineClass = analyzer.classifyMove(
                            evalBefore: engineEvalBefore,
                            evalAfter: -engineEvalAfterScore, // Convert engineEvalAfterScore (player POV) to engine POV
                            isBook: engineIsBook,
                            isBest: isEngineBest,
                            move: engineMove,
                            boardBefore: Position(fen: fen).map { Board(position: $0) } ?? viewModel.board,
                            boardAfter: viewModel.board
                        )
                    }
                    
                    let engineEvalWhitePOV = newSideToMove == .white ? engineEvalAfterScore : -engineEvalAfterScore
                    
                    await MainActor.run {
                        withAnimation {
                            lastClassification = engineClass
                            showClassificationBadge = true
                        }
                        viewModel.moveClassifications[engineMove] = engineClass
                        viewModel.pushHistory(classification: engineClass, bestMoveStr: result.bestMove, movingColor: viewModel.engineColor, evalScore: engineEvalWhitePOV, mate: engineMateWhitePOV, evalDrop: engineEvalDrop)
                    }
                    
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
            } else {
                await MainActor.run {
                    makeRandomMove()
                }
            }
        }
        
        // 4. Try executing any queued premove
        let premoveExecuted = await MainActor.run {
            viewModel.executePremoveIfValid()
        }
        if premoveExecuted {
            await processMoveSequence()
        }
    }
    
    private func makeRandomMove() {
        var allMoves: [(Square, Square)] = []
        for sq in Square.allCases {
            if let piece = viewModel.board.position.piece(at: sq), piece.color == viewModel.engineColor {
                let targets = viewModel.board.legalMoves(forPieceAt: sq)
                for target in targets {
                    // Safety check: Never capture the player's king
                    if let targetPiece = viewModel.board.position.piece(at: target), targetPiece.kind == .king {
                        continue
                    }
                    allMoves.append((sq, target))
                }
            }
        }
        
        if let (start, end) = allMoves.randomElement() {
            viewModel.lastPlayerMoveFenBefore = viewModel.board.position.fen
            viewModel.makeEngineMove(start: start, end: end)
        }
    }
    
    private func resetAnalysisHints() {
        analysisViewModel.hintStep = 0
        analysisViewModel.hintCorrectSquare = nil
        analysisViewModel.hintAlternativeSquare = nil
        showAnalysisBestMoveArrow = nil
        analysisHintBestMove = nil
        isAnalyzingAnalysisHint = false
        activeBestMoveArrowOwner = nil
    }
    
    private func handleAnalysisBestMoveTapped(for color: Piece.Color) {
        let isCurrent = (analysisViewModel.displayBoard.position.sideToMove == color)
        
        if isCurrent {
            if activeBestMoveArrowOwner?.color == color && activeBestMoveArrowOwner?.isCurrent == true {
                showAnalysisBestMoveArrow = nil
                activeBestMoveArrowOwner = nil
                return
            }
            
            let nextIndex = analysisViewModel.historyIndex + 1
            if analysisViewModel.isExploringHistory && nextIndex < analysisViewModel.history.count,
               let bestMoveStr = analysisViewModel.history[nextIndex].bestMoveStr {
                if let move = EngineLANParser.parse(move: bestMoveStr, for: color, in: analysisViewModel.displayBoard.position) {
                    showAnalysisBestMoveArrow = (move.start, move.end)
                    activeBestMoveArrowOwner = (color, true)
                }
            } else {
                let fen = analysisViewModel.displayBoard.position.fen
                isCalculatingAnalysisBestMove = color
                Task {
                    let result = await evaluateWithCache(fen: fen, depth: 10, limitSkill: false, movetime: 300)
                    await MainActor.run {
                        isCalculatingAnalysisBestMove = nil
                        guard analysisViewModel.displayBoard.position.fen == fen else { return }
                        if let bestMoveStr = result?.bestMove,
                           let move = EngineLANParser.parse(move: bestMoveStr, for: color, in: analysisViewModel.displayBoard.position) {
                            showAnalysisBestMoveArrow = (move.start, move.end)
                            activeBestMoveArrowOwner = (color, true)
                        }
                    }
                }
            }
        } else {
            if activeBestMoveArrowOwner?.color == color && activeBestMoveArrowOwner?.isCurrent == false {
                showAnalysisBestMoveArrow = nil
                activeBestMoveArrowOwner = nil
                return
            }
            
            let nodeIndex = analysisViewModel.historyIndex
            if nodeIndex < analysisViewModel.history.count {
                let node = analysisViewModel.history[nodeIndex]
                if node.movingColor == color, let bestMoveStr = node.bestMoveStr, let fenBefore = node.fenBefore, let posBefore = Position(fen: fenBefore) {
                    if let move = EngineLANParser.parse(move: bestMoveStr, for: color, in: posBefore) {
                        showAnalysisBestMoveArrow = (move.start, move.end)
                        activeBestMoveArrowOwner = (color, false)
                    }
                }
            }
        }
    }
    
    private func requestAnalysisHint() {
        guard !analysisViewModel.isProcessing else { return }
        
        if analysisViewModel.hintStep == 0 {
            isAnalyzingAnalysisHint = true
            let fen = analysisViewModel.board.position.fen
            let activeColor = analysisViewModel.board.position.sideToMove
            Task {
                let result = await evaluateWithCache(fen: fen, depth: 10, limitSkill: false, movetime: 300)
                
                await MainActor.run {
                    isAnalyzingAnalysisHint = false
                    guard analysisViewModel.board.position.fen == fen else { return }
                    
                    if let bestMoveStr = result?.bestMove,
                       let move = EngineLANParser.parse(move: bestMoveStr, for: activeColor, in: analysisViewModel.board.position) {
                        
                        analysisHintBestMove = (start: move.start, end: move.end)
                        analysisViewModel.hintCorrectSquare = move.start
                        analysisViewModel.hintAlternativeSquare = findPlausiblePawnOrPiece(correctSquare: move.start, board: analysisViewModel.board, playerColor: activeColor)
                        withAnimation {
                            analysisViewModel.hintStep = 1
                            showAnalysisBestMoveArrow = nil
                        }
                    }
                }
            }
        } else if analysisViewModel.hintStep == 1 {
            withAnimation {
                analysisViewModel.hintStep = 2
                showAnalysisBestMoveArrow = nil
            }
        } else if analysisViewModel.hintStep == 2 {
            withAnimation {
                analysisViewModel.hintStep = 3
                if let bestMove = analysisHintBestMove {
                    showAnalysisBestMoveArrow = bestMove
                }
            }
        } else {
            withAnimation {
                resetAnalysisHints()
            }
        }
    }
    
    private func processAnalysisMoveSequence() async {
        guard let lastMove = analysisViewModel.lastMove,
              let fenBefore = analysisViewModel.lastPlayerMoveFenBefore else { return }
        
        let fenAfter = analysisViewModel.board.position.fen
        let movingColor: Piece.Color = analysisViewModel.board.position.sideToMove == .white ? .black : .white
        
        if showAnalysisTabAnalysis {
            analyzer.debugStatus = "Analysiere Zug..."
            
            let evalBeforeResult = await evaluateWithCache(fen: fenBefore, depth: 10, limitSkill: false, movetime: 300)
            let evalBefore = evalBeforeResult?.score ?? 0
            
            await MainActor.run {
                analysisViewModel.lastBestMoveStr = evalBeforeResult?.bestMove
            }
            
            let pureEvalAfterResult: (bestMove: String, score: Int, mate: Int?)?
            if case .checkmate = analysisViewModel.board.state {
                pureEvalAfterResult = (bestMove: "", score: -10000, mate: nil)
            } else if analysisViewModel.gameOver {
                pureEvalAfterResult = (bestMove: "", score: 0, mate: nil)
            } else {
                pureEvalAfterResult = await evaluateWithCache(fen: fenAfter, depth: 10, limitSkill: false, movetime: 300)
            }
            
            let evalAfter = pureEvalAfterResult?.score ?? 0
            let playerEvalAfter = -evalAfter
            let evalDrop = evalBefore - playerEvalAfter
            
            let mateWhitePOV: Int?
            if let m = pureEvalAfterResult?.mate {
                mateWhitePOV = analysisViewModel.board.position.sideToMove == .white ? m : -m
            } else {
                mateWhitePOV = nil
            }
            
            let isBook = checkIfBookMove(playedMoves: analysisViewModel.history.compactMap { $0.lastMove } + [lastMove])
            await MainActor.run {
                analysisViewModel.inOpening = isBook
            }
            
            let isBest = {
                if let bestMoveStr = evalBeforeResult?.bestMove,
                   let move = EngineLANParser.parse(move: bestMoveStr, for: movingColor, in: Position(fen: fenBefore) ?? analysisViewModel.board.position) {
                    return lastMove.start == move.start && lastMove.end == move.end
                }
                return false
            }()
            let classification = analyzer.classifyMove(
                evalBefore: evalBefore,
                evalAfter: playerEvalAfter,
                isBook: isBook,
                isBest: isBest,
                move: lastMove,
                boardBefore: Position(fen: fenBefore).map { Board(position: $0) } ?? analysisViewModel.board,
                boardAfter: analysisViewModel.board
            )
            let evalWhitePOV = movingColor == .white ? playerEvalAfter : evalAfter
            
            await MainActor.run {
                withAnimation {
                    lastAnalysisClassification = classification
                    showAnalysisClassificationBadge = true
                }
                analysisViewModel.moveClassifications[lastMove] = classification
                analysisViewModel.pushHistory(
                    classification: classification,
                    bestMoveStr: evalBeforeResult?.bestMove,
                    movingColor: movingColor,
                    evalScore: evalWhitePOV,
                    mate: mateWhitePOV,
                    evalDrop: evalDrop
                )
            }
        } else {
            await MainActor.run {
                analysisViewModel.pushHistory(
                    classification: nil,
                    bestMoveStr: nil,
                    movingColor: movingColor,
                    evalScore: 0,
                    mate: nil,
                    evalDrop: 0
                )
            }
        }
    }
    
    private func translatedResult(_ result: String) -> String {
        return L10n.translateResult(result)
    }
    
    private func avatarIcon(for choice: PlayerColor) -> String {
        switch choice {
        case .white: return "circle.fill"
        case .black: return "circle"
        case .random: return "questionmark.circle"
        }
    }
    
    private func choiceDisplayName(for choice: PlayerColor) -> String {
        switch choice {
        case .white: return L10n.tr("white")
        case .black: return L10n.tr("black")
        case .random: return L10n.tr("random")
        }
    }
    
    private func difficultyLabel(for elo: Int) -> String {
        if elo <= 800 {
            return L10n.tr("beginner")
        } else if elo <= 1500 {
            return L10n.tr("intermediate")
        } else if elo <= 2200 {
            return L10n.tr("advanced")
        } else if elo <= 2800 {
            return L10n.tr("master")
        } else {
            return L10n.tr("grandmaster") + (elo >= 3190 ? " (Max)" : "")
        }
    }
    
    var analysisSetupView: some View {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        return ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    if selectedTab == 3 && !isAnalysisGameActive {
                        ScrollOffsetDetector(coordinateSpace: "analysisTabContainer", tag: "analysisSetup")
                    }
                    
                    Spacer().frame(height: isIPad ? 224 : 216)
                    
                    // Board orientation selection card
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.tr("play_as"))
                            .font(.roundedSystem(.headline, weight: .bold))
                            .foregroundColor(Theme.textMain)
                        
                        HStack(spacing: 12) {
                            ForEach([PlayerColor.white, PlayerColor.black], id: \.self) { choice in
                                Button(action: {
                                    withAnimation {
                                        analysisViewModel.playerColorChoice = choice
                                    }
                                }) {
                                    VStack(spacing: 8) {
                                        colorSelectionIcon(for: choice)
                                        Text(choiceDisplayName(for: choice))
                                            .font(.roundedSystem(.subheadline, weight: .bold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(analysisViewModel.playerColorChoice == choice ? Theme.accentColor.opacity(0.2) : Theme.panelBackground)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(analysisViewModel.playerColorChoice == choice ? Theme.accentColor : Color.white.opacity(0.06), lineWidth: analysisViewModel.playerColorChoice == choice ? 2 : 1)
                                    )
                                    .foregroundColor(.white)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Start Analysis button
                    Button(action: {
                        analyzer.updateElo(3190)
                        evaluationCache.removeAll()
                        analysisViewModel.startGame(timed: false, durationSeconds: 600)
                        lastAnalysisClassification = nil
                        showAnalysisClassificationBadge = false
                        resetAnalysisHints()
                        isAnalysisGameActive = true
                    }) {
                        Text(L10n.tr("start_analysis"))
                            .font(.roundedSystem(.headline, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.primaryGradient)
                            .cornerRadius(16)
                            .shadow(color: Theme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                    // Play analysis checkbox
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(L10n.tr("show_analysis_toggle"), isOn: $showAnalysisTabAnalysis)
                            .toggleStyle(ThemeToggleStyle())
                    }
                    .padding(.horizontal)
                    
                }
                .padding(.bottom, 24)
            }
            
            // Collapsible Header View at top
            VStack(spacing: 0) {
                Color.clear.frame(height: 0)
                CollapsibleHeaderView(
                    title: L10n.tr("analysis"),
                    subtitle: L10n.tr("analysis_setup_subtitle"),
                    iconName: "magnifyingglass",
                    scrollOffset: analysisScrollOffset
                )
            }
            .background(
                Theme.background
                    .opacity(analysisScrollOffset < -5 ? 1.0 : 0.0)
                    .ignoresSafeArea(edges: .top)
            )
            .animation(.easeInOut(duration: 0.15), value: analysisScrollOffset < -5)
        }
        .onPreferenceChange(TaggedScrollOffsetPreferenceKey.self) { values in
            if let val = values["analysisSetup"] {
                self.analysisScrollOffset = val
            }
        }
    }
    
    var analysisTab: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            if !isAnalysisGameActive {
                analysisSetupView
                    .transition(.opacity)
                    .onAppear {
                        analysisSelectedElo = Double(analyzer.currentElo)
                    }
            } else {
                GeometryReader { screenGeo in
                    let screenWidth = screenGeo.size.width
                    let screenHeight = screenGeo.size.height
                    let isIPad = UIDevice.current.userInterfaceIdiom == .pad
                    let maxBoardSize = isIPad ? (screenHeight * 0.68) : (screenHeight * 0.55)
                    let baseBoardWidth = showAnalysisEvalBar ? (screenWidth - 56) : (screenWidth - 32)
                    let boardWidth = min(baseBoardWidth, maxBoardSize)
                    
                    let topColor: Piece.Color = analysisViewModel.playerColor == .white ? .black : .white
                    let bottomColor: Piece.Color = analysisViewModel.playerColor == .white ? .white : .black
                    
                    VStack(spacing: 8) {
                        // Top controls
                        HStack(spacing: isIPad ? 12 : 8) {
                            Button(action: {
                                isAnalysisGameActive = false
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                    Text(L10n.tr("back"))
                                        .fixedSize(horizontal: true, vertical: false)
                                }
                                .font(isIPad ? .title3.bold() : .body.bold())
                                .foregroundColor(Theme.textMain)
                                .padding(.horizontal, isIPad ? 18 : 12)
                                .frame(height: isIPad ? 52 : 44)
                                .background(Theme.panelBackground)
                                .cornerRadius(isIPad ? 12 : 8)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            Spacer(minLength: 0)
                            
                            if let openingName = analysisCurrentOpeningName {
                                Text(openingName)
                                    .font(.roundedSystem(isIPad ? .title3 : .body, weight: .bold))
                                    .foregroundColor(Theme.accentColor)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                                    .padding(.horizontal, isIPad ? 8 : 6)
                                    .frame(width: isIPad ? 360 : 160)
                                    .frame(height: isIPad ? 52 : 44)
                                    .background(Theme.panelBackground)
                                    .cornerRadius(isIPad ? 12 : 8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: isIPad ? 12 : 8)
                                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                    )
                            }
                            
                            Spacer(minLength: 0)
                            
                            Button(action: { withAnimation { showAnalysisEvalBar.toggle() } }) {
                                Image(systemName: showAnalysisEvalBar ? "ruler.fill" : "ruler")
                                    .font(.system(size: isIPad ? 22 : 18, weight: .bold))
                                    .foregroundColor(Theme.textSecondary)
                                    .padding(.horizontal, isIPad ? 18 : 12)
                                    .frame(height: isIPad ? 52 : 44)
                                    .background(Theme.panelBackground)
                                    .cornerRadius(isIPad ? 12 : 8)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            Button(action: {
                                isAnalysisGameActive = false
                            }) {
                                Text(L10n.tr("new_game"))
                                    .font(isIPad ? .title3.bold() : .body.bold())
                                    .foregroundColor(Theme.textMain)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .padding(.horizontal, isIPad ? 20 : 14)
                                    .frame(height: isIPad ? 52 : 44)
                                    .background(Theme.accentColor.opacity(0.4))
                                    .cornerRadius(isIPad ? 12 : 8)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                        
                        Spacer(minLength: 0)
                        
                        // Top Profile
                        VStack(spacing: 4) {
                            PlayerProfileView(
                                name: topColor == .white ? L10n.tr("white") : L10n.tr("black"),
                                rating: "",
                                avatarImage: "person",
                                isEngine: false,
                                timeRemaining: analysisViewModel.isTimed ? analysisViewModel.formatTime(topColor == .white ? analysisViewModel.whiteTimeRemaining : analysisViewModel.blackTimeRemaining) : nil,
                                isActive: analysisViewModel.board.position.sideToMove == topColor,
                                mateIn: mateIn(for: topColor, vm: analysisViewModel),
                                isAnalysisMode: true,
                                isCalculatingBestMove: isCalculatingAnalysisBestMove == topColor,
                                isBestMoveActive: activeBestMoveArrowOwner?.color == topColor,
                                isBestMoveDisabled: {
                                    let isCurrent = (analysisViewModel.displayBoard.position.sideToMove == topColor)
                                    if isCurrent {
                                        return false
                                    } else {
                                        let nodeIndex = analysisViewModel.historyIndex
                                        if nodeIndex < analysisViewModel.history.count {
                                            let node = analysisViewModel.history[nodeIndex]
                                            return node.movingColor != topColor || node.bestMoveStr == nil
                                        }
                                        return true
                                    }
                                }(),
                                bestMoveAction: {
                                    handleAnalysisBestMoveTapped(for: topColor)
                                },
                                showAccuracy: true,
                                accuracyValue: analysisViewModel.accuracy(for: topColor, upTo: analysisViewModel.historyIndex)
                            )
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .center, spacing: 12) {
                                    MaterialCounterView(
                                        capturedPieces: analysisViewModel.capturedPieces(for: bottomColor, on: analysisViewModel.board),
                                        capturedColor: bottomColor,
                                        advantage: analysisViewModel.materialScore(for: topColor, on: analysisViewModel.board)
                                    )
                                    
                                    ClassificationCounterView(counts: analysisViewModel.classificationCounts(for: topColor))
                                        .frame(height: 28)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Chess Board
                        HStack(spacing: 8) {
                            ChessBoardView(
                                viewModel: analysisViewModel,
                                bestMoveArrow: showAnalysisBestMoveArrow,
                                showAnalysis: showAnalysisTabAnalysis,
                                showClassificationBadge: showAnalysisClassificationBadge,
                                displayClassification: displayAnalysisClassification
                            )
                            .frame(width: boardWidth, height: boardWidth)
                            
                            if showAnalysisEvalBar {
                                EvalBarView(eval: analysisViewModel.displayEvalScore, isFlipped: analysisViewModel.boardFlipped)
                                    .frame(height: boardWidth)
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 0)
                        
                        // Bottom Profile
                        VStack(spacing: 4) {
                            PlayerProfileView(
                                name: bottomColor == .white ? L10n.tr("white") : L10n.tr("black"),
                                rating: "",
                                avatarImage: "person.fill",
                                isEngine: false,
                                timeRemaining: analysisViewModel.isTimed ? analysisViewModel.formatTime(bottomColor == .white ? analysisViewModel.whiteTimeRemaining : analysisViewModel.blackTimeRemaining) : nil,
                                isActive: analysisViewModel.board.position.sideToMove == bottomColor,
                                mateIn: mateIn(for: bottomColor, vm: analysisViewModel),
                                isAnalysisMode: true,
                                isCalculatingBestMove: isCalculatingAnalysisBestMove == bottomColor,
                                isBestMoveActive: activeBestMoveArrowOwner?.color == bottomColor,
                                isBestMoveDisabled: {
                                    let isCurrent = (analysisViewModel.displayBoard.position.sideToMove == bottomColor)
                                    if isCurrent {
                                        return false
                                    } else {
                                        let nodeIndex = analysisViewModel.historyIndex
                                        if nodeIndex < analysisViewModel.history.count {
                                            let node = analysisViewModel.history[nodeIndex]
                                            return node.movingColor != bottomColor || node.bestMoveStr == nil
                                        }
                                        return true
                                    }
                                }(),
                                bestMoveAction: {
                                    handleAnalysisBestMoveTapped(for: bottomColor)
                                },
                                showAccuracy: true,
                                accuracyValue: analysisViewModel.accuracy(for: bottomColor, upTo: analysisViewModel.historyIndex)
                            )
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .center, spacing: 12) {
                                    MaterialCounterView(
                                        capturedPieces: analysisViewModel.capturedPieces(for: topColor, on: analysisViewModel.board),
                                        capturedColor: topColor,
                                        advantage: analysisViewModel.materialScore(for: bottomColor, on: analysisViewModel.board)
                                    )
                                    
                                    ClassificationCounterView(counts: analysisViewModel.classificationCounts(for: bottomColor))
                                        .frame(height: 28)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        if !analysisViewModel.history.isEmpty {
                            HStack(spacing: 8) {
                                // Go to Start
                                Button(action: {
                                    withAnimation {
                                        analysisViewModel.historyIndex = 0
                                        resetAnalysisHints()
                                    }
                                }) {
                                    Image(systemName: "chevron.left.2")
                                        .font(.body.bold())
                                        .foregroundColor(analysisViewModel.historyIndex > 0 ? .white : .gray)
                                        .padding(10)
                                        .background(Theme.panelBackground)
                                        .clipShape(Circle())
                                }
                                .disabled(analysisViewModel.historyIndex == 0)
                                    
                                    // Step Back (Undo)
                                    Button(action: {
                                        withAnimation {
                                            if analysisViewModel.historyIndex > 0 {
                                                analysisViewModel.historyIndex -= 1
                                                resetAnalysisHints()
                                            }
                                        }
                                    }) {
                                        Image(systemName: "chevron.left")
                                            .font(.body.bold())
                                            .foregroundColor(analysisViewModel.historyIndex > 0 ? .white : .gray)
                                            .padding(10)
                                            .background(Theme.panelBackground)
                                            .clipShape(Circle())
                                    }
                                    .disabled(analysisViewModel.historyIndex == 0)
                                    
                                    // Centered Move Count Info Card
                                    HStack {
                                        Spacer()
                                        Text(appLanguage == "de" ? 
                                            "Zug \(analysisViewModel.historyIndex) / \(max(0, analysisViewModel.history.count - 1))" : 
                                            "Move \(analysisViewModel.historyIndex) / \(max(0, analysisViewModel.history.count - 1))")
                                            .font(.caption.bold())
                                            .foregroundColor(analysisViewModel.isExploringHistory ? Theme.accentColor : Theme.textSecondary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(0.15))
                                    .cornerRadius(8)
                                    
                                    // Step Forward (Redo)
                                    Button(action: {
                                        withAnimation {
                                            if analysisViewModel.historyIndex < analysisViewModel.history.count - 1 {
                                                analysisViewModel.historyIndex += 1
                                                resetAnalysisHints()
                                            }
                                        }
                                    }) {
                                        Image(systemName: "chevron.right")
                                            .font(.body.bold())
                                            .foregroundColor(analysisViewModel.historyIndex < analysisViewModel.history.count - 1 ? .white : .gray)
                                            .padding(10)
                                            .background(Theme.panelBackground)
                                            .clipShape(Circle())
                                    }
                                    .disabled(analysisViewModel.historyIndex == analysisViewModel.history.count - 1)
                                    
                                    // Go to End
                                    Button(action: {
                                        withAnimation {
                                            analysisViewModel.historyIndex = analysisViewModel.history.count - 1
                                            resetAnalysisHints()
                                        }
                                    }) {
                                        Image(systemName: "chevron.right.2")
                                            .font(.body.bold())
                                            .foregroundColor(analysisViewModel.historyIndex < analysisViewModel.history.count - 1 ? .white : .gray)
                                            .padding(10)
                                            .background(Theme.panelBackground)
                                            .clipShape(Circle())
                                    }
                                    .disabled(analysisViewModel.historyIndex == analysisViewModel.history.count - 1)
                                }
                            }
                    }
                    .padding(.top, screenGeo.safeAreaInsets.top)
                    .padding(.bottom, 12)
                    .frame(width: screenGeo.size.width, height: screenGeo.size.height)
                }
            }
            
            // Game Over Overlay
            if analysisViewModel.gameOver && !isAnalysisCheckmate {
                VStack(spacing: 16) {
                    Text(L10n.tr("game_over"))
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    
                    Text(translatedResult(analysisViewModel.gameResult))
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Button(L10n.tr("play_again")) {
                        analyzer.reset()
                        evaluationCache.removeAll()
                        analysisViewModel.startGame(timed: false, durationSeconds: 600)
                        lastAnalysisClassification = nil
                        showAnalysisClassificationBadge = false
                        resetAnalysisHints()
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(8)
                }
                .padding(32)
                .background(Color.black.opacity(0.8))
                .cornerRadius(16)
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .coordinateSpace(name: "analysisTabContainer")
    }
    
    var setupView: some View {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        return ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    if selectedTab == 0 && !isGameActive && selectedGameMode == .bot {
                        ScrollOffsetDetector(coordinateSpace: "gameTabContainer", tag: "setupBot")
                    }
                    
                    Spacer().frame(height: isIPad ? 224 : 216)
                    
                    // Color selection card
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.tr("play_as"))
                            .font(.roundedSystem(.headline, weight: .bold))
                            .foregroundColor(Theme.textMain)
                        
                        HStack(spacing: 12) {
                            ForEach(PlayerColor.allCases, id: \.self) { choice in
                                Button(action: {
                                    withAnimation {
                                        viewModel.playerColorChoice = choice
                                    }
                                }) {
                                    VStack(spacing: 8) {
                                        colorSelectionIcon(for: choice)
                                        Text(choiceDisplayName(for: choice))
                                            .font(.roundedSystem(.subheadline, weight: .bold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(viewModel.playerColorChoice == choice ? Theme.accentColor.opacity(0.2) : Theme.panelBackground)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(viewModel.playerColorChoice == choice ? Theme.accentColor : Color.white.opacity(0.06), lineWidth: viewModel.playerColorChoice == choice ? 2 : 1)
                                    )
                                    .foregroundColor(.white)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Elo rating selection card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(L10n.tr("computer_strength"))
                                .font(.roundedSystem(.headline, weight: .bold))
                                .foregroundColor(Theme.textMain)
                            Spacer()
                            Text(selectedElo >= 3190 ? "Max" : "\(Int(selectedElo)) Elo")
                                .font(.roundedSystem(.headline, weight: .bold))
                                .foregroundColor(Theme.accentColor)
                        }
                        
                        VStack(spacing: 8) {
                            Slider(value: $selectedElo, in: 100...3190, step: 10)
                                .tint(Theme.accentColor)
                            
                            Text(difficultyLabel(for: Int(selectedElo)))
                                .font(.roundedSystem(.caption, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Theme.accentColor.opacity(0.15))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Theme.accentColor.opacity(0.3), lineWidth: 1)
                                )
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
                    
                    // Start Game button (Packed up higher!)
                    Button(action: {
                        viewModel.isFriendMode = false
                        viewModel.allowHints = allowHints
                        viewModel.showBestMovesRetrospectively = showBestMovesRetrospectively
                        
                        analyzer.updateElo(Int(selectedElo))
                        evaluationCache.removeAll()
                        gameSaved = false
                        viewModel.startGame(timed: isTimed, durationSeconds: Int(timeControlMinutes * 60), incrementSeconds: Int(timeControlIncrementSeconds))
                        lastClassification = nil
                        showClassificationBadge = false
                        resetHints()
                        isGameActive = true
                        
                        if viewModel.isEngineTurn {
                            viewModel.isProcessing = true
                            Task {
                                await processMoveSequence()
                                viewModel.isProcessing = false
                            }
                        }
                    }) {
                        Text(L10n.tr("start_game"))
                            .font(.roundedSystem(.headline, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.primaryGradient)
                            .cornerRadius(16)
                            .shadow(color: Theme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                    // Time Control card
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.tr("time_control"))
                            .font(.roundedSystem(.headline, weight: .bold))
                            .foregroundColor(Theme.textMain)
                        
                        VStack(spacing: 12) {
                            Toggle(L10n.tr("activate_clock"), isOn: $isTimed.animation())
                                .toggleStyle(ThemeToggleStyle())
                            
                            if isTimed {
                                VStack(alignment: .leading, spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(L10n.tr("minutes") + ":")
                                                .font(.roundedSystem(.subheadline))
                                                .foregroundColor(Theme.textSecondary)
                                            Spacer()
                                            Text("\(Int(timeControlMinutes))")
                                                .font(.roundedSystem(.subheadline, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        Slider(value: $timeControlMinutes, in: 1...60, step: 1)
                                            .tint(Theme.accentColor)
                                    }
                                    
                                    Divider()
                                        .background(Color.white.opacity(0.12))
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(L10n.tr("increment_seconds") + ":")
                                                .font(.roundedSystem(.subheadline))
                                                .foregroundColor(Theme.textSecondary)
                                            Spacer()
                                            Text("\(Int(timeControlIncrementSeconds))")
                                                .font(.roundedSystem(.subheadline, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        Slider(value: $timeControlIncrementSeconds, in: 1...10, step: 1)
                                            .tint(Theme.accentColor)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Theme.panelBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Additional Settings card
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.tr("settings"))
                            .font(.roundedSystem(.headline, weight: .bold))
                            .foregroundColor(Theme.textMain)
                        
                        VStack(spacing: 12) {
                            Toggle(L10n.tr("show_analysis_toggle"), isOn: $showAnalysis)
                                .toggleStyle(ThemeToggleStyle())
                            
                            Toggle(L10n.tr("allow_hints"), isOn: $allowHints)
                                .toggleStyle(ThemeToggleStyle())
                            
                            Toggle(L10n.tr("show_best_moves_retro"), isOn: $showBestMovesRetrospectively)
                                .toggleStyle(ThemeToggleStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
            
            // Collapsible Header View at top
            VStack(spacing: 0) {
                Color.clear.frame(height: 0)
                CollapsibleHeaderView(
                    title: L10n.tr("singleplayer"),
                    subtitle: L10n.tr("setup_subtitle"),
                    iconName: "cpu",
                    scrollOffset: setupScrollOffset,
                    backAction: {
                        selectedGameMode = .none
                    }
                )
            }
            .background(
                Theme.background
                    .opacity(setupScrollOffset < -5 ? 1.0 : 0.0)
                    .ignoresSafeArea(edges: .top)
            )
            .animation(.easeInOut(duration: 0.15), value: setupScrollOffset < -5)
        }
        .onPreferenceChange(TaggedScrollOffsetPreferenceKey.self) { values in
            if let val = values["setupBot"] {
                self.setupScrollOffset = val
            }
        }
    }
    
    var modeSelectionView: some View {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        return ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    if selectedTab == 0 && !isGameActive && selectedGameMode == .none {
                        ScrollOffsetDetector(coordinateSpace: "gameTabContainer", tag: "modeSelection")
                    }
                    
                    Spacer().frame(height: isIPad ? 224 : 216)
                    
                    VStack(spacing: 24) {
                        // Gegen Bot spielen
                        Button(action: {
                            selectedGameMode = .bot
                        }) {
                            VStack(spacing: 12) {
                                Spacer()
                                Image(systemName: "cpu")
                                    .font(.system(size: 48))
                                    .foregroundStyle(Theme.primaryGradient)
                                
                                Text(L10n.tr("play_against_bot"))
                                    .font(.title2.bold())
                                    .foregroundColor(Theme.textMain)
                                
                                Text(L10n.tr("bot_mode_desc"))
                                    .font(.subheadline)
                                    .foregroundColor(Theme.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Theme.panelBackground)
                            .cornerRadius(24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        // Gegen Freund spielen
                        Button(action: {
                            selectedGameMode = .friend
                        }) {
                            VStack(spacing: 12) {
                                Spacer()
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(Theme.primaryGradient)
                                
                                Text(L10n.tr("play_against_friend"))
                                    .font(.title2.bold())
                                    .foregroundColor(Theme.textMain)
                                
                                Text(L10n.tr("friend_mode_desc"))
                                    .font(.subheadline)
                                    .foregroundColor(Theme.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Theme.panelBackground)
                            .cornerRadius(24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal)
                }
            }
            
            // Collapsible Header View at top
            VStack(spacing: 0) {
                Color.clear.frame(height: 0)
                CollapsibleHeaderView(
                    title: L10n.tr("choose_mode"),
                    subtitle: L10n.tr("choose_mode_subtitle"),
                    iconName: "gamecontroller.fill",
                    scrollOffset: modeSelectionScrollOffset
                )
            }
            .background(
                Theme.background
                    .opacity(modeSelectionScrollOffset < -5 ? 1.0 : 0.0)
                    .ignoresSafeArea(edges: .top)
            )
            .animation(.easeInOut(duration: 0.15), value: modeSelectionScrollOffset < -5)
        }
        .onPreferenceChange(TaggedScrollOffsetPreferenceKey.self) { values in
            if let val = values["modeSelection"] {
                self.modeSelectionScrollOffset = val
            }
        }
    }
    
    var friendSetupView: some View {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        return ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    if selectedTab == 0 && !isGameActive && selectedGameMode == .friend {
                        ScrollOffsetDetector(coordinateSpace: "gameTabContainer", tag: "setupFriend")
                    }
                    
                    Spacer().frame(height: isIPad ? 224 : 216)
                    
                    // Start Game button
                    Button(action: {
                        viewModel.isFriendMode = true
                        viewModel.flipBoardAfterMoves = flipBoardAfterMoves
                        viewModel.allowHints = allowHints
                        viewModel.showBestMovesRetrospectively = showBestMovesRetrospectively
                        
                        evaluationCache.removeAll()
                        gameSaved = false
                        viewModel.startGame(timed: isTimed, durationSeconds: Int(timeControlMinutes * 60), incrementSeconds: Int(timeControlIncrementSeconds))
                        lastClassification = nil
                        showClassificationBadge = false
                        resetHints()
                        isGameActive = true
                    }) {
                        Text(L10n.tr("start_game"))
                            .font(.roundedSystem(.headline, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.primaryGradient)
                            .cornerRadius(16)
                            .shadow(color: Theme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                    // Time Control card
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.tr("time_control"))
                            .font(.roundedSystem(.headline, weight: .bold))
                            .foregroundColor(Theme.textMain)
                        
                        VStack(spacing: 12) {
                            Toggle(L10n.tr("activate_clock"), isOn: $isTimed.animation())
                                .toggleStyle(ThemeToggleStyle())
                            
                            if isTimed {
                                VStack(alignment: .leading, spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(L10n.tr("minutes") + ":")
                                                .font(.roundedSystem(.subheadline))
                                                .foregroundColor(Theme.textSecondary)
                                            Spacer()
                                            Text("\(Int(timeControlMinutes))")
                                                .font(.roundedSystem(.subheadline, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        Slider(value: $timeControlMinutes, in: 1...60, step: 1)
                                            .tint(Theme.accentColor)
                                    }
                                    
                                    Divider()
                                        .background(Color.white.opacity(0.12))
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(L10n.tr("increment_seconds") + ":")
                                                .font(.roundedSystem(.subheadline))
                                                .foregroundColor(Theme.textSecondary)
                                            Spacer()
                                            Text("\(Int(timeControlIncrementSeconds))")
                                                .font(.roundedSystem(.subheadline, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        Slider(value: $timeControlIncrementSeconds, in: 1...10, step: 1)
                                            .tint(Theme.accentColor)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Theme.panelBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Additional Settings card with flip option
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.tr("settings"))
                            .font(.roundedSystem(.headline, weight: .bold))
                            .foregroundColor(Theme.textMain)
                        
                        VStack(spacing: 12) {
                            Toggle(L10n.tr("show_analysis_toggle"), isOn: $showAnalysis)
                                .toggleStyle(ThemeToggleStyle())
                            
                            Toggle(L10n.tr("allow_hints"), isOn: $allowHints)
                                .toggleStyle(ThemeToggleStyle())
                            
                            Toggle(L10n.tr("show_best_moves_retro"), isOn: $showBestMovesRetrospectively)
                                .toggleStyle(ThemeToggleStyle())
                            
                            Toggle(L10n.tr("flip_board_after_moves"), isOn: $flipBoardAfterMoves)
                                .toggleStyle(ThemeToggleStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
            
            // Collapsible Header View at top
            VStack(spacing: 0) {
                Color.clear.frame(height: 0)
                CollapsibleHeaderView(
                    title: L10n.tr("setup_friend_title"),
                    subtitle: L10n.tr("setup_friend_subtitle"),
                    iconName: "person.2.fill",
                    scrollOffset: friendSetupScrollOffset,
                    backAction: {
                        selectedGameMode = .none
                    }
                )
            }
            .background(
                Theme.background
                    .opacity(friendSetupScrollOffset < -5 ? 1.0 : 0.0)
                    .ignoresSafeArea(edges: .top)
            )
            .animation(.easeInOut(duration: 0.15), value: friendSetupScrollOffset < -5)
        }
        .onPreferenceChange(TaggedScrollOffsetPreferenceKey.self) { values in
            if let val = values["setupFriend"] {
                self.friendSetupScrollOffset = val
            }
        }
    }
    
    @ViewBuilder
    private func colorSelectionIcon(for choice: PlayerColor) -> some View {
        switch choice {
        case .white:
            Image("wk")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
        case .black:
            Image("bk")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
        case .random:
            HStack(spacing: -14) {
                Image("wk")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                Image("bk")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            }
            .frame(height: 32)
        }
    }
    
    // MARK: - Custom Tab Bar
    var customTabBar: some View {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        return HStack(spacing: 0) {
            tabButton(index: 0, title: L10n.tr("game"), systemImage: "chevron.forward.2")
            tabButton(index: 1, title: L10n.tr("history"), systemImage: "clock.arrow.circlepath")
            tabButton(index: 2, title: L10n.tr("training"), systemImage: "dumbbell.fill")
            tabButton(index: 3, title: L10n.tr("analysis"), systemImage: "magnifyingglass")
            tabButton(index: 4, title: L10n.tr("settings"), systemImage: "gearshape.fill")
        }
        .padding(.horizontal, isIPad ? 12 : 8)
        .padding(.vertical, isIPad ? 12 : 8)
        .background(Theme.panelBackground)
        .cornerRadius(isIPad ? 32 : 24)
        .overlay(
            RoundedRectangle(cornerRadius: isIPad ? 32 : 24)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 4)
        .padding(.horizontal, isIPad ? 24 : 16)
        .padding(.bottom, isIPad ? 8 : 2)
    }
    
    private func tabButton(index: Int, title: String, systemImage: String) -> some View {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        let isSelected = selectedTab == index
        return Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                selectedTab = index
            }
            HapticManager.shared.playImpact(.light)
        }) {
            VStack(spacing: isIPad ? 6 : 4) {
                Image(systemName: systemImage)
                    .font(.system(size: isIPad ? 22 : 18, weight: .semibold, design: .rounded))
                Text(title)
                    .font(.system(size: isIPad ? 11 : 9, weight: .bold, design: .rounded))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(isSelected ? Theme.accentColor : Theme.textSecondary.opacity(0.7))
            .padding(.vertical, isIPad ? 10 : 8)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: isIPad ? 24 : 16)
                            .fill(Theme.accentColor.opacity(0.12))
                            .matchedGeometryEffect(id: "activeTabBackground", in: tabNamespace)
                    }
                }
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func pieceKindName(_ kind: Piece.Kind) -> String {
        switch kind {
        case .queen:
            return appLanguage == "de" ? "Dame" : "Queen"
        case .rook:
            return appLanguage == "de" ? "Turm" : "Rook"
        case .bishop:
            return appLanguage == "de" ? "Läufer" : "Bishop"
        case .knight:
            return appLanguage == "de" ? "Springer" : "Knight"
        default:
            return ""
        }
    }
}

struct SettingsView: View {
    var isActive: Bool = true
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("appTheme") private var appTheme = "standard"
    @AppStorage("appIcon") private var appIcon = "elysium"
    @AppStorage("showBoardCoordinates") private var showBoardCoordinates = true
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @AppStorage("screenShakeEnabled") private var screenShakeEnabled = false
    @AppStorage("botName") private var botName = "Stockfish"
    @State private var showingResetAlert = false
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        ZStack(alignment: .top) {
            Theme.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    if isActive {
                        ScrollOffsetDetector(coordinateSpace: "settingsContainer")
                    }
                    
                    Spacer().frame(height: isIPad ? 224 : 216)
                    
                    // Theme Selection Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.tr("theme_selection"))
                            .font(.headline)
                            .foregroundColor(Theme.textMain)
                        
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                            ForEach(Theme.ThemeType.allCases) { type in
                                Button(action: {
                                    withAnimation {
                                        appTheme = type.rawValue
                                    }
                                    HapticManager.shared.playImpact(.medium)
                                }) {
                                    VStack(spacing: 8) {
                                        // Miniature Board Preview
                                        HStack(spacing: 0) {
                                            Rectangle()
                                                .fill(Theme.lightSquareForPreview(type))
                                                .frame(height: 40)
                                            Rectangle()
                                                .fill(Theme.darkSquareForPreview(type))
                                                .frame(height: 40)
                                        }
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                        )
                                        
                                        Text(type.displayName)
                                            .font(.roundedSystem(.caption, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .padding(8)
                                    .background(appTheme == type.rawValue ? Theme.accentColor.opacity(0.15) : Theme.panelBackground)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(appTheme == type.rawValue ? Theme.accentColor : Color.white.opacity(0.08), lineWidth: appTheme == type.rawValue ? 2 : 1)
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }
                    
                    // Language Selection Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.tr("lang_selection"))
                            .font(.headline)
                            .foregroundColor(Theme.textMain)
                        
                        HStack(spacing: 16) {
                            ForEach(AppLanguage.allCases) { lang in
                                Button(action: {
                                    withAnimation {
                                        appLanguage = lang.rawValue
                                    }
                                }) {
                                    Text(lang.displayName)
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(appLanguage == lang.rawValue ? Theme.accentColor.opacity(0.15) : Theme.panelBackground)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(appLanguage == lang.rawValue ? Theme.accentColor : Color.white.opacity(0.12), lineWidth: 2)
                                        )
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }
                    
                    // App Icon Selection Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.tr("app_icon_selection"))
                            .font(.headline)
                            .foregroundColor(Theme.textMain)
                        
                        HStack(spacing: 16) {
                            ForEach(["elysium", "nebula", "eclipse", "sophie"], id: \.self) { icon in
                                Button(action: {
                                    withAnimation {
                                        appIcon = icon
                                        changeAppIcon(to: icon)
                                    }
                                }) {
                                    VStack(alignment: .center, spacing: 8) {
                                        Image(icon)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 60, height: 60)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                            )
                                            .shadow(radius: 3)
                                        
                                        Text(icon == "elysium" ? L10n.tr("standard") :
                                             icon == "nebula" ? L10n.tr("dark_neon") :
                                             icon == "eclipse" ? L10n.tr("midnight_gold") :
                                             L10n.tr("sweet_rose"))
                                            .font(.caption.bold())
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(appIcon == icon ? Theme.accentColor.opacity(0.15) : Theme.panelBackground)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(appIcon == icon ? Theme.accentColor : Color.white.opacity(0.12), lineWidth: 2)
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }
                    
                    // Board & Game Settings Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.tr("game_settings"))
                            .font(.headline)
                            .foregroundColor(Theme.textMain)
                        
                        VStack(spacing: 12) {
                            Toggle(L10n.tr("board_coordinates"), isOn: $showBoardCoordinates)
                                .toggleStyle(ThemeToggleStyle())
                            
                            Toggle(L10n.tr("haptic_feedback"), isOn: $hapticFeedbackEnabled)
                                .toggleStyle(ThemeToggleStyle())
                            
                            Toggle(L10n.tr("screen_shake"), isOn: $screenShakeEnabled)
                                .toggleStyle(ThemeToggleStyle())
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(L10n.tr("bot_name_label"))
                                    .font(.caption.bold())
                                    .foregroundColor(Theme.textSecondary)
                                
                                TextField("Stockfish", text: $botName)
                                    .font(.roundedSystem(.body, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.black.opacity(0.20))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Theme.panelBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                    }
                    
                    // Danger Zone Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.tr("danger_zone"))
                            .font(.headline)
                            .foregroundColor(Theme.textMain)
                        
                        Button(action: {
                            showingResetAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text(L10n.tr("reset_history"))
                                    .bold()
                                Spacer()
                            }
                            .foregroundColor(.red)
                            .padding()
                            .background(Theme.panelBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    // About Section
                    VStack(spacing: 8) {
                        Text(L10n.tr("about_app"))
                            .font(.headline)
                            .foregroundColor(Theme.textMain)
                        
                        Text(L10n.tr("about_desc"))
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                .padding()
            }
            .alert(isPresented: $showingResetAlert) {
                Alert(
                    title: Text(L10n.tr("reset_history")),
                    message: Text(L10n.tr("confirm_reset")),
                    primaryButton: .destructive(Text(L10n.tr("delete"))) {
                        GameHistoryStore.shared.clearAll()
                    },
                    secondaryButton: .cancel(Text(L10n.tr("cancel")))
                )
            }
            
            // Collapsible Header View at top
            VStack(spacing: 0) {
                Color.clear.frame(height: 0)
                CollapsibleHeaderView(
                    title: L10n.tr("settings"),
                    subtitle: appLanguage == "de" ? "Passe das Design, die Sprache und Spielparameter der App an." : "Customize the app design, language, and gameplay parameters.",
                    iconName: "gearshape.fill",
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
        .coordinateSpace(name: "settingsContainer")
        .onPreferenceChange(TaggedScrollOffsetPreferenceKey.self) { values in
            if let val = values["settingsContainer"] {
                self.scrollOffset = val
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func changeAppIcon(to iconName: String) {
        let targetName = iconName == "elysium" ? nil : iconName
        
        guard UIApplication.shared.supportsAlternateIcons else {
            return
        }
        
        UIApplication.shared.setAlternateIconName(targetName) { error in
            if let error = error {
                print("Error changing app icon: \(error.localizedDescription)")
            }
        }
    }
}

struct PlayerProfileView: View {
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("appTheme") private var appTheme = "standard"
    let name: String
    let rating: String
    let avatarImage: String
    let isEngine: Bool
    let timeRemaining: String?
    let isActive: Bool
    var mateIn: Int? = nil
    var hintAction: (() -> Void)? = nil
    var hintStep: Int = 0
    var isAnalyzingHint: Bool = false
    var isAnalysisMode: Bool = false
    var isCalculatingBestMove: Bool = false
    var isBestMoveActive: Bool = false
    var isBestMoveDisabled: Bool = false
    var bestMoveAction: (() -> Void)? = nil
    var showBestMoveButton: Bool = false
    var showHintButton: Bool = true
    var showAccuracy: Bool = false
    var accuracyValue: Double? = nil
    
    private func hintButtonText(for step: Int) -> String {
        switch step {
        case 1: return L10n.tr("hint_narrow")
        case 2: return L10n.tr("show_arrow")
        case 3: return L10n.tr("hint_hide")
        default: return L10n.tr("hint")
        }
    }
    
    var body: some View {
        let _ = appLanguage
        let _ = appTheme
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        
        HStack(alignment: .center) {
            // Profile Info (Left)
            HStack(spacing: isIPad ? 12 : 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: isIPad ? 52 : 40, height: isIPad ? 52 : 40)
                    
                    Image(systemName: avatarImage)
                        .font(isIPad ? .title2 : .body)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(name)
                            .font(isIPad ? Font.title3.bold() : Font.headline)
                            .foregroundColor(Theme.textMain)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .frame(maxWidth: isIPad ? 220 : 110, alignment: .leading)
                        
                        if let m = mateIn {
                            Text("M\(m)")
                                .font(isIPad ? Font.body.bold() : Font.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, isIPad ? 8 : 6)
                                .padding(.vertical, isIPad ? 3 : 2)
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(4)
                        }
                    }
                    
                    if !rating.isEmpty {
                        Text("(\(rating))")
                            .font(isIPad ? Font.body : Font.subheadline)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            // Buttons and Info Grid (Right)
            let colWidth: CGFloat = isIPad ? 140 : 105
            let colHeight: CGFloat = isIPad ? 44 : 34
            
            let hasHint = !isAnalysisMode && showHintButton && hintAction != nil
            let hasBestMove = isAnalysisMode || (showBestMoveButton && bestMoveAction != nil)
            let hasClock = timeRemaining != nil
            let hasAccuracy = showAccuracy && accuracyValue != nil
            let showRightSide = hasHint || hasBestMove || hasClock || hasAccuracy
            
            if showRightSide {
                VStack(alignment: .trailing, spacing: 6) {
                    let drawRow1 = hasHint || hasBestMove
                    let drawRow2 = hasClock || hasAccuracy
                    
                    if drawRow1 {
                        HStack(spacing: 8) {
                            if hasHint {
                                Button(action: hintAction!) {
                                    HStack(spacing: 4) {
                                        if isAnalyzingHint {
                                            ProgressView()
                                                .tint(hintStep > 0 ? .black : Theme.highlightSquare)
                                                .scaleEffect(isIPad ? 0.9 : 0.65)
                                                .frame(width: isIPad ? 20 : 14, height: isIPad ? 20 : 14)
                                        } else {
                                            Image(systemName: hintStep > 0 ? "lightbulb.fill" : "lightbulb")
                                                .font(isIPad ? Font.body : Font.caption)
                                        }
                                        
                                        Text(hintButtonText(for: hintStep))
                                            .font(isIPad ? Font.body.bold() : Font.caption.bold())
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                    }
                                    .foregroundColor(hintStep > 0 ? .black : Theme.highlightSquare)
                                    .padding(.horizontal, isIPad ? 8 : 6)
                                    .frame(width: colWidth, height: colHeight)
                                    .background(hintStep > 0 ? Theme.highlightSquare : Theme.panelBackground)
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Theme.highlightSquare.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                                .disabled(isAnalyzingHint)
                            } else if drawRow2 && hasClock {
                                Color.clear.frame(width: colWidth, height: colHeight)
                            }
                            
                            if hasBestMove {
                                if isAnalysisMode {
                                    Button(action: {
                                        bestMoveAction?()
                                    }) {
                                        HStack(spacing: 4) {
                                            if isCalculatingBestMove {
                                                ProgressView()
                                                    .tint(isBestMoveActive ? .black : Theme.highlightSquare)
                                                    .scaleEffect(isIPad ? 0.9 : 0.65)
                                                    .frame(width: isIPad ? 20 : 14, height: isIPad ? 20 : 14)
                                            } else {
                                                Image(systemName: "arrow.up.right")
                                                    .font(isIPad ? Font.body : Font.caption)
                                            }
                                            
                                            Text(L10n.tr("best_move"))
                                                .font(isIPad ? Font.body.bold() : Font.caption.bold())
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                        }
                                        .foregroundColor(isBestMoveActive ? .black : (isBestMoveDisabled ? Color.gray : Theme.highlightSquare))
                                        .padding(.horizontal, isIPad ? 8 : 6)
                                        .frame(width: colWidth, height: colHeight)
                                        .background(isBestMoveActive ? Theme.highlightSquare : (isBestMoveDisabled ? Theme.panelBackground.opacity(0.5) : Theme.panelBackground))
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(isBestMoveActive ? Color.clear : (isBestMoveDisabled ? Color.clear : Theme.highlightSquare.opacity(0.3)), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    .disabled(isBestMoveDisabled || isCalculatingBestMove)
                                } else {
                                    Button(action: bestMoveAction!) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.up.right")
                                                .font(isIPad ? Font.body : Font.caption)
                                            Text(L10n.tr("best_move"))
                                                .font(isIPad ? Font.body.bold() : Font.caption.bold())
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                        }
                                        .foregroundColor(isBestMoveDisabled ? Color.gray : .white)
                                        .padding(.horizontal, isIPad ? 8 : 6)
                                        .frame(width: colWidth, height: colHeight)
                                        .background(isBestMoveDisabled ? Theme.panelBackground.opacity(0.5) : Theme.highlightSquare.opacity(0.85))
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(isBestMoveDisabled ? Color.clear : Theme.highlightSquare.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    .disabled(isBestMoveDisabled)
                                    .opacity(isBestMoveDisabled ? 0.4 : 1.0)
                                }
                            } else if drawRow2 && hasAccuracy {
                                Color.clear.frame(width: colWidth, height: colHeight)
                            }
                        }
                    }
                    
                    if drawRow2 {
                        HStack(spacing: 8) {
                            if hasClock, let time = timeRemaining {
                                Text(time)
                                    .font(.system(size: isIPad ? 22 : 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(isActive ? .white : .gray)
                                    .frame(width: colWidth, height: colHeight)
                                    .background(isActive ? Theme.highlightSquare.opacity(0.3) : Color.black.opacity(0.2))
                                    .cornerRadius(isIPad ? 8 : 6)
                            } else if drawRow1 && hasHint {
                                Color.clear.frame(width: colWidth, height: colHeight)
                            }
                            
                            if hasAccuracy, let accuracy = accuracyValue {
                                AccuracyCounterView(accuracy: accuracy)
                                    .frame(width: colWidth, height: colHeight)
                            } else if drawRow1 && hasBestMove {
                                Color.clear.frame(width: colWidth, height: colHeight)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ClassificationCounterView: View {
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("appTheme") private var appTheme = "standard"
    let counts: [MoveClassification: Int]
    
    let displayOrder: [MoveClassification] = [
        .brilliant, .great, .best, .excellent, .good, .book, .inaccuracy, .mistake, .blunder
    ]
    
    var body: some View {
        let _ = appLanguage
        let _ = appTheme
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: isIPad ? 14 : 10) {
                ForEach(displayOrder, id: \.self) { classification in
                    let count = counts[classification] ?? 0
                    if count > 0 {
                        HStack(spacing: isIPad ? 8 : 6) {
                            MoveClassificationBadge(classification: classification, size: isIPad ? 34 : 20)
                            
                            Text("\(count)")
                                .font(isIPad ? .title3.monospacedDigit().bold() : .footnote.monospacedDigit().bold())
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, isIPad ? 12 : 8)
                        .padding(.vertical, isIPad ? 8 : 5)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(isIPad ? 8 : 6)
                    }
                }
            }
        }
    }
}

struct EvalBarView: View {
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("appTheme") private var appTheme = "standard"
    let eval: Int?
    let isFlipped: Bool
    
    var body: some View {
        let _ = appLanguage
        let _ = appTheme
        GeometryReader { geometry in
            // eval is in white's POV: positive = white winning, negative = black winning
            let rawScore = Double(eval ?? 0) / 100.0
            
            // atan gives smooth S-curve so small advantages are clearly visible
            let whiteFraction = 0.5 + (atan(rawScore / 3.0) / .pi)
            let whiteHeight = geometry.size.height * whiteFraction
            let blackHeight = geometry.size.height - whiteHeight
            
            VStack(spacing: 0) {
                if isFlipped {
                    // White on top, Black on bottom
                    Rectangle()
                        .fill(Color.white)
                        .frame(height: whiteHeight)
                    Rectangle()
                        .fill(Color(white: 0.15))
                } else {
                    // Black on top, White on bottom
                    Rectangle()
                        .fill(Color(white: 0.15))
                        .frame(height: blackHeight)
                    Rectangle()
                        .fill(Color.white)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: eval)
            
            // Score text on the winning side
            if let evalScore = eval {
                let scoreVal = Double(evalScore) / 100.0
                let absScoreStr = String(format: "%.1f", abs(scoreVal))
                
                // Determine if the text should be at the top or bottom
                // NOT flipped: White winning (scoreVal > 0) -> bottom, Black winning (scoreVal < 0) -> top
                // Flipped: White winning (scoreVal > 0) -> top, Black winning (scoreVal < 0) -> bottom
                let isTop = isFlipped ? (scoreVal > 0) : (scoreVal < 0)
                let textColor = scoreVal > 0 ? Color.black : Color.white
                
                VStack {
                    if isTop {
                        Text(absScoreStr)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(textColor)
                            .padding(.top, 4)
                        Spacer()
                    } else {
                        Spacer()
                        Text(absScoreStr)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(textColor)
                            .padding(.bottom, 4)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(width: 16)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct FlipDigitView: View {
    let value: Int
    
    var body: some View {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        Text("\(value)")
            .font(.system(size: isIPad ? 28 : 20, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .frame(width: isIPad ? 22 : 16, height: isIPad ? 38 : 28)
            .background(Color.black)
            .cornerRadius(isIPad ? 6 : 4)
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                    .offset(y: 0),
                alignment: .center
            )
            .shadow(color: .black.opacity(0.5), radius: 2, y: 2)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: value)
    }
}

struct AccuracyCounterView: View {
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("appTheme") private var appTheme = "standard"
    let accuracy: Double
    
    var body: some View {
        let _ = appLanguage
        let _ = appTheme
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        HStack(spacing: 2) {
            let accuracyInt = Int(round(accuracy))
            let digits = String(accuracyInt).compactMap { Int(String($0)) }
            
            ForEach(0..<digits.count, id: \.self) { index in
                FlipDigitView(value: digits[index])
            }
            
            Text("%")
                .font(.system(size: isIPad ? 28 : 20, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, isIPad ? 6 : 4)
        }
        .padding(.horizontal, isIPad ? 6 : 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.3))
        .cornerRadius(isIPad ? 8 : 6)
    }
}

struct MaterialCounterView: View {
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("appTheme") private var appTheme = "standard"
    let capturedPieces: [Piece.Kind]
    let capturedColor: Piece.Color
    let advantage: Int
    
    // Group identical pieces for cleaner display (like chess.com does)
    var groupedPieces: [(kind: Piece.Kind, count: Int)] {
        var counts: [Piece.Kind: Int] = [:]
        for piece in capturedPieces {
            counts[piece, default: 0] += 1
        }
        // Sort by value (Q, R, B, N, P)
        let order: [Piece.Kind] = [.queen, .rook, .bishop, .knight, .pawn]
        return order.compactMap { kind in
            if let count = counts[kind], count > 0 {
                return (kind, count)
            }
            return nil
        }
    }
    
    var body: some View {
        let _ = appLanguage
        let _ = appTheme
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        HStack(spacing: 4) {
            ForEach(groupedPieces, id: \.kind) { group in
                HStack(spacing: isIPad ? -16 : -10) { // Overlap identical pieces
                    ForEach(0..<group.count, id: \.self) { _ in
                        Image(imageName(for: group.kind, color: capturedColor))
                            .resizable()
                            .scaledToFit()
                            .frame(width: isIPad ? 30 : 18, height: isIPad ? 30 : 18)
                    }
                }
            }
            if advantage > 0 {
                Text("+\(advantage)")
                    .font(isIPad ? .body.bold() : .caption.bold())
                    .foregroundColor(Theme.textSecondary)
                    .padding(.leading, isIPad ? 8 : 4)
            }
            Spacer()
        }
        .frame(height: isIPad ? 36 : 24)
    }
    
    private func imageName(for kind: Piece.Kind, color: Piece.Color) -> String {
        let prefix = color == .white ? "w" : "b"
        let suffix: String
        switch kind {
        case .pawn: suffix = "p"
        case .knight: suffix = "n"
        case .bishop: suffix = "b"
        case .rook: suffix = "r"
        case .queen: suffix = "q"
        case .king: suffix = "k"
        }
        return prefix + suffix
    }
}
