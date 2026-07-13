import Foundation
import SwiftUI
import Combine
import ChessKit

class OpeningTrainerViewModel: ObservableObject {
    @Published var board: Board
    @Published var selectedSquare: Square?
    @Published var currentMoveIndex: Int = 0
    @Published var isTrainingComplete: Bool = false
    @Published var incorrectMove: (start: Square, end: Square)? = nil
    @Published var errorMessage: String? = nil
    @Published var showHintArrow: Bool = false
    @Published var isBotThinking: Bool = false
    @Published var hintStep: Int = 0
    @Published var hintCorrectSquare: Square? = nil
    @Published var hintAlternativeSquare: Square? = nil
    
    let opening: Opening
    let playerColor: Piece.Color
    
    private var errorHighlightId = UUID()
    
    init(opening: Opening, playerColor: Piece.Color) {
        self.opening = opening
        self.playerColor = playerColor
        self.board = Board()
        
        // Start the game loop
        self.reset()
    }
    
    var isPlayerTurn: Bool {
        if isTrainingComplete || isBotThinking {
            return false
        }
        
        // White plays on even indices (0, 2, 4...)
        // Black plays on odd indices (1, 3, 5...)
        let isWhiteTurnInOpening = (currentMoveIndex % 2 == 0)
        if playerColor == .white {
            return isWhiteTurnInOpening
        } else {
            return !isWhiteTurnInOpening
        }
    }
    
    func reset() {
        self.board = Board()
        self.selectedSquare = nil
        self.currentMoveIndex = 0
        self.isTrainingComplete = false
        self.incorrectMove = nil
        self.errorMessage = nil
        self.showHintArrow = false
        self.isBotThinking = false
        self.hintStep = 0
        self.hintCorrectSquare = nil
        self.hintAlternativeSquare = nil
        
        // If player is Black, White (bot) makes the first move
        if playerColor == .black {
            playBotMoveWithDelay()
        }
    }
    
    func select(square: Square) {
        guard isPlayerTurn else { return }
        
        // Tap a piece of own color to select or change selection
        if let piece = board.position.piece(at: square), piece.color == playerColor {
            selectedSquare = square
            HapticManager.shared.playSelection()
            return
        }
        
        // If a piece is selected, validate moving to the tapped square
        if let selected = selectedSquare {
            // Clear selection
            selectedSquare = nil
            
            // Check if the move is legal under standard chess rules
            if board.canMove(pieceAt: selected, to: square) {
                let startStr = squareToString(selected)
                let endStr = squareToString(square)
                
                // Retrieve expected opening move
                guard currentMoveIndex < opening.moves.count else { return }
                let expectedMove = opening.moves[currentMoveIndex]
                
                if startStr == expectedMove.start && endStr == expectedMove.end {
                    // Correct Move!
                    if let _ = board.move(pieceAt: selected, to: square) {
                        currentMoveIndex += 1
                        incorrectMove = nil
                        errorMessage = nil
                        showHintArrow = false
                        hintStep = 0
                        hintCorrectSquare = nil
                        hintAlternativeSquare = nil
                        
                        NotificationCenter.default.post(name: Notification.Name("didMakeMove"), object: self)
                        
                        // Check if opening completed
                        if currentMoveIndex == opening.moves.count {
                            isTrainingComplete = true
                            HapticManager.shared.playNotification(.success)
                        } else {
                            HapticManager.shared.playImpact(.light)
                            // Let bot play after a short delay
                            playBotMoveWithDelay()
                        }
                    }
                } else {
                    // Incorrect move in the opening sequence!
                    incorrectMove = (selected, square)
                    errorMessage = "Falscher Zug! Das ist nicht der Zug der \(opening.nameGerman)."
                    showHintArrow = false
                    
                    // Trigger haptic feedback
                    HapticManager.shared.playNotification(.error)
                    
                    // Clear the red incorrect highlight after 1.5 seconds
                    let currentId = UUID()
                    self.errorHighlightId = currentId
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                        guard let self = self else { return }
                        if self.errorHighlightId == currentId {
                            self.incorrectMove = nil
                        }
                    }
                }
            }
        }
    }
    
    private func playBotMoveWithDelay() {
        guard currentMoveIndex < opening.moves.count else { return }
        
        isBotThinking = true
        let expectedMove = opening.moves[currentMoveIndex]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            guard let self = self else { return }
            self.isBotThinking = false
            
            // Ensure index hasn't reset or changed unexpectedly during delay
            guard self.currentMoveIndex < self.opening.moves.count else { return }
            let currentExpected = self.opening.moves[self.currentMoveIndex]
            guard currentExpected.start == expectedMove.start && currentExpected.end == expectedMove.end else { return }
            
            let startSquare = Square(expectedMove.start)
            let endSquare = Square(expectedMove.end)
            
            // Apply bot move
            if let _ = self.board.move(pieceAt: startSquare, to: endSquare) {
                // Auto-promote pawn for bot if it ever reaches promotion (rare in openings)
                if case .promotion(let promoMove) = self.board.state {
                    _ = self.board.completePromotion(of: promoMove, to: .queen)
                }
                
                self.currentMoveIndex += 1
                
                // Check if completed
                if self.currentMoveIndex == self.opening.moves.count {
                    self.isTrainingComplete = true
                    HapticManager.shared.playNotification(.success)
                } else {
                    HapticManager.shared.playImpact(.light)
                }
            }
        }
    }
    
    func toggleHint() {
        guard currentMoveIndex < opening.moves.count else { return }
        incorrectMove = nil
        
        if hintStep == 0 {
            // Step 1: Highlight 2 pieces (correct one and an alternative one)
            let expectedMove = opening.moves[currentMoveIndex]
            let correctSquare = Square(expectedMove.start)
            hintCorrectSquare = correctSquare
            hintAlternativeSquare = findPlausiblePawnOrPiece(correctSquare: correctSquare, board: board, playerColor: playerColor)
            hintStep = 1
            showHintArrow = false
        } else if hintStep == 1 {
            // Step 2: Highlight only correct piece
            hintStep = 2
            showHintArrow = false
        } else if hintStep == 2 {
            // Step 3: Draw the arrow
            hintStep = 3
            showHintArrow = true
        } else {
            // Cycle back to 0 (hidden)
            hintStep = 0
            showHintArrow = false
        }
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
    
    // Helper to stringify square for matching
    private func squareToString(_ square: Square) -> String {
        let files = ["a", "b", "c", "d", "e", "f", "g", "h"]
        let fileIndex = square.file.number - 1
        let rankValue = square.rank.value
        if fileIndex >= 0 && fileIndex < 8 {
            return "\(files[fileIndex])\(rankValue)"
        }
        return ""
    }
}
