import SwiftUI
import ChessKit

struct TrainingSession: Identifiable {
    let id = UUID()
    let opening: Opening
    let color: Piece.Color
}

enum TrainingMode {
    case menu
    case openings
    case mates
    case coordinates
}

struct MateScenario: Identifiable {
    let id: String
    let nameGerman: String
    let nameEnglish: String
    let descriptionGerman: String
    let descriptionEnglish: String
    let fen: String
    let initialMoveColor: Piece.Color
}

let mateScenariosList = [
    MateScenario(
        id: "queen_mate",
        nameGerman: "Dame & König vs. König",
        nameEnglish: "Queen & King vs. King",
        descriptionGerman: "Lerne das elementare Mattsetzen mit Dame und König.",
        descriptionEnglish: "Learn the basic checkmate with a Queen and King.",
        fen: "8/8/8/8/8/3k4/8/Q3K3 w - - 0 1",
        initialMoveColor: .white
    ),
    MateScenario(
        id: "rook_mate",
        nameGerman: "Turm & König vs. König",
        nameEnglish: "Rook & King vs. King",
        descriptionGerman: "Lerne das elementare Mattsetzen mit Turm und König.",
        descriptionEnglish: "Learn the basic checkmate with a Rook and King.",
        fen: "8/8/8/8/8/3k4/8/1R2K3 w - - 0 1",
        initialMoveColor: .white
    ),
    MateScenario(
        id: "pawn_mate",
        nameGerman: "König & Bauer vs. König",
        nameEnglish: "King & Pawn vs. King",
        descriptionGerman: "Meistere die Opposition im Bauernendspiel.",
        descriptionEnglish: "Master the opposition in a pawn endgame.",
        fen: "8/8/8/4k3/8/3K4/4P3/8 w - - 0 1",
        initialMoveColor: .white
    ),
    MateScenario(
        id: "two_pawns_mate",
        nameGerman: "König & 2 Bauern vs. König",
        nameEnglish: "King & 2 Pawns vs. King",
        descriptionGerman: "Gewinne das Endspiel mit zwei verbundenen Freibauern.",
        descriptionEnglish: "Win the endgame with two connected passed pawns.",
        fen: "8/8/8/8/3k4/8/3PP3/3K4 w - - 0 1",
        initialMoveColor: .white
    )
]

struct OpeningTrainerView: View {
    var isActive: Bool = true
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("appTheme") private var appTheme = "standard"
    @State private var selectedOpeningForColorSelection: Opening? = nil
    @State private var activeSession: TrainingSession? = nil
    
    @State private var activeMode: TrainingMode = .menu
    @State private var activeMateScenario: MateScenario? = {
        if FileManager.default.fileExists(atPath: "/Users/milanswillus/dev/ChessAnalyzer/run_simulation.txt") {
            return mateScenariosList.first { $0.id == "rook_mate" }
        }
        return nil
    }()
    
    @State private var menuScrollOffset: CGFloat = 0
    @State private var openingsScrollOffset: CGFloat = 0
    @State private var matesScrollOffset: CGFloat = 0
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        let _ = appLanguage
        let _ = appTheme
        
        ZStack {
            Theme.background.ignoresSafeArea()
            
            if let session = activeSession {
                OpeningTrainingDetailView(session: session) {
                    activeSession = nil
                }
            } else if let scenario = activeMateScenario {
                MateTrainingDetailView(scenario: scenario) {
                    activeMateScenario = nil
                }
            } else {
                switch activeMode {
                case .menu:
                    menuView
                case .openings:
                    openingsGridView
                case .mates:
                    mateScenariosListView
                case .coordinates:
                    CoordinateLearningView {
                        activeMode = .menu
                    }
                }
            }
        }
        .coordinateSpace(name: "trainingContainer")
        .sheet(item: $selectedOpeningForColorSelection) { opening in
            ColorSelectionSheet(opening: opening) { color in
                selectedOpeningForColorSelection = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    activeSession = TrainingSession(opening: opening, color: color)
                }
            }
        }
    }
    
    var menuView: some View {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        return ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    if isActive {
                        ScrollOffsetDetector(coordinateSpace: "trainingContainer", tag: "trainingMenu")
                    }
                    
                    Spacer().frame(height: isIPad ? 224 : 216)
                    
                    VStack(spacing: 20) {
                        Button(action: {
                            activeMode = .openings
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Theme.accentColor.opacity(0.15))
                                        .frame(width: 56, height: 56)
                                    Image(systemName: "book.closed.fill")
                                        .font(.title2)
                                        .foregroundColor(Theme.accentColor)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(L10n.tr("openings_training"))
                                        .font(.roundedSystem(.title3, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(L10n.tr("openings_training_desc"))
                                        .font(.roundedSystem(.caption))
                                        .foregroundColor(Theme.textSecondary)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Theme.textSecondary.opacity(0.5))
                            }
                            .padding()
                            .background(Theme.panelBackground)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: {
                            activeMode = .mates
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Theme.accentColor.opacity(0.15))
                                        .frame(width: 56, height: 56)
                                    Image(systemName: "crown.fill")
                                        .font(.title2)
                                        .foregroundColor(Theme.accentColor)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(L10n.tr("mate_scenarios"))
                                        .font(.roundedSystem(.title3, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(L10n.tr("mate_training_desc"))
                                        .font(.roundedSystem(.caption))
                                        .foregroundColor(Theme.textSecondary)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Theme.textSecondary.opacity(0.5))
                            }
                            .padding()
                            .background(Theme.panelBackground)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: {
                            activeMode = .coordinates
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Theme.accentColor.opacity(0.15))
                                        .frame(width: 56, height: 56)
                                    Image(systemName: "target")
                                        .font(.title2)
                                        .foregroundColor(Theme.accentColor)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(L10n.tr("learn_coordinates"))
                                        .font(.roundedSystem(.title3, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(L10n.tr("coord_desc"))
                                        .font(.roundedSystem(.caption))
                                        .foregroundColor(Theme.textSecondary)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Theme.textSecondary.opacity(0.5))
                            }
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
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
            
            // Collapsible Header View at top
            VStack(spacing: 0) {
                Color.clear.frame(height: 0)
                CollapsibleHeaderView(
                    title: L10n.tr("training"),
                    subtitle: appLanguage == "de" ? "Wähle einen Modus, um deine Eröffnungen, Matt-Szenarien oder Feld-Visualisierung zu trainieren." : "Select a mode to train your openings, checkmate scenarios, or board visualization.",
                    iconName: "dumbbell.fill",
                    scrollOffset: menuScrollOffset
                )
            }
            .background(
                Theme.background
                    .opacity(menuScrollOffset < -5 ? 1.0 : 0.0)
                    .ignoresSafeArea(edges: .top)
            )
            .animation(.easeInOut(duration: 0.15), value: menuScrollOffset < -5)
        }
        .onPreferenceChange(TaggedScrollOffsetPreferenceKey.self) { values in
            if let val = values["trainingMenu"] {
                self.menuScrollOffset = val
            }
        }
    }
    
    var openingsGridView: some View {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        return ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    if isActive {
                        ScrollOffsetDetector(coordinateSpace: "trainingContainer", tag: "trainingOpenings")
                    }
                    
                    Spacer().frame(height: isIPad ? 224 : 216)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Opening.allOpenings) { opening in
                            OpeningCardView(opening: opening) {
                                selectedOpeningForColorSelection = opening
                            }
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
                    title: L10n.tr("openings"),
                    subtitle: L10n.tr("theory_text"),
                    iconName: "book.closed.fill",
                    scrollOffset: openingsScrollOffset,
                    backAction: {
                        activeMode = .menu
                    }
                )
            }
            .background(
                Theme.background
                    .opacity(openingsScrollOffset < -5 ? 1.0 : 0.0)
                    .ignoresSafeArea(edges: .top)
            )
            .animation(.easeInOut(duration: 0.15), value: openingsScrollOffset < -5)
        }
        .onPreferenceChange(TaggedScrollOffsetPreferenceKey.self) { values in
            if let val = values["trainingOpenings"] {
                self.openingsScrollOffset = val
            }
        }
    }
    
    var mateScenariosListView: some View {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        return ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    if isActive {
                        ScrollOffsetDetector(coordinateSpace: "trainingContainer", tag: "trainingMates")
                    }
                    
                    Spacer().frame(height: isIPad ? 224 : 216)
                    
                    VStack(spacing: 16) {
                        ForEach(mateScenariosList) { scenario in
                            Button(action: {
                                activeMateScenario = scenario
                            }) {
                                HStack(spacing: 16) {
                                    MateScenarioBoardRow(scenarioId: scenario.id)
                                        .frame(height: 36)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "play.fill")
                                        .font(.roundedSystem(.subheadline, weight: .bold))
                                        .foregroundColor(Theme.accentColor)
                                }
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
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
            
            // Collapsible Header View at top
            VStack(spacing: 0) {
                Color.clear.frame(height: 0)
                CollapsibleHeaderView(
                    title: L10n.tr("mate_scenarios"),
                    subtitle: appLanguage == "de" ? "Wähle ein Endspiel-Matt-Szenario aus und setze den maximalen Bot matt. Fehler führen zum sofortigen Abbruch!" : "Select an endgame checkmate scenario and mate the max strength bot. Mistakes lead to immediate termination!",
                    iconName: "crown.fill",
                    scrollOffset: matesScrollOffset,
                    backAction: {
                        activeMode = .menu
                    }
                )
            }
            .background(
                Theme.background
                    .opacity(matesScrollOffset < -5 ? 1.0 : 0.0)
                    .ignoresSafeArea(edges: .top)
            )
            .animation(.easeInOut(duration: 0.15), value: matesScrollOffset < -5)
        }
        .onPreferenceChange(TaggedScrollOffsetPreferenceKey.self) { values in
            if let val = values["trainingMates"] {
                self.matesScrollOffset = val
            }
        }
    }
}

// MARK: - Opening Card View
struct OpeningCardView: View {
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("appTheme") private var appTheme = "standard"
    let opening: Opening
    let action: () -> Void
    
    var body: some View {
        let _ = appLanguage
        let _ = appTheme
        Button(action: action) {
            GeometryReader { cardGeo in
                let cardSize = cardGeo.size.width
                let boardSize = cardSize * 0.50
                
                VStack(spacing: 0) {
                    // Mini Chess Board with position after 4 moves (8 plies)
                    MiniChessBoardView(board: previewBoard)
                        .frame(width: boardSize, height: boardSize)
                        .cornerRadius(6)
                        .shadow(color: Color.black.opacity(0.25), radius: 3)
                        .padding(.top, cardSize * 0.08)
                    
                    Spacer(minLength: 4)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(appLanguage == "de" ? opening.nameGerman : opening.name)
                            .font(.roundedSystem(size: cardSize * 0.08, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        // Show a quick preview of the first moves in a horizontal scroll view, very thin
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(Array(opening.moveNames.prefix(5).enumerated()), id: \.offset) { index, name in
                                    let isWhiteMove = index % 2 == 0
                                    let cleanName = isWhiteMove ? name : name.replacingOccurrences(of: #"^\d+\.\.\.\s*"#, with: "", options: .regularExpression)
                                    
                                    Text(cleanName)
                                        .font(.system(size: cardSize * 0.065, weight: .thin, design: .rounded))
                                        .foregroundColor(isWhiteMove ? Theme.accentColor : Theme.accentColor.opacity(0.55))
                                }
                            }
                            .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, cardSize * 0.08)
                    .padding(.bottom, cardSize * 0.08)
                }
                .frame(width: cardSize, height: cardSize)
            }
            .aspectRatio(1.0, contentMode: .fit) // Perfect square card
            .background(
                LinearGradient(
                    colors: [Theme.panelBackground, Theme.panelBackground.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var previewBoard: Board {
        var board = Board()
        let count = min(8, opening.moves.count)
        for i in 0..<count {
            let move = opening.moves[i]
            _ = board.move(pieceAt: Square(move.start), to: Square(move.end))
        }
        return board
    }
}

// MARK: - Mini Chess Board View for Opening Card Preview
struct MiniChessBoardView: View {
    let board: Board
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<8, id: \.self) { rankIndex in
                HStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { fileIndex in
                        let rank = 7 - rankIndex
                        let file = fileIndex
                        let square = Square("\(Square.File(file + 1).rawValue)\(rank + 1)")
                        let isLight = (file + rank) % 2 != 0
                        let piece = board.position.piece(at: square)
                        
                        ZStack {
                            Rectangle()
                                .fill(isLight ? Theme.lightSquare : Theme.darkSquare)
                            
                            if let piece = piece {
                                Image(piece.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .padding(0.8)
                            }
                        }
                    }
                }
            }
        }
        .border(Color.black.opacity(0.35), width: 0.5)
    }
}

// MARK: - Color Selection Sheet
struct ColorSelectionSheet: View {
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("appTheme") private var appTheme = "standard"
    let opening: Opening
    let onSelect: (Piece.Color) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        let _ = appLanguage
        let _ = appTheme
        ZStack {
            Theme.panelBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header indicator
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                VStack(spacing: 6) {
                    Text(L10n.tr("choose_color"))
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    
                    Text(appLanguage == "de" ? "Wähle deine Seite für das Training der Eröffnung:" : "Choose your side for training this opening:")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    Text(appLanguage == "de" ? opening.nameGerman : opening.name)
                        .font(.headline.bold())
                        .foregroundColor(Theme.highlightSquare)
                        .padding(.top, 2)
                }
                
                HStack(spacing: 24) {
                    // White Button
                    Button(action: { onSelect(.white) }) {
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .frame(width: 70, height: 70)
                                    .shadow(radius: 3)
                                
                                Image(systemName: "crown.fill")
                                    .font(.title)
                                    .foregroundColor(.black)
                            }
                            
                            Text(appLanguage == "de" ? "Weiß spielen" : "Play as White")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Black Button
                    Button(action: { onSelect(.black) }) {
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black)
                                    .frame(width: 70, height: 70)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                    )
                                    .shadow(radius: 3)
                                
                                Image(systemName: "crown.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                            
                            Text(appLanguage == "de" ? "Schwarz spielen" : "Play as Black")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                Spacer()
            }
        }
        .presentationDetents([.fraction(0.38)])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Detailed Training Game View
struct OpeningTrainingDetailView: View {
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("appTheme") private var appTheme = "standard"
    let session: TrainingSession
    let onBack: () -> Void
    
    @StateObject private var viewModel: OpeningTrainerViewModel
    @State private var showMoveList: Bool = true
    
    private func hintButtonText(for step: Int) -> String {
        switch step {
        case 1: return L10n.tr("hint_narrow")
        case 2: return L10n.tr("show_arrow")
        case 3: return L10n.tr("hint_hide")
        default: return L10n.tr("hint")
        }
    }
    
    init(session: TrainingSession, onBack: @escaping () -> Void) {
        self.session = session
        self.onBack = onBack
        self._viewModel = StateObject(wrappedValue: OpeningTrainerViewModel(opening: session.opening, playerColor: session.color))
    }
    
    var body: some View {
        let _ = appLanguage
        let _ = appTheme
        
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let isIPad = UIDevice.current.userInterfaceIdiom == .pad
            
            // Adjust board size so it fits along with the moves, toggles, and buttons without scrolling.
            let maxBoardSize = isIPad ? (screenHeight * 0.65) : (screenHeight * 0.52)
            let boardWidth = min(screenWidth - 32, maxBoardSize)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.roundedSystem(.headline))
                            Text(L10n.tr("openings"))
                                .font(.roundedSystem(.body, weight: .bold))
                        }
                        .foregroundColor(Theme.textMain)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(appLanguage == "de" ? session.opening.nameGerman : session.opening.name)
                            .font(.roundedSystem(.headline, weight: .bold))
                            .foregroundColor(.white)
                        Text(appLanguage == "de" ? "Training" : "Training")
                            .font(.roundedSystem(.caption))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .padding()
                .background(Theme.panelBackground)
                
                VStack(spacing: 12) {
                    // Status message / Error banner (hide standard "Your turn!" message)
                    if viewModel.errorMessage != nil || viewModel.isTrainingComplete {
                        ZStack {
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(Color.red.opacity(0.85))
                                    .cornerRadius(8)
                                    .transition(.scale.combined(with: .opacity))
                            } else if viewModel.isTrainingComplete {
                                HStack(spacing: 6) {
                                    Text(appLanguage == "de" ? "Glückwunsch! Eröffnung gemeistert!" : "Congratulations! Opening mastered!")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.black)
                                    Image(systemName: "star.fill")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.black)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Theme.accentColor)
                                .cornerRadius(8)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .frame(height: 36)
                        .padding(.top, 8)
                        .animation(.easeInOut(duration: 0.25), value: viewModel.errorMessage)
                    }
                    
                    // Board
                    OpeningChessBoardView(viewModel: viewModel)
                        .frame(width: boardWidth, height: boardWidth)
                        .padding(.top, 8)
                    
                    Spacer(minLength: 8)
                    
                    // Toggle to show/hide moves styled premium using ThemeToggleStyle
                    Toggle(isOn: $showMoveList.animation(.easeInOut(duration: 0.2))) {
                        HStack(spacing: 8) {
                            Image(systemName: showMoveList ? "eye.fill" : "eye.slash.fill")
                            Text(appLanguage == "de" ? "Züge anzeigen" : "Show Moves")
                        }
                    }
                    .toggleStyle(ThemeToggleStyle())
                    .padding(.horizontal)
                    
                    if showMoveList {
                        // Moves timeline
                        ScrollViewReader { proxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(0..<viewModel.opening.moveNames.count, id: \.self) { index in
                                        let name = viewModel.opening.moveNames[index]
                                        let isCurrent = viewModel.currentMoveIndex == index
                                        let isPlayed = viewModel.currentMoveIndex > index
                                        let isWhiteMove = index % 2 == 0
                                        let cleanName = isWhiteMove ? name : name.replacingOccurrences(of: #"^\d+\.\.\.\s*"#, with: "", options: .regularExpression)
                                        
                                        Text(cleanName)
                                            .font(.caption.monospaced().bold())
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(
                                                isCurrent ? Theme.highlightSquare :
                                                (isPlayed ? Color.green.opacity(0.25) : Color.white.opacity(0.08))
                                            )
                                            .foregroundColor(
                                                isCurrent ? .black :
                                                (isPlayed ? .white : .gray)
                                            )
                                            .cornerRadius(6)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(isCurrent ? Color.clear : (isPlayed ? Color.green.opacity(0.4) : Color.clear), lineWidth: 1)
                                            )
                                            .id(index)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .frame(height: 38)
                            .onChange(of: viewModel.currentMoveIndex) { oldValue, newIndex in
                                withAnimation {
                                    proxy.scrollTo(newIndex, anchor: .center)
                                }
                            }
                            .onAppear {
                                proxy.scrollTo(viewModel.currentMoveIndex, anchor: .center)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // Control Dashboard
                    HStack(spacing: 16) {
                        // Hint Button
                        Button(action: {
                            withAnimation {
                                viewModel.toggleHint()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: viewModel.hintStep > 0 ? "lightbulb.fill" : "lightbulb")
                                Text(hintButtonText(for: viewModel.hintStep))
                            }
                            .frame(maxWidth: .infinity)
                            .font(.roundedSystem(.subheadline, weight: .bold))
                            .foregroundColor(viewModel.hintStep > 0 ? .black : Theme.accentColor)
                            .padding(.vertical, 12)
                            .background(viewModel.hintStep > 0 ? Theme.accentColor : Theme.panelBackground)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Theme.accentColor.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .disabled(viewModel.isTrainingComplete || viewModel.isBotThinking)
                        
                        // Restart Button
                        Button(action: {
                            withAnimation {
                                viewModel.reset()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                Text(appLanguage == "de" ? "Neustart" : "Restart")
                            }
                            .frame(maxWidth: .infinity)
                            .font(.roundedSystem(.subheadline, weight: .bold))
                            .foregroundColor(.white)
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
                    
                    Spacer(minLength: 8)
                    
                    // Info Section
                    VStack(alignment: .leading, spacing: 6) {
                        Text(appLanguage == "de" ? "Info zur Eröffnung" : "About the Opening")
                            .font(.roundedSystem(.subheadline, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(session.opening.description)
                            .font(.roundedSystem(.caption))
                            .foregroundColor(Theme.textSecondary)
                            .lineSpacing(2)
                            .lineLimit(isIPad ? 5 : 3)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.panelBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
                .padding(.bottom, isIPad ? 24 : 16)
            }
        }
        .overlay {
            // Victory success screen overlay
            if viewModel.isTrainingComplete {
                ZStack {
                    Color.black.opacity(0.85)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(Theme.highlightSquare)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.black)
                        }
                        
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Text(appLanguage == "de" ? "Eröffnung gelernt!" : "Opening learned!")
                                    .font(.title.bold())
                                    .foregroundColor(.white)
                                Image(systemName: "trophy.fill")
                                    .font(.title)
                                    .foregroundColor(Theme.accentColor)
                            }
                            
                            Text(appLanguage == "de" ? "Du hast alle Züge für die \(session.opening.nameGerman) fehlerfrei gespielt." : "You played all moves for the \(session.opening.name) correctly.")
                                .font(.body)
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        VStack(spacing: 12) {
                            Button(L10n.tr("play_again")) {
                                withAnimation {
                                    viewModel.reset()
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 32)
                            .frame(maxWidth: .infinity)
                            .background(Theme.accentColor)
                            .cornerRadius(10)
                            
                            Button(appLanguage == "de" ? "Zurück zur Übersicht" : "Back to Overview") {
                                onBack()
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 32)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal, 40)
                    }
                    .padding(.vertical, 32)
                    .background(Theme.panelBackground)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .padding(24)
                }
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Custom Chess Board View for Openings
struct OpeningChessBoardView: View {
    @AppStorage("appTheme") private var appTheme = "standard"
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("screenShakeEnabled") private var screenShakeEnabled = false
    @State private var shakeOffsetX: CGFloat = 0
    @State private var shakeOffsetY: CGFloat = 0
    @ObservedObject var viewModel: OpeningTrainerViewModel
    
    var body: some View {
        let _ = appLanguage
        let _ = appTheme
        GeometryReader { geometry in
            let boardSize = geometry.size.width
            let squareSize = boardSize / 8
            let isFlipped = viewModel.playerColor == .black
            
            ZStack(alignment: .topLeading) {
                // Board Squares Grid
                VStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { rankIndex in
                        HStack(spacing: 0) {
                            ForEach(0..<8, id: \.self) { fileIndex in
                                // Flip coordinate space if player is playing as Black
                                let rank = isFlipped ? rankIndex : (7 - rankIndex)
                                let file = isFlipped ? (7 - fileIndex) : fileIndex
                                
                                let square = Square("\(Square.File(file + 1).rawValue)\(rank + 1)")
                                let isLight = (file + rank) % 2 != 0
                                
                                let isSelected = viewModel.selectedSquare == square
                                
                                // Last move highlight (highlight both start and end square of the most recent move)
                                let isLastMove = {
                                    if viewModel.currentMoveIndex > 0 && viewModel.currentMoveIndex <= viewModel.opening.moves.count {
                                        let prevMove = viewModel.opening.moves[viewModel.currentMoveIndex - 1]
                                        return prevMove.start == square.coordinateString || prevMove.end == square.coordinateString
                                    }
                                    return false
                                }()
                                
                                // Incorrect move highlight
                                let isIncorrect = viewModel.incorrectMove?.start == square || viewModel.incorrectMove?.end == square
                                
                                let isLegalMove = {
                                    if let selected = viewModel.selectedSquare {
                                        return viewModel.board.canMove(pieceAt: selected, to: square)
                                    }
                                    return false
                                }()
                                
                                let isHintHighlighted: Bool = {
                                    if viewModel.hintStep == 1 {
                                        return square == viewModel.hintCorrectSquare || square == viewModel.hintAlternativeSquare
                                    } else if viewModel.hintStep == 2 {
                                        return square == viewModel.hintCorrectSquare
                                    }
                                    return false
                                }()
                                
                                OpeningSquareView(
                                    square: square,
                                    piece: viewModel.board.position.piece(at: square),
                                    isLight: isLight,
                                    isSelected: isSelected,
                                    isLastMove: isLastMove,
                                    isIncorrect: isIncorrect,
                                    isLegalMove: isLegalMove,
                                    isHintHighlighted: isHintHighlighted,
                                    size: squareSize,
                                    fileIndex: fileIndex,
                                    rankIndex: rankIndex
                                )
                                .onTapGesture {
                                    viewModel.select(square: square)
                                }
                            }
                        }
                    }
                }
                
                // Draw hint arrow
                if viewModel.showHintArrow && viewModel.currentMoveIndex < viewModel.opening.moves.count {
                    let expectedMove = viewModel.opening.moves[viewModel.currentMoveIndex]
                    let startSquare = Square(expectedMove.start)
                    let endSquare = Square(expectedMove.end)
                    
                    OpeningArrowView(start: startSquare, end: endSquare, squareSize: squareSize, isFlipped: isFlipped)
                }
            }
            .border(Color.black, width: 2)
            .frame(width: boardSize, height: boardSize)
            .offset(x: shakeOffsetX, y: shakeOffsetY)
        }
        .aspectRatio(1, contentMode: .fit)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("didMakeMove"))) { notification in
            guard let sender = notification.object as? OpeningTrainerViewModel, sender === viewModel else { return }
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

// MARK: - Custom Square View for Openings
struct OpeningSquareView: View {
    @AppStorage("showBoardCoordinates") private var showBoardCoordinates = true
    @AppStorage("appTheme") private var appTheme = "standard"
    @AppStorage("appLanguage") private var appLanguage = "de"
    let square: Square
    let piece: Piece?
    let isLight: Bool
    let isSelected: Bool
    let isLastMove: Bool
    let isIncorrect: Bool
    let isLegalMove: Bool
    var isHintHighlighted: Bool = false
    let size: CGFloat
    let fileIndex: Int
    let rankIndex: Int
    
    var backgroundColor: Color {
        if isIncorrect {
            return Color.red.opacity(0.7)
        }
        if isSelected {
            return Theme.highlightSquare
        }
        if isHintHighlighted {
            return Color.blue.opacity(0.35)
        }
        if isLastMove {
            return Theme.lastMoveHighlight
        }
        return isLight ? Theme.lightSquare : Theme.darkSquare
    }
    
    var body: some View {
        let _ = appLanguage
        let _ = appTheme
        ZStack {
            Rectangle()
                .fill(backgroundColor)
                .frame(width: size, height: size)
            
            if showBoardCoordinates && fileIndex == 0 {
                Text(String(square.rank.value))
                    .font(.system(size: size * 0.18, weight: .bold))
                    .foregroundColor(isLight ? Theme.darkSquare : Theme.lightSquare)
                    .position(x: size * 0.15, y: size * 0.15)
            }
            
            if showBoardCoordinates && rankIndex == 7 {
                Text(square.file.rawValue)
                    .font(.system(size: size * 0.18, weight: .bold))
                    .foregroundColor(isLight ? Theme.darkSquare : Theme.lightSquare)
                    .position(x: size * 0.85, y: size * 0.85)
            }
            
            if let piece = piece {
                Image(piece.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.9, height: size * 0.9)
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
        }
    }
}

// MARK: - Custom Arrow View for Hints
struct OpeningArrowView: View {
    let start: Square
    let end: Square
    let squareSize: CGFloat
    let isFlipped: Bool
    
    var body: some View {
        // Calculate screen coordinates based on board flipping
        let startX = (isFlipped ? CGFloat(8 - start.file.number) : CGFloat(start.file.number - 1)) * squareSize + squareSize / 2
        let startY = (isFlipped ? CGFloat(start.rank.value - 1) : CGFloat(8 - start.rank.value)) * squareSize + squareSize / 2
        let endX = (isFlipped ? CGFloat(8 - end.file.number) : CGFloat(end.file.number - 1)) * squareSize + squareSize / 2
        let endY = (isFlipped ? CGFloat(end.rank.value - 1) : CGFloat(8 - end.rank.value)) * squareSize + squareSize / 2
        
        let isKnight: Bool = {
            let df = abs(end.file.number - start.file.number)
            let dr = abs(end.rank.value - start.rank.value)
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
        
        return ZStack {
            // Arrow shaft
            if isKnight {
                Path { path in
                    path.move(to: CGPoint(x: startX, y: startY))
                    path.addLine(to: CGPoint(x: midX, y: midY))
                    path.addLine(to: CGPoint(x: shaftEndX, y: shaftEndY))
                }
                .stroke(arrowColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            } else {
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
}

// MARK: - Extension on Square for Coordinate string
extension Square {
    var coordinateString: String {
        let files = ["a", "b", "c", "d", "e", "f", "g", "h"]
        let fileIndex = self.file.number - 1
        let rankValue = self.rank.value
        if fileIndex >= 0 && fileIndex < 8 {
            return "\(files[fileIndex])\(rankValue)"
        }
        return ""
    }
}

// MARK: - Mate Scenario Board Row (8 Horizontal Squares)
struct MateScenarioBoardRow: View {
    @AppStorage("appTheme") private var appTheme = "standard"
    let scenarioId: String
    
    var body: some View {
        let _ = appTheme // trigger re-render on theme change
        HStack(spacing: 0) {
            ForEach(0..<8) { col in
                let isLight = col % 2 == 0
                let pieceName = getPieceName(col: col)
                ZStack {
                    Rectangle()
                        .fill(isLight ? Theme.lightSquare : Theme.darkSquare)
                    
                    if let pieceName = pieceName {
                        Image(pieceName)
                            .resizable()
                            .scaledToFit()
                            .padding(4)
                    }
                }
                .aspectRatio(1.0, contentMode: .fit)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
    
    private func getPieceName(col: Int) -> String? {
        switch scenarioId {
        case "queen_mate":
            if col == 0 { return "wk" }
            if col == 1 { return "wq" }
            if col == 7 { return "bk" }
        case "rook_mate":
            if col == 0 { return "wk" }
            if col == 1 { return "wr" }
            if col == 7 { return "bk" }
        case "pawn_mate":
            if col == 0 { return "wk" }
            if col == 1 { return "wp" }
            if col == 7 { return "bk" }
        case "two_pawns_mate":
            if col == 0 { return "wk" }
            if col == 1 { return "wp" }
            if col == 2 { return "wp" }
            if col == 7 { return "bk" }
        default:
            break
        }
        return nil
    }
}

