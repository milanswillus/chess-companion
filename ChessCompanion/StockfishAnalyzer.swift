import Combine
import Foundation
import ChessKit
import ChessKitEngine

@MainActor
class StockfishAnalyzer: ObservableObject {
    private var engine: Engine?
    private var engineReady = false
    
    var isReady: Bool { engineReady }
    
    @Published var currentElo: Int = 3190
    @Published var debugStatus: String = "Engine nicht gestartet"
    
    // Track the latest centipawn score from engine info lines
    private var latestScore: Int? = nil
    private var latestMate: Int? = nil
    private static var hasRunDiagnostic = false
    
    init() {
        debugStatus = "Engine wird erstellt..."
        engine = Engine(type: .stockfish, loggingEnabled: true)
        
        Task {
            await startEngine()
        }
    }
    
    private func startEngine() async {
        guard let engine = engine else {
            debugStatus = "Engine ist nil"
            return
        }
        
        debugStatus = "Engine wird gestartet..."
        await engine.start()
        debugStatus = "Engine gestartet, wird konfiguriert..."
        
        // Explicitly set the NNUE paths to make absolutely sure they are loaded from the correct bundle location
        if let nnuePath = Bundle.main.path(forResource: "nn-1111cefa1111", ofType: "nnue") {
            await engine.send(command: .setoption(id: "EvalFile", value: nnuePath))
        }
        if let nnueSmallPath = Bundle.main.path(forResource: "nn-37f18f62d772", ofType: "nnue") {
            await engine.send(command: .setoption(id: "EvalFileSmall", value: nnueSmallPath))
        }
        
        Task {
            guard let stream = await engine.responseStream else {
                self.debugStatus = "Kein Antwort-Stream!"
                return
            }
            
            for await response in stream {
                // Log response to file
                let logMsg = "[\(Date())] Response: \(response)"
                let logPath = "/Users/milanswillus/dev/ChessAnalyzer/engine_log.txt"
                if let data = (logMsg + "\n").data(using: .utf8) {
                    if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                        _ = try? fileHandle.seekToEnd()
                        try? fileHandle.write(contentsOf: data)
                        try? fileHandle.close()
                    } else {
                        try? data.write(to: URL(fileURLWithPath: logPath))
                    }
                }
                
                let respStr = "\(response)"
                if respStr.contains("ERROR") || respStr.contains("terminated") {
                    self.engineReady = false
                    self.debugStatus = "Engine-Fehler!"
                }
                
                switch response {
                case .readyok:
                    self.debugStatus = "Engine bereit!"
                    self.engineReady = true
                    
                    if !Self.hasRunDiagnostic {
                        Self.hasRunDiagnostic = true
                        Task {
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                            let testFen1 = "8/8/8/8/8/3k4/8/1R2K3 w - - 0 1"
                            let result1 = await self.evaluate(fen: testFen1, depth: 25, limitSkill: false)
                            
                            let testFen2 = "3k4/6R1/3K4/8/8/8/8/8 w - - 0 1"
                            let result2 = await self.evaluate(fen: testFen2, depth: 25, limitSkill: false)
                            
                            let resultStr = "Diagnostic test:\nResult1: bestMove=\(result1?.bestMove ?? "nil"), mate=\(String(describing: result1?.mate))\nResult2: bestMove=\(result2?.bestMove ?? "nil"), mate=\(String(describing: result2?.mate))\n"
                            try? resultStr.write(toFile: "/Users/milanswillus/dev/ChessAnalyzer/test_result.txt", atomically: true, encoding: .utf8)
                        }
                    }
                case .info(let info):
                    // Only process principal variation (PV) lines to update evaluations
                    let isPV = info.multipv == 1 || (info.multipv == nil && info.pv != nil)
                    if isPV, let score = info.score {
                        if let cp = score.cp {
                            self.latestScore = Int(cp)
                            self.latestMate = nil
                        } else if let mate = score.mate {
                            // Convert mate score to large centipawn value
                            self.latestScore = mate > 0 ? 10000 : -10000
                            self.latestMate = Int(mate)
                        }
                    }
                case .bestmove(let move, _):
                    self.debugStatus = "Bester Zug empfangen: \(move)"
                    self.handleBestMove(move)
                default:
                    break
                }
            }
        }
        
        // Configure for analysis
        await applyEngineConfiguration(for: currentElo)
        debugStatus = "Engine konfiguriert (Elo: \(currentElo))"
    }
    
    // MARK: - Move Handling
    
    private var pendingMoveCompletion: ((String?) -> Void)?
    private var isEvaluating = false
    
    private func handleBestMove(_ moveString: String) {
        let completion = pendingMoveCompletion
        pendingMoveCompletion = nil
        completion?(moveString)
    }
    
    // MARK: - Engine Evaluation
    
    func evaluate(fen: String, depth: Int = 10, limitSkill: Bool = false, movetime: Int? = nil) async -> (bestMove: String, score: Int, mate: Int?)? {
        guard let engine = engine, engineReady else { return nil }
        
        while isEvaluating {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        isEvaluating = true
        
        return await withCheckedContinuation { continuation in
            var timeoutTask: Task<Void, Never>?
            
            self.pendingMoveCompletion = { [weak self] moveStr in
                timeoutTask?.cancel()
                let score = self?.latestScore ?? 0
                let mate = self?.latestMate
                continuation.resume(returning: (bestMove: moveStr ?? "", score: score, mate: mate))
                self?.isEvaluating = false
            }
            
            Task {
                self.latestScore = nil // Reset score before search
                self.latestMate = nil
                if limitSkill {
                    await self.applyEngineConfiguration(for: self.currentElo)
                } else {
                    await engine.send(command: .setoption(id: "UCI_LimitStrength", value: "false"))
                    await engine.send(command: .setoption(id: "Skill Level", value: "20"))
                }
                try? await Task.sleep(nanoseconds: 10_000_000)
                await engine.send(command: .position(.fen(fen)))
                try? await Task.sleep(nanoseconds: 10_000_000)
                await engine.send(command: .go(depth: depth, movetime: movetime))
            }
            
            timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                if !Task.isCancelled {
                    await engine.send(command: .stop)
                    
                    // Hard timeout fallback
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 more seconds
                    if !Task.isCancelled {
                        if let completion = self.pendingMoveCompletion {
                            self.pendingMoveCompletion = nil
                            completion(nil)
                        }
                    }
                }
            }
        }
    }
    
    func reset() {
        pendingMoveCompletion = nil
        isEvaluating = false
        latestScore = nil
        latestMate = nil
    }
    
    private func winProbability(centipawns: Int) -> Double {
        let x = -0.00368208 * Double(centipawns)
        return 50.0 + 50.0 * (2.0 / (1.0 + exp(x)) - 1.0)
    }

    private func pieceValue(_ kind: Piece.Kind) -> Int {
        switch kind {
        case .pawn: return 1
        case .knight: return 3
        case .bishop: return 3
        case .rook: return 5
        case .queen: return 9
        case .king: return 1000
        }
    }
    
    private func isSacrifice(move: Move, boardBefore: Board, boardAfter: Board) -> Bool {
        let activeColor = boardBefore.position.sideToMove
        let opponentColor = activeColor == .white ? Piece.Color.black : Piece.Color.white
        
        guard let movedPiece = boardBefore.position.piece(at: move.start),
              movedPiece.kind != .pawn && movedPiece.kind != .king else {
            return false
        }
        
        let movedPieceVal = pieceValue(movedPiece.kind)
        
        for oppSq in Square.allCases {
            guard let oppPiece = boardAfter.position.piece(at: oppSq),
                  oppPiece.color == opponentColor else { continue }
            
            if boardAfter.legalMoves(forPieceAt: oppSq).contains(move.end) {
                let oppPieceVal = pieceValue(oppPiece.kind)
                
                // Case A: Opponent piece is of lower value
                if oppPieceVal < movedPieceVal {
                    return true
                }
                
                // Case B: Opponent piece is of equal/higher value but unprotected
                var boardCaptured = boardAfter
                if boardCaptured.move(pieceAt: oppSq, to: move.end) != nil {
                    var canRecapture = false
                    for ourSq in Square.allCases {
                        if let ourPiece = boardCaptured.position.piece(at: ourSq),
                           ourPiece.color == activeColor {
                            if boardCaptured.legalMoves(forPieceAt: ourSq).contains(move.end) {
                                canRecapture = true
                                break
                            }
                        }
                    }
                    if !canRecapture {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    private func hasEnPrisePiece(board: Board, color: Piece.Color) -> Bool {
        let opponentColor = color == .white ? Piece.Color.black : Piece.Color.white
        
        for ourSq in Square.allCases {
            guard let ourPiece = board.position.piece(at: ourSq),
                  ourPiece.color == color,
                  ourPiece.kind != .pawn && ourPiece.kind != .king else { continue }
            
            let ourPieceVal = pieceValue(ourPiece.kind)
            
            for oppSq in Square.allCases {
                guard let oppPiece = board.position.piece(at: oppSq),
                      oppPiece.color == opponentColor else { continue }
                
                if board.legalMoves(forPieceAt: oppSq).contains(ourSq) {
                    let oppPieceVal = pieceValue(oppPiece.kind)
                    if oppPieceVal < ourPieceVal {
                        return true
                    }
                    
                    var boardCaptured = board
                    if boardCaptured.move(pieceAt: oppSq, to: ourSq) != nil {
                        var canRecapture = false
                        for recaptureSq in Square.allCases {
                            if let recPiece = boardCaptured.position.piece(at: recaptureSq),
                               recPiece.color == color {
                                if boardCaptured.legalMoves(forPieceAt: recaptureSq).contains(ourSq) {
                                    canRecapture = true
                                    break
                                }
                            }
                        }
                        if !canRecapture {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
    
    func classifyMove(
        evalBefore: Int, 
        evalAfter: Int, 
        isBook: Bool = false, 
        isBest: Bool = false,
        move: Move? = nil,
        boardBefore: Board? = nil,
        boardAfter: Board? = nil
    ) -> MoveClassification {
        if isBook { return .book }
        
        // 1. Calculate win probability drop using clamped evaluations
        // Clamping prevents saturation at extreme evaluations (+15 vs +10, etc.)
        let clampLimit = 600
        let clampedBefore = max(-clampLimit, min(clampLimit, evalBefore))
        let clampedAfter = max(-clampLimit, min(clampLimit, evalAfter))
        
        let wBefore = winProbability(centipawns: clampedBefore)
        let wAfter = winProbability(centipawns: clampedAfter)
        var drop = wBefore - wAfter
        
        // 2. Calculate raw centipawn loss
        let rawLoss = evalBefore - evalAfter
        
        // 3. Apply raw loss correction for lost positions or large material blunders
        let bothWinning = evalBefore >= 600 && evalAfter >= 600
        
        if !bothWinning && rawLoss > 0 {
            var virtualDrop = 0.0
            if rawLoss >= 300 {
                virtualDrop = 22.0 // Blunder threshold
            } else if rawLoss >= 150 {
                virtualDrop = 12.0 // Mistake threshold
            } else if rawLoss >= 80 {
                virtualDrop = 6.0  // Inaccuracy threshold
            }
            
            drop = max(drop, virtualDrop)
        }
        
        // 4. Downgrade severity if the resulting position is still clearly winning (e.g. evalAfter >= 400)
        if evalAfter >= 400 {
            if drop >= 20.0 {
                drop = 9.0 // Downgrade blunder to inaccuracy
            } else if drop >= 10.0 {
                drop = 4.0 // Downgrade mistake to good
            }
        }
        
        // 4b. Custom raw loss correction for extremely winning positions (both evaluations >= 600)
        // to prevent saturation at +9.0 where win probability drop would stay at 0.0.
        if bothWinning && rawLoss > 0 {
            var virtualDrop = 0.0
            if rawLoss >= 400 {
                virtualDrop = 15.0 // Mistake threshold
            } else if rawLoss >= 200 {
                virtualDrop = 7.5  // Inaccuracy threshold
            } else if rawLoss >= 120 {
                virtualDrop = 3.5  // Good threshold
            } else if rawLoss >= 50 {
                virtualDrop = 1.0  // Excellent threshold
            }
            drop = max(drop, virtualDrop)
        }
        
        // Miss: Missed opportunity to gain/maintain a winning position, resulting in an equal or worse outcome.
        if evalBefore >= 200 && evalAfter <= 100 && drop >= 10.0 {
            return .missed
        }
        
        // Sacrifice check for Brilliant Move
        let isSac = {
            if let m = move, let bBefore = boardBefore, let bAfter = boardAfter {
                let activeColor = bBefore.position.sideToMove
                return isSacrifice(move: m, boardBefore: bBefore, boardAfter: bAfter) ||
                       (!hasEnPrisePiece(board: bBefore, color: activeColor) && hasEnPrisePiece(board: bAfter, color: activeColor))
            }
            return false
        }()
        
        // Brilliant: sound sacrifice (isBest or drop < 0.5, is a sacrifice, position not already winning, position not losing)
        if isSac && (isBest || drop < 0.5) && evalBefore < 600 && evalAfter >= -150 {
            return .brilliant
        }
        
        // Great Move: critical equalizer, breakthrough, or depth anomaly
        let isGreat = {
            if isBest || drop < 0.5 {
                // Equalizer: losing -> equal
                if evalBefore <= -150 && evalAfter >= -100 {
                    return true
                }
                // Breakthrough: equal -> winning
                if evalBefore >= -100 && evalBefore <= 100 && evalAfter >= 200 {
                    return true
                }
                // Depth anomaly (engine initially underestimated)
                if drop <= -2.0 {
                    return true
                }
            }
            return false
        }()
        
        if isGreat {
            return .great
        }
        
        if isBest {
            return .best
        }
        
        // Standard classifications based on Expected % Loss in Win Probability
        if drop < 0.5 {
            return .excellent
        } else if drop < 2.0 {
            return .excellent
        } else if drop < 5.0 {
            return .good
        } else if drop < 10.0 {
            return .inaccuracy
        } else if drop < 20.0 {
            return .mistake
        } else {
            return .blunder
        }
    }

    
    private func applyEngineConfiguration(for elo: Int) async {
        guard let engine = engine else { return }
        if elo >= 3190 {
            await engine.send(command: .setoption(id: "UCI_LimitStrength", value: "false"))
            await engine.send(command: .setoption(id: "Skill Level", value: "20"))
        } else if elo >= 1320 {
            await engine.send(command: .setoption(id: "UCI_LimitStrength", value: "true"))
            await engine.send(command: .setoption(id: "UCI_Elo", value: "\(elo)"))
            await engine.send(command: .setoption(id: "Skill Level", value: "20"))
        } else {
            // Map Elo 100...1320 to Skill Level 0...20
            let skillLevel = max(0, min(20, Int((Double(elo - 100) / 1220.0) * 20.0)))
            await engine.send(command: .setoption(id: "UCI_LimitStrength", value: "true"))
            await engine.send(command: .setoption(id: "UCI_Elo", value: "1320"))
            await engine.send(command: .setoption(id: "Skill Level", value: "\(skillLevel)"))
        }
    }
    
    func updateElo(_ elo: Int) {
        currentElo = max(100, min(3190, elo)) // Stockfish Elo range starting at 100
        Task {
            await applyEngineConfiguration(for: currentElo)
        }
    }
    
    deinit {
        let engineRef = engine
        Task.detached {
            await engineRef?.stop()
        }
    }
}
