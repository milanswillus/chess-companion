import SwiftUI
import ChessKit

struct ChessBoardView: View {
    @AppStorage("appTheme") private var appTheme = "standard"
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("screenShakeEnabled") private var screenShakeEnabled = false
    @State private var shakeOffsetX: CGFloat = 0
    @State private var shakeOffsetY: CGFloat = 0
    @ObservedObject var viewModel: GameViewModel
    var bestMoveArrow: (start: Square, end: Square)? = nil
    var showAnalysis: Bool = false
    var showClassificationBadge: Bool = false
    var displayClassification: MoveClassification? = nil
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 8)
    
    var body: some View {
        let _ = appLanguage
        let _ = appTheme
        GeometryReader { geometry in
            let boardSize = geometry.size.width - 4
            let squareSize = boardSize / 8
            
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<8, id: \.self) { col in
                                let rank = viewModel.boardFlipped ? row : 7 - row
                                let file = viewModel.boardFlipped ? 7 - col : col
                                
                                let square = Square("\(Square.File(file + 1).rawValue)\(rank + 1)")
                                let isLight = (file + rank) % 2 != 0
                                let isPremove = !viewModel.isExploringHistory && viewModel.premoves.contains { $0.start == square || $0.end == square }
                                
                                let isLegalMove = {
                                    if let selected = viewModel.selectedSquare {
                                        if viewModel.isAnalysisMode {
                                            return viewModel.displayBoard.canMove(pieceAt: selected, to: square)
                                        } else if !viewModel.isExploringHistory {
                                            if viewModel.isPlayerTurn && !viewModel.isProcessing {
                                                return viewModel.board.canMove(pieceAt: selected, to: square)
                                            } else {
                                                if let piece = viewModel.virtualBoard.position.piece(at: selected) {
                                                    return viewModel.isConceptuallyPossible(pieceKind: piece.kind, start: selected, end: square, color: piece.color)
                                                }
                                            }
                                        }
                                    }
                                    return false
                                }()
                                
                                let isHintHighlighted: Bool = {
                                    if !viewModel.isExploringHistory {
                                        if viewModel.hintStep == 1 {
                                            return square == viewModel.hintCorrectSquare || square == viewModel.hintAlternativeSquare
                                        } else if viewModel.hintStep == 2 {
                                            return square == viewModel.hintCorrectSquare
                                        }
                                    }
                                    return false
                                }()
                                
                                let isSquareCheckmatedKing: Bool = {
                                    if case .checkmate(let color) = viewModel.displayBoard.state {
                                        if let piece = viewModel.displayBoard.position.piece(at: square),
                                           piece.kind == .king && piece.color == color {
                                            return true
                                        }
                                    }
                                    return false
                                }()
                                
                                let isSquareDrawKing: Bool = {
                                    let isDrawState: Bool = {
                                        if case .draw = viewModel.displayBoard.state {
                                            return true
                                        }
                                        let pieces = Square.allCases.compactMap { viewModel.displayBoard.position.piece(at: $0) }
                                        if pieces.count == 2 {
                                            return !pieces.contains { $0.kind != .king }
                                        }
                                        return false
                                    }()
                                    
                                    if isDrawState {
                                        if let piece = viewModel.displayBoard.position.piece(at: square),
                                           piece.kind == .king {
                                            return true
                                        }
                                    }
                                    return false
                                }()
                                
                                let isSquareTimeExpiredKing: Bool = {
                                    if let expiredColor = viewModel.expiredPlayerColor {
                                        if let piece = viewModel.displayBoard.position.piece(at: square),
                                           piece.kind == .king && piece.color == expiredColor {
                                            return true
                                        }
                                    }
                                    return false
                                }()
                                
                                let isSquareLastMoveEnd = (viewModel.displayLastMove?.end == square)
                                let squareClassification: MoveClassification? = {
                                    if showAnalysis,
                                       isSquareLastMoveEnd,
                                       let classification = displayClassification,
                                       classification != .none {
                                        return classification
                                    }
                                    return nil
                                }()
                                let shouldShowClassification = showClassificationBadge || viewModel.isExploringHistory
                                
                                SquareView(
                                    square: square,
                                    piece: viewModel.displayBoard.position.piece(at: square),
                                    isLight: isLight,
                                    isSelected: (!viewModel.isExploringHistory || viewModel.isAnalysisMode) && viewModel.selectedSquare == square,
                                    isLastMove: viewModel.displayLastMove?.start == square || viewModel.displayLastMove?.end == square,
                                    isPremove: isPremove,
                                    isLegalMove: isLegalMove,
                                    isHintHighlighted: isHintHighlighted,
                                    isCheckmated: isSquareCheckmatedKing,
                                    isDraw: isSquareDrawKing,
                                    isTimeExpired: isSquareTimeExpiredKing,
                                    size: squareSize,
                                    fileIndex: col,
                                    rankIndex: row,
                                    classification: squareClassification,
                                    showClassification: shouldShowClassification,
                                    shouldMirrorBlackPieces: viewModel.isFriendMode && !viewModel.flipBoardAfterMoves
                                )
                                .onTapGesture {
                                    viewModel.select(square: square)
                                }
                                .zIndex((squareClassification != nil && shouldShowClassification) || isSquareCheckmatedKing || isSquareDrawKing || isSquareTimeExpiredKing ? 10 : 0)
                            }
                        }
                    }
                }
                
                if let arrow = bestMoveArrow {
                    let isFlipped = viewModel.boardFlipped
                    let startX = (isFlipped ? CGFloat(8 - arrow.start.file.number) : CGFloat(arrow.start.file.number - 1)) * squareSize + squareSize / 2
                    let startY = (isFlipped ? CGFloat(arrow.start.rank.value - 1) : CGFloat(8 - arrow.start.rank.value)) * squareSize + squareSize / 2
                    let endX = (isFlipped ? CGFloat(8 - arrow.end.file.number) : CGFloat(arrow.end.file.number - 1)) * squareSize + squareSize / 2
                    let endY = (isFlipped ? CGFloat(arrow.end.rank.value - 1) : CGFloat(8 - arrow.end.rank.value)) * squareSize + squareSize / 2
                    
                    let isKnight: Bool = {
                        let df = abs(arrow.end.file.number - arrow.start.file.number)
                        let dr = abs(arrow.end.rank.value - arrow.start.rank.value)
                        return (df == 1 && dr == 2) || (df == 2 && dr == 1)
                    }()
                    
                    let arrowColor = Color(red: 235/255, green: 150/255, blue: 30/255).opacity(0.85)
                    let lineWidth: CGFloat = squareSize * 0.18
                    let headSize: CGFloat = squareSize * 0.35
                    
                    let midX = endX
                    let midY = startY
                    
                    let arrowAngle: CGFloat = {
                        if isKnight {
                            return atan2(endY - midY, endX - midX)
                        } else {
                            return atan2(endY - startY, endX - startX)
                        }
                    }()
                    
                    let shaftEndX = endX - cos(arrowAngle) * headSize * 0.8
                    let shaftEndY = endY - sin(arrowAngle) * headSize * 0.8
                    
                    // Arrow shaft
                    if isKnight {
                        // L-shaped path: first move horizontally, then vertically
                        Path { path in
                            path.move(to: CGPoint(x: startX, y: startY))
                            path.addLine(to: CGPoint(x: midX, y: midY))
                            path.addLine(to: CGPoint(x: shaftEndX, y: shaftEndY))
                        }
                        .stroke(arrowColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    } else {
                        // Straight shaft stopping before arrowhead
                        Path { path in
                            path.move(to: CGPoint(x: startX, y: startY))
                            path.addLine(to: CGPoint(x: shaftEndX, y: shaftEndY))
                        }
                        .stroke(arrowColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    }
                    
                    // Triangular arrowhead
                    let tipX = endX
                    let tipY = endY
                    let baseAngle1 = arrowAngle + .pi * 0.75
                    let baseAngle2 = arrowAngle - .pi * 0.75
                    Path { path in
                        path.move(to: CGPoint(x: tipX, y: tipY))
                        path.addLine(to: CGPoint(x: tipX + cos(baseAngle1) * headSize, y: tipY + sin(baseAngle1) * headSize))
                        path.addLine(to: CGPoint(x: tipX + cos(baseAngle2) * headSize, y: tipY + sin(baseAngle2) * headSize))
                        path.closeSubpath()
                    }
                    .fill(arrowColor)
            }
        }
        .frame(width: boardSize, height: boardSize)
        .padding(2)
        .background(Color.black)
        .offset(x: shakeOffsetX, y: shakeOffsetY)
    }
    .aspectRatio(1, contentMode: .fit)
    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("didMakeMove"))) { notification in
        guard let sender = notification.object as? GameViewModel, sender === viewModel else { return }
        triggerShake()
    }
}

private func triggerShake() {
    guard screenShakeEnabled else { return }
    shakeOffsetX = -6
    shakeOffsetY = 4
    withAnimation(.spring(response: 0.22, dampingFraction: 0.25, blendDuration: 0)) {
        shakeOffsetX = 0
        shakeOffsetY = 0
    }
}
}

struct SquareView: View {
    @AppStorage("showBoardCoordinates") private var showBoardCoordinates = true
    @AppStorage("appTheme") private var appTheme = "standard"
    @AppStorage("appLanguage") private var appLanguage = "de"
    let square: Square
    let piece: Piece?
    let isLight: Bool
    let isSelected: Bool
    let isLastMove: Bool
    let isPremove: Bool
    let isLegalMove: Bool
    var isHintHighlighted: Bool = false
    var isCheckmated: Bool = false
    var isDraw: Bool = false
    var isTimeExpired: Bool = false
    let size: CGFloat
    let fileIndex: Int
    let rankIndex: Int
    var classification: MoveClassification? = nil
    var showClassification: Bool = false
    var shouldMirrorBlackPieces: Bool = false
    
    var backgroundColor: Color {
        if isSelected {
            return Theme.highlightSquare
        }
        if isLastMove {
            return Theme.lastMoveHighlight
        }
        if isHintHighlighted {
            return Theme.hintColor
        }
        return isLight ? Theme.lightSquare : Theme.darkSquare
    }
    
    var body: some View {
        let _ = appLanguage
        let _ = appTheme
        let badgeSize = min(size * 0.53, 30)
        let badgeOffset = badgeSize * 0.15
        ZStack {
            Rectangle()
                .fill(backgroundColor)
                .frame(width: size, height: size)
            
            if isPremove {
                Rectangle()
                    .fill(Theme.premoveColor)
                    .frame(width: size, height: size)
            }
            
            if isHintHighlighted {
                Rectangle()
                    .stroke(Theme.hintColor.opacity(0.95), lineWidth: 3)
                    .frame(width: size - 3, height: size - 3)
            }
            
            if showBoardCoordinates && fileIndex == 0 {
                Text(String(square.rank.value))
                    .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                    .foregroundColor(isLight ? Theme.darkSquare : Theme.lightSquare)
                    .position(x: size * 0.15, y: size * 0.15)
            }
            
            if showBoardCoordinates && rankIndex == 7 {
                Text(square.file.rawValue)
                    .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                    .foregroundColor(isLight ? Theme.darkSquare : Theme.lightSquare)
                    .position(x: size * 0.85, y: size * 0.85)
            }
            
            if let piece = piece {
                Image(piece.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.9, height: size * 0.9)
                    .rotationEffect(
                        (shouldMirrorBlackPieces && piece.color == .black)
                        ? .degrees(180)
                        : .degrees(0)
                    )
            }
            
            if isLegalMove {
                if piece != nil {
                    Circle()
                        .stroke(Color.black.opacity(0.18), lineWidth: size * 0.08)
                        .frame(width: size * 0.85, height: size * 0.85)
                } else {
                    Circle()
                        .fill(Color.black.opacity(0.18))
                        .frame(width: size * 0.28, height: size * 0.28)
                }
            }
            
            if isCheckmated {
                CheckmateBadge(size: badgeSize)
                    .position(x: size - badgeOffset, y: badgeOffset)
            }
            
            if isDraw {
                DrawBadge(size: badgeSize)
                    .position(x: size - badgeOffset, y: badgeOffset)
            }
            
            if isTimeExpired {
                TimeUpBadge(size: badgeSize)
                    .position(x: size - badgeOffset, y: badgeOffset)
            }
            
            if showClassification, let classification = classification, classification != .none {
                MoveClassificationBadge(classification: classification, size: badgeSize)
                    .position(x: size - badgeOffset, y: badgeOffset)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showClassification)
            }
        }
    }
}

extension Piece {
    var imageName: String {
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
