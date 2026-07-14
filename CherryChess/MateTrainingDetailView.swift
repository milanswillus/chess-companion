import SwiftUI
import ChessKit

struct MateTrainingDetailView: View {
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("appTheme") private var appTheme = "cherry"
    
    let scenario: MateScenario
    let onBack: () -> Void
    
    @StateObject private var viewModel = GameViewModel()
    @EnvironmentObject private var analyzer: StockfishAnalyzer
    
    @State private var isProcessing = false
    
    
    @State private var initialMateDistance: Int? = nil
    @State private var currentMateDistance: Int? = nil
    @State private var playerMovesCount = 0
    @State private var wastedMoves = 0
    @State private var mateInMoves = "10+"
    @State private var hintBestMoveArrow: (start: Square, end: Square)? = nil
    @State private var isCalculatingHint = false
    
    var body: some View {
        let _ = appLanguage
        let _ = appTheme
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        
        ZStack {
            Theme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: isIPad ? 12 : 8) {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text(L10n.tr("back"))
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .font(isIPad ? .title3.bold() : .body.bold())
                        .foregroundColor(Theme.textMain)
                        .padding(.horizontal, isIPad ? 18 : 12)
                        .padding(.vertical, isIPad ? 14 : 12)
                        .background(Theme.panelBackground)
                        .cornerRadius(isIPad ? 12 : 8)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Spacer()
                    
                    Text(appLanguage == "de" ? scenario.nameGerman : scenario.nameEnglish)
                        .font(.roundedSystem(isIPad ? .title3 : .body, weight: .bold))
                        .foregroundColor(Theme.textMain)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    
                    Spacer()
                    
                    HStack(spacing: isIPad ? 12 : 8) {
                        Button(action: requestHint) {
                            ZStack {
                                if isCalculatingHint {
                                    ProgressView()
                                        .tint(Theme.accentColor)
                                        .scaleEffect(isIPad ? 1.2 : 0.9)
                                } else {
                                    Image(systemName: hintBestMoveArrow != nil ? "lightbulb.fill" : "lightbulb")
                                        .font(.system(size: isIPad ? 22 : 18, weight: .bold))
                                        .foregroundColor(hintBestMoveArrow != nil ? .yellow : Theme.textSecondary)
                                }
                            }
                            .padding(.horizontal, isIPad ? 18 : 12)
                            .padding(.vertical, isIPad ? 14 : 12)
                            .background(Theme.panelBackground)
                            .cornerRadius(isIPad ? 12 : 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: isIPad ? 12 : 8)
                                    .stroke(hintBestMoveArrow != nil ? Theme.accentColor : Theme.line.opacity(0.06), lineWidth: hintBestMoveArrow != nil ? 2 : 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .disabled(isProcessing || viewModel.gameOver)
                        
                        Button(action: resetScenario) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: isIPad ? 22 : 18, weight: .bold))
                                .foregroundColor(Theme.textSecondary)
                                .padding(.horizontal, isIPad ? 18 : 12)
                                .padding(.vertical, isIPad ? 14 : 12)
                                .background(Theme.panelBackground)
                                .cornerRadius(isIPad ? 12 : 8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: isIPad ? 12 : 8)
                                        .stroke(Theme.line.opacity(0.06), lineWidth: 1)
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding()
                
                // Mate Counter
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text(appLanguage == "de" ? "MATT IN" : "MATE IN")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.5)
                            .foregroundColor(Theme.textSecondary)
                        
                        Text(mateInMoves)
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(mateInMoves == "10+" ? Theme.textSecondary : Theme.accentColor)
                            .themedCardShadow()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Theme.panelBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Theme.line.opacity(0.06), lineWidth: 1)
                            )
                    )
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
                
                // Chess Board
                ChessBoardView(viewModel: viewModel, bestMoveArrow: hintBestMoveArrow)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .disabled(isProcessing || viewModel.gameOver)
                
                let hasWastedMoves = wastedMoves > 0
                HStack(spacing: 8) {
                    Image(systemName: hasWastedMoves ? "exclamationmark.circle.fill" : "info.circle")
                        .foregroundColor(hasWastedMoves ? .orange : Theme.textSecondary)
                    Text(String(format: L10n.tr("more_moves_than_needed"), wastedMoves))
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundColor(hasWastedMoves ? .orange : Theme.textSecondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(hasWastedMoves ? Color.orange.opacity(0.15) : Theme.panelBackground)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(hasWastedMoves ? Color.orange.opacity(0.25) : Theme.line.opacity(0.06), lineWidth: 1)
                )
                .padding(.bottom, 8)
                
                // Bottom instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text(appLanguage == "de" ? "Regeln:" : "Rules:")
                        .font(.system(.headline, design: .rounded).bold())
                        .foregroundColor(Theme.textMain)
                    Text(appLanguage == "de" ? 
                         "• Setze den Bot in dieser Stellung matt.\n• Der Bot spielt mit maximaler Stärke.\n• Jeder Fehler, der zu einem Remis führt, bricht das Spiel sofort ab." : 
                         "• Checkmate the bot from this position.\n• The bot plays at maximum strength.\n• Any mistake leading to a draw immediately terminates the game.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                        .lineSpacing(4)
                }
                .padding()
                .background(Theme.panelBackground)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.line.opacity(0.06), lineWidth: 1)
                )
                .padding()
                
                Spacer()
            }
            
            // Promotion Picker Overlay (Clean, premium custom modal)
            if viewModel.showPromotionPicker {
                PromotionPickerView(promotingColor: viewModel.pendingPromotionMove?.piece.color ?? viewModel.playerColor) { kind in
                    viewModel.completePromotion(to: kind)
                }
                .zIndex(200)
            }
        }
        .onAppear {
            resetScenario()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didMakeMove)) { notification in
            guard notification.object as? GameViewModel === viewModel else { return }
            hintBestMoveArrow = nil
            if !viewModel.gameOver && viewModel.board.position.sideToMove == .black {
                Task {
                    await processMateMoveSequence()
                }
            }
        }
    }
    
    private func resetScenario() {
        isProcessing = false
        viewModel.startGame(from: scenario.fen, playerColor: scenario.initialMoveColor, timed: false, durationSeconds: 0)
        
        initialMateDistance = nil
        currentMateDistance = nil
        playerMovesCount = 0
        wastedMoves = 0
        mateInMoves = "10+"
        hintBestMoveArrow = nil
        isCalculatingHint = false
        
        Task {
            await calculateInitialMate()
        }
    }
    
    private func checkDrawOrKingsOnly() -> Bool {
        if case .draw = viewModel.board.state {
            return true
        }
        let pieces = Square.allCases.compactMap { viewModel.board.position.piece(at: $0) }
        if pieces.count == 2 {
            let hasNonKing = pieces.contains { $0.kind != .king }
            if !hasNonKing {
                return true
            }
        }
        return false
    }
    
    
    
    private func calculateInitialMate() async {
        for _ in 0..<50 {
            if analyzer.isReady { break }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        guard analyzer.isReady else { return }
        
        let result = await analyzer.evaluate(fen: scenario.fen, depth: 18, limitSkill: false)
        if let result = result, let mate = result.mate {
            let newSideToMove = Position(fen: scenario.fen)?.sideToMove ?? .white
            let mateWhitePOV = newSideToMove == .white ? mate : -mate
            let playerColor = scenario.initialMoveColor
            
            let m: Int? = {
                if playerColor == .white && mateWhitePOV > 0 { return mateWhitePOV }
                if playerColor == .black && mateWhitePOV < 0 { return abs(mateWhitePOV) }
                return nil
            }()
            
            await MainActor.run {
                if let validM = m {
                    self.initialMateDistance = validM
                    self.currentMateDistance = validM
                    updateMateInMoves(validM)
                } else {
                    self.mateInMoves = "10+"
                }
            }
        }
    }
    
    private func updateMateInMoves(_ mate: Int) {
        if mate <= 10 {
            mateInMoves = "\(mate)"
        } else {
            mateInMoves = "10+"
        }
    }
    
    /// Wasted moves = how many player moves exceed the scenario's known optimal.
    private func updateWastedMoves() {
        wastedMoves = max(0, playerMovesCount - scenario.optimalMoves)
    }
    
    private func processMateMoveSequence() async {
        guard viewModel.lastMove != nil,
              viewModel.lastPlayerMoveFenBefore != nil,
              viewModel.board.position.sideToMove == .black else {
            return
        }

        if isProcessing {
            return
        }
        await MainActor.run { isProcessing = true }
        
        // Wait for engine to be ready
        for _ in 0..<100 {
            if analyzer.isReady { break }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        guard analyzer.isReady else {
            await MainActor.run { isProcessing = false }
            return
        }

        let fenAfterPlayer = viewModel.board.position.fen

        await MainActor.run {
            playerMovesCount += 1
            updateWastedMoves()
        }

        // 1. Check immediate checkmate
        if case .checkmate = viewModel.board.state {
            await MainActor.run {
                viewModel.gameOver = true
                isProcessing = false
            }
            return
        }
        
        // Check actual draw / only kings
        if checkDrawOrKingsOnly() {
            await MainActor.run {
                viewModel.gameOver = true
                isProcessing = false
            }
            return
        }
        
        // 2. Evaluate player move and prepare engine reply
        let evalResult = await analyzer.evaluate(fen: fenAfterPlayer, depth: 12, limitSkill: false, movetime: 300)

        if let result = evalResult {
            let newSideToMove = Position(fen: fenAfterPlayer)?.sideToMove ?? .white
            let mateWhitePOV = result.mate.map { newSideToMove == .white ? $0 : -$0 }
            
            let m: Int? = {
                guard let mw = mateWhitePOV else { return nil }
                if scenario.initialMoveColor == .white && mw > 0 { return mw }
                if scenario.initialMoveColor == .black && mw < 0 { return abs(mw) }
                return nil
            }()
            
            if let validM = m {
                await MainActor.run {
                    self.currentMateDistance = validM
                    updateMateInMoves(validM)
                }
            } else {
                await MainActor.run {
                    mateInMoves = "10+"
                }
            }

            if let move = EngineLANParser.parse(move: result.bestMove, for: .black, in: viewModel.board.position) {
                await MainActor.run {
                    viewModel.lastPlayerMoveFenBefore = fenAfterPlayer
                    viewModel.makeEngineMove(start: move.start, end: move.end, promoteTo: move.promotedPiece?.kind)
                }
            } else {
                await MainActor.run {
                    makeRandomEngineMove()
                }
            }
        } else {
            await MainActor.run {
                makeRandomEngineMove()
            }
        }
        
        // Check engine move results
        if case .checkmate = viewModel.board.state {
            // Handled by the game-over UI
        } else if checkDrawOrKingsOnly() {
            await MainActor.run {
                viewModel.gameOver = true
            }
        } else {
            // Evaluate FEN after engine's move to update the mate display
            let fenAfterEngine = viewModel.board.position.fen
            let postEngineResult = await analyzer.evaluate(fen: fenAfterEngine, depth: 12, limitSkill: false, movetime: 300)

            let newSideToMove = Position(fen: fenAfterEngine)?.sideToMove ?? .white
            let mateWhitePOV = postEngineResult?.mate.map { newSideToMove == .white ? $0 : -$0 }
            
            let m: Int? = {
                guard let mw = mateWhitePOV else { return nil }
                if scenario.initialMoveColor == .white && mw > 0 { return mw }
                if scenario.initialMoveColor == .black && mw < 0 { return abs(mw) }
                return nil
            }()
            
            if let validM = m {
                await MainActor.run {
                    self.currentMateDistance = validM
                    updateMateInMoves(validM)
                }
            } else {
                await MainActor.run {
                    mateInMoves = "10+"
                }
            }
        }
        
        await MainActor.run { isProcessing = false }
    }
    
    private func makeRandomEngineMove() {
        var allMoves: [(Square, Square)] = []
        for sq in Square.allCases {
            if let piece = viewModel.board.position.piece(at: sq), piece.color == .black {
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
    
    private func requestHint() {
        guard !isProcessing && !viewModel.gameOver else { return }
        
        if hintBestMoveArrow != nil {
            hintBestMoveArrow = nil
            return
        }
        
        isCalculatingHint = true
        Task {
            let fen = viewModel.board.position.fen
            // Deeper, uncapped search: the 300ms cap previously returned drawing/suboptimal
            // moves on device for precise endgames. These positions have a tiny branching
            // factor, so a fixed depth resolves quickly and yields the correct winning move.
            let evalResult = await analyzer.evaluate(fen: fen, depth: 20, limitSkill: false)
            await MainActor.run {
                isCalculatingHint = false
                if let result = evalResult {
                    if let move = EngineLANParser.parse(move: result.bestMove, for: viewModel.board.position.sideToMove, in: viewModel.board.position) {
                        hintBestMoveArrow = (start: move.start, end: move.end)
                    }
                }
            }
        }
    }
}

// Helper to blur background
struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}
