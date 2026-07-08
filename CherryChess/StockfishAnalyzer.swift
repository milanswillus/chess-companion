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
    
    init() {
        debugStatus = "Engine wird erstellt..."
        engine = Engine(type: .stockfish, loggingEnabled: false)
        
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
                let respStr = "\(response)"
                if respStr.contains("ERROR") || respStr.contains("terminated") {
                    self.engineReady = false
                    self.debugStatus = "Engine-Fehler!"
                }
                
                switch response {
                case .readyok:
                    self.debugStatus = "Engine bereit!"
                    self.engineReady = true
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
    private var lastEvaluation: Task<(bestMove: String, score: Int, mate: Int?), Never>?

    private func handleBestMove(_ moveString: String) {
        let completion = pendingMoveCompletion
        pendingMoveCompletion = nil
        completion?(moveString)
    }
    
    // MARK: - Engine Evaluation
    
    func evaluate(fen: String, depth: Int = 10, limitSkill: Bool = false, movetime: Int? = nil) async -> (bestMove: String, score: Int, mate: Int?)? {
        guard let engine = engine, engineReady else { return nil }

        // Serialize engine access: each evaluation waits for the previous one to finish.
        let previous = lastEvaluation
        let evaluation = Task { () -> (bestMove: String, score: Int, mate: Int?) in
            _ = await previous?.value
            return await self.runSearch(fen: fen, depth: depth, limitSkill: limitSkill, movetime: movetime, engine: engine)
        }
        lastEvaluation = evaluation
        return await evaluation.value
    }

    private func runSearch(fen: String, depth: Int, limitSkill: Bool, movetime: Int?, engine: Engine) async -> (bestMove: String, score: Int, mate: Int?) {
        return await withCheckedContinuation { continuation in
            var timeoutTask: Task<Void, Never>?

            self.pendingMoveCompletion = { [weak self] moveStr in
                timeoutTask?.cancel()
                let score = self?.latestScore ?? 0
                let mate = self?.latestMate
                continuation.resume(returning: (bestMove: moveStr ?? "", score: score, mate: mate))
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
        // Resolve any in-flight search so the evaluation chain never wedges.
        let completion = pendingMoveCompletion
        pendingMoveCompletion = nil
        completion?(nil)
        latestScore = nil
        latestMate = nil
    }
    
    private func winProbability(centipawns: Int) -> Double {
        let x = -0.00368208 * Double(centipawns)
        return 50.0 + 50.0 * (2.0 / (1.0 + exp(x)) - 1.0)
    }

    private func pieceValue(_ kind: Piece.Kind) -> Int {
        // The king is effectively priceless for sacrifice/en-prise detection.
        kind == .king ? 1000 : PieceValues.material(of: kind)
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

        // All evaluations are from the moving side's point of view (higher = better
        // for the mover), in centipawns, with mate encoded as ±10000.

        // 1. Win-probability drop. Clamp generously so extreme values (especially
        // the mate sentinel) don't dominate, while still leaving a small gradient
        // inside clearly-winning territory.
        let clampLimit = 1200
        let clampedBefore = max(-clampLimit, min(clampLimit, evalBefore))
        let clampedAfter = max(-clampLimit, min(clampLimit, evalAfter))

        let wBefore = winProbability(centipawns: clampedBefore)
        let wAfter = winProbability(centipawns: clampedAfter)
        var drop = wBefore - wAfter          // positive => the position got worse
        let swing = wAfter - wBefore         // positive => the position improved

        // 2. Raw centipawn loss. Near equality a small win-probability change can
        // still hide a large material blunder, so we use raw loss as a floor —
        // but ONLY while the mover is not still clearly winning. Giving back part
        // of a winning advantage while remaining clearly winning is not a real
        // mistake and must not be flagged as one (this is what made evaluations
        // look "wrong" in heavily winning positions).
        let rawLoss = evalBefore - evalAfter
        let stillClearlyWinning = evalAfter >= 400

        if !stillClearlyWinning && rawLoss > 0 {
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

        // Miss: had a clear advantage and threw most of it away toward equality.
        if evalBefore >= 200 && evalAfter <= 75 && drop >= 10.0 {
            return .missed
        }

        // Brilliant and Great are reserved for moves that are essentially the
        // engine's top choice — never for mediocre moves that merely look flashy.
        let isTopMove = isBest || drop < 1.0

        // Brilliant: a genuine piece sacrifice (the moved piece itself is left
        // hanging) that keeps the game at least equal, played in a position that
        // is not already completely winning. We deliberately no longer treat
        // "leaves some piece attackable" as a sacrifice — that produced quiet,
        // unintuitive brilliants.
        if isTopMove,
           let m = move, let bBefore = boardBefore, let bAfter = boardAfter,
           isSacrifice(move: m, boardBefore: bBefore, boardAfter: bAfter),
           evalAfter >= -100,      // not losing after the sacrifice
           evalBefore < 500 {      // not already crushing beforehand
            return .brilliant
        }

        // Great: a decisive turning point that was also the best move. We require
        // a LARGE win-probability swing so ordinary strong moves never qualify.
        if isTopMove {
            // Recovered a clearly worse/losing position back to at least equal.
            if evalBefore <= -200 && evalAfter >= -50 && swing >= 12.0 {
                return .great
            }
            // Converted a balanced position into a clearly winning one.
            if evalBefore <= 60 && evalAfter >= 350 && swing >= 15.0 {
                return .great
            }
        }

        if isBest {
            return .best
        }
        // Standard classifications based on expected win-probability loss.
        if drop < 2.0 {
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
