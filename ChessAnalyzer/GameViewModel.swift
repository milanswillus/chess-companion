import Foundation
import Combine
import ChessKit
import UIKit

enum PlayerColor: String, CaseIterable {
    case white = "Weiß"
    case black = "Schwarz"
    case random = "Zufall"
}

struct HistoryNode {
    let board: Board
    let lastMove: Move?
    let fenBefore: String?
    let bestMoveStr: String?
    let classification: MoveClassification?
    let movingColor: Piece.Color?
    let evalScore: Int?
    let mate: Int?
    let liveElo: Int
}

struct Premove: Equatable {
    let start: Square
    let end: Square
    var promotesTo: Piece.Kind? = nil
}

class GameViewModel: ObservableObject {
    @Published var board: Board
    @Published var lastMove: Move?
    @Published var selectedSquare: Square?
    @Published var moveClassifications: [Move: MoveClassification] = [:]
    @Published var lastPlayerMoveFenBefore: String? = nil
    @Published var isProcessing: Bool = false
    
    // Player color
    @Published var playerColor: Piece.Color = .white
    @Published var playerColorChoice: PlayerColor = .white
    
    // Game state
    @Published var gameOver: Bool = false
    @Published var gameResult: String = ""
    @Published var showPromotionPicker: Bool = false
    @Published var pendingPromotionMove: Move? = nil
    @Published var isAnalysisMode: Bool = false
    
    // Friend Mode and custom rules
    @Published var isFriendMode: Bool = false
    @Published var flipBoardAfterMoves: Bool = true
    @Published var allowHints: Bool = true
    @Published var showBestMovesRetrospectively: Bool = false
    
    // History Explorer
    @Published var history: [HistoryNode] = []
    @Published var historyIndex: Int = 0
    @Published var inOpening: Bool = true
    
    // Premove, Best Move and Hints
    @Published var premoves: [Premove] = []
    @Published var virtualBoard: Board = Board()
    @Published var showPremovePromotionPicker: Bool = false
    var pendingPremove: Premove? = nil
    var lastBestMoveStr: String? = nil
    @Published var hintStep: Int = 0
    @Published var hintCorrectSquare: Square? = nil
    @Published var hintAlternativeSquare: Square? = nil
    
    // Time controls (in seconds)
    @Published var isTimed: Bool = false
    @Published var timeControlSeconds: Int = 600
    @Published var incrementSeconds: Int = 0
    
    @Published var whiteTimeRemaining: Int = 600
    @Published var blackTimeRemaining: Int = 600
    
    private var timer: Timer?
    
    @Published var showTimeExpiredAlert: Bool = false
    @Published var expiredPlayerColor: Piece.Color? = nil
    
    var isPlayerTurn: Bool {
        if isAnalysisMode || isFriendMode {
            return !gameOver
        }
        return !gameOver && board.position.sideToMove == playerColor
    }
    
    var isEngineTurn: Bool {
        if isAnalysisMode || isFriendMode {
            return false
        }
        return !gameOver && board.position.sideToMove != playerColor
    }
    
    var engineColor: Piece.Color {
        playerColor == .white ? .black : .white
    }
    
    /// Whether the board should be flipped (player's pieces at the bottom)
    var boardFlipped: Bool {
        if isFriendMode {
            if flipBoardAfterMoves {
                let activeBoard = displayBoard
                return activeBoard.position.sideToMove == .black
            } else {
                return playerColor == .black
            }
        }
        return playerColor == .black
    }
    
    // Display properties for history explorer
    var isExploringHistory: Bool {
        !history.isEmpty && historyIndex < history.count - 1
    }
    
    var displayBoard: Board {
        if isExploringHistory {
            return history[historyIndex].board
        }
        if !premoves.isEmpty && !isAnalysisMode {
            return virtualBoard
        }
        return board
    }
    
    private func movePieceInFEN(_ fen: String, start: Square, end: Square, promotesTo: Piece.Kind? = nil) -> String? {
        let components = fen.components(separatedBy: " ")
        guard components.count >= 1 else { return nil }
        
        let placement = components[0]
        let ranks = placement.components(separatedBy: "/")
        guard ranks.count == 8 else { return nil }
        
        var grid = Array(repeating: Array(repeating: Character(" "), count: 8), count: 8)
        
        for r in 0..<8 {
            let rankStr = ranks[r]
            var col = 0
            for char in rankStr {
                if let val = Int(String(char)) {
                    col += val
                } else {
                    if col < 8 {
                        grid[r][col] = char
                        col += 1
                    }
                }
            }
        }
        
        let startCol = start.file.number - 1
        let startRow = 8 - start.rank.value
        
        let endCol = end.file.number - 1
        let endRow = 8 - end.rank.value
        
        guard startCol >= 0 && startCol < 8 && startRow >= 0 && startRow < 8,
              endCol >= 0 && endCol < 8 && endRow >= 0 && endRow < 8 else {
            return nil
        }
        
        var movingPieceChar = grid[startRow][startCol]
        if movingPieceChar == " " {
            return nil
        }
        
        // Handle castling rook move in FEN preview
        if (movingPieceChar == "K" || movingPieceChar == "k") && startCol == 4 {
            if startRow == 7 { // White king
                if endCol == 6 { // g1
                    grid[7][7] = " "
                    grid[7][5] = "R"
                } else if endCol == 2 { // c1
                    grid[7][0] = " "
                    grid[7][3] = "R"
                }
            } else if startRow == 0 { // Black king
                if endCol == 6 { // g8
                    grid[0][7] = " "
                    grid[0][5] = "r"
                } else if endCol == 2 { // c8
                    grid[0][0] = " "
                    grid[0][3] = "r"
                }
            }
        }
        
        // Handle promotion in FEN preview
        if let promoKind = promotesTo {
            let isWhite = movingPieceChar.isUppercase
            let kindChar: Character
            switch promoKind {
            case .queen: kindChar = "q"
            case .rook: kindChar = "r"
            case .bishop: kindChar = "b"
            case .knight: kindChar = "n"
            case .pawn: kindChar = "p"
            case .king: kindChar = "k"
            }
            movingPieceChar = isWhite ? Character(kindChar.uppercased()) : kindChar
        }
        
        grid[startRow][startCol] = " "
        grid[endRow][endCol] = movingPieceChar
        
        var newRanks: [String] = []
        for r in 0..<8 {
            var rankStr = ""
            var emptyCount = 0
            for c in 0..<8 {
                let char = grid[r][c]
                if char == " " {
                    emptyCount += 1
                } else {
                    if emptyCount > 0 {
                        rankStr += String(emptyCount)
                        emptyCount = 0
                    }
                    rankStr += String(char)
                }
            }
            if emptyCount > 0 {
                rankStr += String(emptyCount)
            }
            newRanks.append(rankStr)
        }
        
        let newPlacement = newRanks.joined(separator: "/")
        var newComponents = components
        newComponents[0] = newPlacement
        return newComponents.joined(separator: " ")
    }
    
    private func updateVirtualBoard() {
        if isAnalysisMode {
            self.virtualBoard = board
            return
        }
        var currentFen = board.position.fen
        
        for pm in premoves {
            if let tempPos = Position(fen: currentFen),
               let piece = tempPos.piece(at: pm.start) {
                let isPawnPromotion = piece.kind == .pawn && 
                    ((piece.color == .white && pm.end.rank.value == 8) || 
                     (piece.color == .black && pm.end.rank.value == 1))
                
                let actualPromo = isPawnPromotion ? (pm.promotesTo ?? .queen) : nil
                
                if let newFen = movePieceInFEN(currentFen, start: pm.start, end: pm.end, promotesTo: actualPromo) {
                    currentFen = newFen
                }
            }
        }
        
        if let finalPosition = Position(fen: currentFen) {
            self.virtualBoard = Board(position: finalPosition)
        } else {
            self.virtualBoard = board
        }
    }
    
    func isConceptuallyPossible(pieceKind: Piece.Kind, start: Square, end: Square, color: Piece.Color) -> Bool {
        if start == end { return false }
        
        let df = end.file.number - start.file.number
        let dr = end.rank.value - start.rank.value
        let abs_df = abs(df)
        let abs_dr = abs(dr)
        
        switch pieceKind {
        case .pawn:
            if color == .white {
                return (df == 0 && (dr == 1 || (dr == 2 && start.rank.value == 2))) ||
                       (abs_df == 1 && dr == 1)
            } else {
                return (df == 0 && (dr == -1 || (dr == -2 && start.rank.value == 7))) ||
                       (abs_df == 1 && dr == -1)
            }
        case .knight:
            return (abs_df == 1 && abs_dr == 2) || (abs_df == 2 && abs_dr == 1)
        case .bishop:
            return abs_df == abs_dr && abs_df > 0
        case .rook:
            return (abs_df > 0 && abs_dr == 0) || (abs_dr > 0 && abs_df == 0)
        case .queen:
            return (abs_df == abs_dr && abs_df > 0) || (abs_df > 0 && abs_dr == 0) || (abs_dr > 0 && abs_df == 0)
        case .king:
            return (abs_df <= 1 && abs_dr <= 1) || 
                   (abs_df == 2 && dr == 0 && (start.file == .e && (start.rank.value == 1 || start.rank.value == 8)))
        }
    }
    
    func completePremovePromotion(to kind: Piece.Kind) {
        guard var pm = pendingPremove else { return }
        pm.promotesTo = kind
        premoves.append(pm)
        pendingPremove = nil
        showPremovePromotionPicker = false
        updateVirtualBoard()
        HapticManager.shared.playImpact(.medium)
    }
    
    var displayLastMove: Move? {
        isExploringHistory ? history[historyIndex].lastMove : lastMove
    }
    
    var displayEvalScore: Int? {
        if isExploringHistory {
            return history[historyIndex].evalScore
        }
        return history.last?.evalScore
    }
    
    var displayLiveElo: Int {
        if isExploringHistory {
            return history[historyIndex].liveElo
        }
        return history.last?.liveElo ?? 1200
    }
    
    init() {
        self.board = Board()
    }
    
    func startGame(from fen: String, playerColor: Piece.Color, timed: Bool, durationSeconds: Int, incrementSeconds: Int = 0) {
        self.playerColorChoice = playerColor == .white ? .white : .black
        self.playerColor = playerColor
        
        if let position = Position(fen: fen) {
            self.board = Board(position: position)
        } else {
            self.board = Board()
        }
        
        self.lastMove = nil
        self.moveClassifications.removeAll()
        self.selectedSquare = nil
        self.gameOver = false
        self.hintStep = 0
        self.hintCorrectSquare = nil
        self.hintAlternativeSquare = nil
        self.gameResult = ""
        self.showPromotionPicker = false
        self.pendingPromotionMove = nil
        self.lastPlayerMoveFenBefore = nil
        self.premoves.removeAll()
        self.showTimeExpiredAlert = false
        self.expiredPlayerColor = nil
        self.lastBestMoveStr = nil
        self.history.removeAll()
        self.historyIndex = 0
        self.inOpening = false
        self.isTimed = timed
        self.timeControlSeconds = durationSeconds
        self.incrementSeconds = incrementSeconds
        
        self.whiteTimeRemaining = durationSeconds
        self.blackTimeRemaining = durationSeconds
        
        if isTimed {
            startTimer()
        }
        
        updateVirtualBoard()
        pushHistory(classification: nil, bestMoveStr: nil, movingColor: nil, evalScore: nil, mate: nil, evalDrop: nil)
    }
    
    func startGame(timed: Bool, durationSeconds: Int, incrementSeconds: Int = 0) {
        // Determine player color
        switch playerColorChoice {
        case .white: playerColor = .white
        case .black: playerColor = .black
        case .random: playerColor = Bool.random() ? .white : .black
        }
        
        self.board = Board()
        self.lastMove = nil
        self.moveClassifications.removeAll()
        self.selectedSquare = nil
        self.gameOver = false
        self.hintStep = 0
        self.hintCorrectSquare = nil
        self.hintAlternativeSquare = nil
        self.gameResult = ""
        self.showPromotionPicker = false
        self.pendingPromotionMove = nil
        self.lastPlayerMoveFenBefore = nil
        self.premoves.removeAll()
        self.showTimeExpiredAlert = false
        self.expiredPlayerColor = nil
        self.lastBestMoveStr = nil
        self.history.removeAll()
        self.historyIndex = 0
        self.inOpening = true
        self.isTimed = timed
        self.timeControlSeconds = durationSeconds
        self.incrementSeconds = incrementSeconds
        
        self.whiteTimeRemaining = durationSeconds
        self.blackTimeRemaining = durationSeconds
        
        if isTimed {
            startTimer()
        }
        
        updateVirtualBoard()
        // Push initial state
        pushHistory(classification: nil, bestMoveStr: nil, movingColor: nil, evalScore: nil, mate: nil, evalDrop: nil)
    }
    
    func pushHistory(classification: MoveClassification?, bestMoveStr: String?, movingColor: Piece.Color?, evalScore: Int?, mate: Int?, evalDrop: Int?) {
        var currentElo = history.last?.liveElo ?? 1200
        
        if movingColor == playerColor, let drop = evalDrop {
            if drop <= 0 {
                // Best move or better than expected (depth anomalies)
                currentElo += 15
            } else if drop < 30 {
                // Excellent / Good
                currentElo += 5
            } else {
                // Inaccuracy, Mistake, Blunder
                // e.g., a drop of 600 centipawns (6 pawns) translates to -900 Elo
                let eloLoss = Int(Double(drop) * 1.5)
                currentElo -= eloLoss
            }
            // Floor at a minimum Elo to prevent negative numbers
            currentElo = max(100, currentElo)
        }
        
        let node = HistoryNode(
            board: self.board,
            lastMove: self.lastMove,
            fenBefore: self.lastPlayerMoveFenBefore,
            bestMoveStr: bestMoveStr,
            classification: classification,
            movingColor: movingColor,
            evalScore: evalScore,
            mate: mate,
            liveElo: currentElo
        )
        self.history.append(node)
        self.historyIndex = self.history.count - 1
    }
    
    private func applyIncrement() {
        guard isTimed && incrementSeconds > 0 else { return }
        if board.position.sideToMove == .white {
            blackTimeRemaining += incrementSeconds
        } else {
            whiteTimeRemaining += incrementSeconds
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.gameOver else { return }
            if self.board.position.sideToMove == .white {
                if self.whiteTimeRemaining > 0 {
                    self.whiteTimeRemaining -= 1
                    if self.whiteTimeRemaining == 0 {
                        self.handleTimeExpired(for: .white)
                    }
                }
            } else {
                if self.blackTimeRemaining > 0 {
                    self.blackTimeRemaining -= 1
                    if self.blackTimeRemaining == 0 {
                        self.handleTimeExpired(for: .black)
                    }
                }
            }
        }
    }
    
    private func handleTimeExpired(for color: Piece.Color) {
        timer?.invalidate()
        
        let pieces = Square.allCases.compactMap { board.position.piece(at: $0) }
        let onlyKingsLeft = pieces.count == 2 && pieces.allSatisfy { $0.kind == .king }
        
        if onlyKingsLeft {
            self.gameOver = true
            self.gameResult = "Remis durch unzureichendes Material (Zeit abgelaufen)"
            HapticManager.shared.playNotification(.warning)
        } else {
            self.expiredPlayerColor = color
            self.gameOver = true
            let loser = color == .white ? "Weiß" : "Schwarz"
            self.gameResult = "\(loser) verliert durch Zeitüberschreitung"
            HapticManager.shared.playNotification(.warning)
        }
    }
    
    func claimTimeLoss() {
        self.gameOver = true
        let loser = expiredPlayerColor == .white ? "Weiß" : "Schwarz"
        self.gameResult = "\(loser) verliert durch Zeitüberschreitung"
        self.showTimeExpiredAlert = false
        
        let won = (expiredPlayerColor != playerColor)
        HapticManager.shared.playNotification(won ? .success : .error)
    }
    
    func continueWithoutTime() {
        self.isTimed = false
        self.showTimeExpiredAlert = false
        self.gameOver = false
        self.expiredPlayerColor = nil
        self.gameResult = ""
        timer?.invalidate()
    }
    
    func select(square: Square) {
        if isExploringHistory {
            if isAnalysisMode {
                // In analysis mode, we allow interacting with history board
                let activeBoard = displayBoard
                if let selected = selectedSquare {
                    if activeBoard.canMove(pieceAt: selected, to: square) {
                        // Truncate history at historyIndex to branch off
                        self.board = activeBoard
                        self.lastMove = history[historyIndex].lastMove
                        self.lastPlayerMoveFenBefore = history[historyIndex].fenBefore
                        self.history = Array(self.history.prefix(historyIndex + 1))
                        self.historyIndex = self.history.count - 1
                        
                        // Make the move on the updated board
                        makePlayerMove(start: selected, end: square)
                        selectedSquare = nil
                    } else {
                        if let piece = activeBoard.position.piece(at: square), piece.color == activeBoard.position.sideToMove {
                            selectedSquare = square
                            HapticManager.shared.playSelection()
                        } else {
                            selectedSquare = nil
                        }
                    }
                } else {
                    if let piece = activeBoard.position.piece(at: square), piece.color == activeBoard.position.sideToMove {
                        selectedSquare = square
                        HapticManager.shared.playSelection()
                    }
                }
            } else {
                return // Prevent interaction during history exploration
            }
            return
        }
        
        if isPlayerTurn && !isProcessing {
            // Normal move selection
            if let selected = selectedSquare {
                if board.canMove(pieceAt: selected, to: square) {
                    // Safety check: Never allow capturing the opponent's king
                    if let targetPiece = board.position.piece(at: square), targetPiece.kind == .king {
                        selectedSquare = nil
                        return
                    }
                    makePlayerMove(start: selected, end: square)
                    selectedSquare = nil
                } else {
                    if let piece = board.position.piece(at: square), piece.color == board.position.sideToMove {
                        selectedSquare = square
                        HapticManager.shared.playSelection()
                    } else {
                        selectedSquare = nil
                    }
                }
            } else {
                if let piece = board.position.piece(at: square), piece.color == board.position.sideToMove {
                    selectedSquare = square
                    HapticManager.shared.playSelection()
                }
            }
        } else if (isEngineTurn || isProcessing) && !isAnalysisMode && !isFriendMode {
            // Premove logic
            if let selected = selectedSquare {
                if let piece = virtualBoard.position.piece(at: selected),
                   isConceptuallyPossible(pieceKind: piece.kind, start: selected, end: square, color: piece.color) {
                    
                    let isPawnPromotion = piece.kind == .pawn && 
                        ((piece.color == .white && square.rank.value == 8) || 
                         (piece.color == .black && square.rank.value == 1))
                    
                    if isPawnPromotion {
                        let newPremove = Premove(start: selected, end: square, promotesTo: nil)
                        pendingPremove = newPremove
                        showPremovePromotionPicker = true
                        selectedSquare = nil
                    } else {
                        premoves.append(Premove(start: selected, end: square))
                        updateVirtualBoard()
                        HapticManager.shared.playImpact(.light)
                        selectedSquare = nil
                    }
                } else {
                    if let piece = virtualBoard.position.piece(at: square), piece.color == playerColor {
                        if selectedSquare == square {
                            // Tapped the already selected piece again -> cancel all premoves
                            selectedSquare = nil
                            premoves.removeAll()
                            updateVirtualBoard()
                            HapticManager.shared.playImpact(.medium)
                        } else {
                            selectedSquare = square
                            HapticManager.shared.playSelection()
                        }
                    } else {
                        selectedSquare = nil
                        premoves.removeAll() // Clear on invalid target tap
                        updateVirtualBoard()
                    }
                }
            } else {
                if let piece = virtualBoard.position.piece(at: square), piece.color == playerColor {
                    selectedSquare = square
                    HapticManager.shared.playSelection()
                } else {
                    premoves.removeAll() // Clear on empty space tap
                    updateVirtualBoard()
                }
            }
        }
    }
    
    /// Player move — posts notification so engine responds
    func makePlayerMove(start: Square, end: Square, isPremove: Bool = false, promoteTo: Piece.Kind? = nil) {
        guard !gameOver else { return }
        
        self.hintStep = 0
        self.hintCorrectSquare = nil
        self.hintAlternativeSquare = nil
        
        // Capture FEN before the move for analysis
        lastPlayerMoveFenBefore = board.position.fen
        
        if let move = board.move(pieceAt: start, to: end) {
            lastMove = move
            HapticManager.shared.playImpact(.light)
            
            // Check for promotion
            if case .promotion(let promoMove) = board.state {
                if isPremove {
                    let completedMove = board.completePromotion(of: promoMove, to: promoteTo ?? .queen)
                    lastMove = completedMove
                    HapticManager.shared.playImpact(.medium)
                } else {
                    pendingPromotionMove = promoMove
                    showPromotionPicker = true
                    updateVirtualBoard()
                    return // Don't post notification until promotion is complete
                }
            }
            
            applyIncrement()
            checkGameState()
            updateVirtualBoard()
            NotificationCenter.default.post(name: .didMakeMove, object: self, userInfo: ["move": lastMove ?? move])
        }
    }
    
    /// Complete pawn promotion
    func completePromotion(to kind: Piece.Kind) {
        self.hintStep = 0
        self.hintCorrectSquare = nil
        self.hintAlternativeSquare = nil
        guard let move = pendingPromotionMove else { return }
        let completedMove = board.completePromotion(of: move, to: kind)
        lastMove = completedMove
        showPromotionPicker = false
        pendingPromotionMove = nil
        
        HapticManager.shared.playImpact(.medium)
        
        applyIncrement()
        checkGameState()
        updateVirtualBoard()
        NotificationCenter.default.post(name: .didMakeMove, object: self, userInfo: ["move": completedMove])
    }
    
    /// Engine move — does NOT post notification (prevents infinite loop)
    func makeEngineMove(start: Square, end: Square, promoteTo: Piece.Kind? = nil) {
        guard !gameOver else { return }
        
        if let move = board.move(pieceAt: start, to: end) {
            lastMove = move
            HapticManager.shared.playImpact(.light)
            
            // Promote engine pawn to specified piece, or default to queen
            if case .promotion(let promoMove) = board.state {
                let completedMove = board.completePromotion(of: promoMove, to: promoteTo ?? .queen)
                lastMove = completedMove
            }
            
            applyIncrement()
            checkGameState()
            updateVirtualBoard()
        }
    }
    
    /// Calculate classification counts for a specific color up to an optional index limit
    func classificationCounts(for color: Piece.Color, upTo index: Int? = nil) -> [MoveClassification: Int] {
        var counts: [MoveClassification: Int] = [:]
        let limit = index ?? (history.count - 1)
        guard limit >= 0 && limit < history.count else { return counts }
        for i in 0...limit {
            let node = history[i]
            if node.movingColor == color, let c = node.classification, c != .none {
                counts[c, default: 0] += 1
            }
        }
        return counts
    }
    
    /// Calculate accuracy for a specific color up to an optional index limit
    func accuracy(for color: Piece.Color, upTo index: Int? = nil) -> Double {
        let counts = classificationCounts(for: color, upTo: index)
        var totalWeight = 0.0
        var totalMoves = 0.0
        
        for (classification, count) in counts {
            let weight: Double
            switch classification {
            case .brilliant: weight = 100.0
            case .great: weight = 100.0
            case .best: weight = 100.0
            case .forced: weight = 100.0
            case .book: weight = 100.0
            case .excellent: weight = 95.0
            case .good: weight = 80.0
            case .inaccuracy: weight = 50.0
            case .mistake: weight = 20.0
            case .missed: weight = 30.0
            case .blunder: weight = 0.0
            case .none: continue
            }
            totalWeight += weight * Double(count)
            totalMoves += Double(count)
        }
        
        if totalMoves == 0 {
            return 100.0
        }
        return totalWeight / totalMoves
    }
    
    /// Calculated accuracy for the player (0 to 100), history-aware when exploring history
    var playerAccuracy: Double {
        accuracy(for: playerColor, upTo: isExploringHistory ? historyIndex : (history.count - 1))
    }
    
    /// Returns captured pieces for each side based on the current board state.
    /// Piece values: Q=9, R=5, B=3, N=3, P=1
    func capturedPieces(for color: Piece.Color, on board: Board) -> [Piece.Kind] {
        let pieceValue: (Piece.Kind) -> Int = { kind in
            switch kind {
            case .queen: return 9
            case .rook: return 5
            case .bishop: return 3
            case .knight: return 3
            case .pawn: return 1
            case .king: return 0
            }
        }
        
        // Starting counts
        let startCounts: [Piece.Kind: Int] = [.queen: 1, .rook: 2, .bishop: 2, .knight: 2, .pawn: 8]
        
        // Current counts on board for opponent (pieces the opponent captured FROM this color)
        var currentCounts: [Piece.Kind: Int] = [.queen: 0, .rook: 0, .bishop: 0, .knight: 0, .pawn: 0]
        for sq in Square.allCases {
            if let piece = board.position.piece(at: sq), piece.color == color {
                if piece.kind != .king {
                    currentCounts[piece.kind, default: 0] += 1
                }
            }
        }
        
        // Captured = started with - still on board
        var captured: [Piece.Kind] = []
        for kind in [Piece.Kind.queen, .rook, .bishop, .knight, .pawn] {
            let lost = (startCounts[kind] ?? 0) - (currentCounts[kind] ?? 0)
            if lost > 0 {
                captured.append(contentsOf: Array(repeating: kind, count: lost))
            }
        }
        
        // Sort by value descending
        return captured.sorted { pieceValue($0) > pieceValue($1) }
    }
    
    /// Returns the net material advantage score for the given color.
    func materialScore(for color: Piece.Color, on board: Board) -> Int {
        let pieceValue: (Piece.Kind) -> Int = { kind in
            switch kind {
            case .queen: return 9; case .rook: return 5
            case .bishop: return 3; case .knight: return 3
            case .pawn: return 1; case .king: return 0
            }
        }
        var score = 0
        for sq in Square.allCases {
            if let piece = board.position.piece(at: sq) {
                let val = pieceValue(piece.kind)
                score += piece.color == color ? val : -val
            }
        }
        return score
    }
    
    @discardableResult
    func executePremoveIfValid() -> Bool {
        if isAnalysisMode { return false }
        guard !premoves.isEmpty else { return false }
        
        let nextPremove = premoves.removeFirst()
        let pStart = nextPremove.start
        let pEnd = nextPremove.end
        
        // Only execute if it's the player's turn and the move is valid in the current board
        if isPlayerTurn, board.canMove(pieceAt: pStart, to: pEnd) {
            makePlayerMove(start: pStart, end: pEnd, isPremove: true, promoteTo: nextPremove.promotesTo)
            return true
        } else {
            // If any premove in the chain fails, clear all subsequent premoves!
            premoves.removeAll()
            updateVirtualBoard()
            return false
        }
    }
    
    /// Check if the game is over (checkmate, draw, stalemate)
    private func checkGameState() {
        switch board.state {
        case .checkmate(let color):
            gameOver = true
            let winnerName = color == .white ? "Schwarz" : "Weiß"
            gameResult = "\(winnerName) gewinnt durch Schachmatt!"
            timer?.invalidate()
            
            let won = (color != playerColor)
            HapticManager.shared.playNotification(won ? .success : .error)
        case .draw(let reason):
            gameOver = true
            switch reason {
            case .stalemate: gameResult = "Remis durch Patt"
            case .fiftyMoves: gameResult = "Remis durch 50-Züge-Regel"
            case .repetition: gameResult = "Remis durch Zugwiederholung"
            case .insufficientMaterial: gameResult = "Remis durch unzureichendes Material"
            case .agreement: gameResult = "Remis durch Einigung"
            }
            timer?.invalidate()
            
            HapticManager.shared.playNotification(.warning)
        default:
            break
        }
    }
    
    func formatTime(_ timeInSeconds: Int) -> String {
        let minutes = timeInSeconds / 60
        let seconds = timeInSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

extension Notification.Name {
    static let didMakeMove = Notification.Name("didMakeMove")
    static let didAnalyzeMove = Notification.Name("didAnalyzeMove")
}
