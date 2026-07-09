import Foundation
import ChessKit

struct Opening: Identifiable, Hashable {
    let id: String
    let name: String
    let nameGerman: String
    let description: String
    let moves: [MovePair]
    let moveNames: [String]
    
    struct MovePair: Codable, Hashable {
        let start: String
        let end: String
    }
}

extension Opening {
    static let allOpenings: [Opening] = [
        Opening(
            id: "ruy_lopez",
            name: "Ruy Lopez",
            nameGerman: "Spanische Partie",
            description: "Eine der ältesten und am häufigsten gespielten Eröffnungen. Sie konzentriert sich auf die schnelle Entwicklung und den Druck auf den schwarzen e5-Bauern.",
            moves: [
                MovePair(start: "e2", end: "e4"),
                MovePair(start: "e7", end: "e5"),
                MovePair(start: "g1", end: "f3"),
                MovePair(start: "b8", end: "c6"),
                MovePair(start: "f1", end: "b5"),
                MovePair(start: "a7", end: "a6"),
                MovePair(start: "b5", end: "a4"),
                MovePair(start: "g8", end: "f6"),
                MovePair(start: "d2", end: "d3"),
                MovePair(start: "d7", end: "d6"),
                MovePair(start: "c2", end: "c3"),
                MovePair(start: "g7", end: "g6")
            ],
            moveNames: ["1. e4", "1... e5", "2. Nf3", "2... Nc6", "3. Bb5", "3... a6", "4. Ba4", "4... Nf6", "5. d3", "5... d6", "6. c3", "6... g6"]
        ),
        Opening(
            id: "italian_game",
            name: "Italian Game",
            nameGerman: "Italienische Partie",
            description: "Ein offener Klassiker, der auf eine schnelle Kontrolle des Zentrums und Angriffe auf das schwache f7-Feld abzielt.",
            moves: [
                MovePair(start: "e2", end: "e4"),
                MovePair(start: "e7", end: "e5"),
                MovePair(start: "g1", end: "f3"),
                MovePair(start: "b8", end: "c6"),
                MovePair(start: "f1", end: "c4"),
                MovePair(start: "f8", end: "c5"),
                MovePair(start: "c2", end: "c3"),
                MovePair(start: "g8", end: "f6"),
                MovePair(start: "d2", end: "d3"),
                MovePair(start: "d7", end: "d6"),
                MovePair(start: "a2", end: "a4"),
                MovePair(start: "a7", end: "a6")
            ],
            moveNames: ["1. e4", "1... e5", "2. Nf3", "2... Nc6", "3. Bc4", "3... Bc5", "4. c3", "4... Nf6", "5. d3", "5... d6", "6. a4", "6... a6"]
        ),
        Opening(
            id: "sicilian_defense",
            name: "Sicilian Defense",
            nameGerman: "Sizilianische Verteidigung",
            description: "Die beliebteste und aggressivste Antwort auf 1.e4. Schwarz kämpft asymmetrisch um das Zentrum.",
            moves: [
                MovePair(start: "e2", end: "e4"),
                MovePair(start: "c7", end: "c5"),
                MovePair(start: "g1", end: "f3"),
                MovePair(start: "d7", end: "d6"),
                MovePair(start: "d2", end: "d4"),
                MovePair(start: "c5", end: "d4"),
                MovePair(start: "f3", end: "d4"),
                MovePair(start: "g8", end: "f6"),
                MovePair(start: "b1", end: "c3"),
                MovePair(start: "a7", end: "a6"),
                MovePair(start: "c1", end: "g5"),
                MovePair(start: "e7", end: "e6"),
                MovePair(start: "f2", end: "f4"),
                MovePair(start: "f8", end: "e7"),
                MovePair(start: "d1", end: "f3"),
                MovePair(start: "d8", end: "c7")
            ],
            moveNames: ["1. e4", "1... c5", "2. Nf3", "2... d6", "3. d4", "3... cxd4", "4. Nxd4", "4... Nf6", "5. Nc3", "5... a6", "6. Bg5", "6... e6", "7. f4", "7... Be7", "8. Qf3", "8... Qc7"]
        ),
        Opening(
            id: "french_defense",
            name: "French Defense",
            nameGerman: "Französische Verteidigung",
            description: "Eine solide, halboffene Verteidigung. Schwarz baut eine starke Bauernkette e6-d5 auf, blockiert jedoch vorerst den weißfeldrigen Läufer.",
            moves: [
                MovePair(start: "e2", end: "e4"),
                MovePair(start: "e7", end: "e6"),
                MovePair(start: "d2", end: "d4"),
                MovePair(start: "d7", end: "d5"),
                MovePair(start: "b1", end: "c3"),
                MovePair(start: "g8", end: "f6"),
                MovePair(start: "c1", end: "g5"),
                MovePair(start: "f8", end: "e7"),
                MovePair(start: "e4", end: "e5"),
                MovePair(start: "f6", end: "d7"),
                MovePair(start: "g5", end: "e7"),
                MovePair(start: "d8", end: "e7")
            ],
            moveNames: ["1. e4", "1... e6", "2. d4", "2... d5", "3. Nc3", "3... Nf6", "4. Bg5", "4... Be7", "5. e5", "5... Nfd7", "6. Bxe7", "6... Qxe7"]
        ),
        Opening(
            id: "caro_kann",
            name: "Caro-Kann Defense",
            nameGerman: "Caro-Kann-Verteidigung",
            description: "Ähnlich solide wie die französische Verteidigung, aber Schwarz hält sich den Weg für den Damenläufer frei.",
            moves: [
                MovePair(start: "e2", end: "e4"),
                MovePair(start: "c7", end: "c6"),
                MovePair(start: "d2", end: "d4"),
                MovePair(start: "d7", end: "d5"),
                MovePair(start: "b1", end: "c3"),
                MovePair(start: "d5", end: "e4"),
                MovePair(start: "c3", end: "e4"),
                MovePair(start: "c8", end: "f5"),
                MovePair(start: "e4", end: "g3"),
                MovePair(start: "f5", end: "g6"),
                MovePair(start: "h2", end: "h4"),
                MovePair(start: "h7", end: "h6"),
                MovePair(start: "g1", end: "f3"),
                MovePair(start: "b8", end: "d7")
            ],
            moveNames: ["1. e4", "1... c6", "2. d4", "2... d5", "3. Nc3", "3... dxe4", "4. Nxe4", "4... Bf5", "5. Ng3", "5... Bg6", "6. h4", "6... h6", "7. Nf3", "7... Nd7"]
        ),
        Opening(
            id: "queens_gambit",
            name: "Queen's Gambit",
            nameGerman: "Damengambit",
            description: "Ein Klassiker nach 1.d4. Weiß opfert scheinbar einen Flügelbauern, um eine dominante Kontrolle im Zentrum zu erlangen.",
            moves: [
                MovePair(start: "d2", end: "d4"),
                MovePair(start: "d7", end: "d5"),
                MovePair(start: "c2", end: "c4"),
                MovePair(start: "e7", end: "e6"),
                MovePair(start: "b1", end: "c3"),
                MovePair(start: "g8", end: "f6"),
                MovePair(start: "c1", end: "g5"),
                MovePair(start: "f8", end: "e7"),
                MovePair(start: "e2", end: "e3"),
                MovePair(start: "b8", end: "d7"),
                MovePair(start: "g1", end: "f3"),
                MovePair(start: "c7", end: "c6")
            ],
            moveNames: ["1. d4", "1... d5", "2. c4", "2... e6", "3. Nc3", "3... Nf6", "4. Bg5", "4... Be7", "5. e3", "5... Nbd7", "6. Nf3", "6... c6"]
        ),
        Opening(
            id: "scandinavian_defense",
            name: "Scandinavian Defense",
            nameGerman: "Skandinavische Verteidigung",
            description: "Schwarz greift das weiße e4-Zentrum sofort an. Führt zu offenem Spiel, bei dem die schwarze Dame früh ins Spiel kommt.",
            moves: [
                MovePair(start: "e2", end: "e4"),
                MovePair(start: "d7", end: "d5"),
                MovePair(start: "e4", end: "d5"),
                MovePair(start: "d8", end: "d5"),
                MovePair(start: "b1", end: "c3"),
                MovePair(start: "d5", end: "a5"),
                MovePair(start: "d2", end: "d4"),
                MovePair(start: "g8", end: "f6"),
                MovePair(start: "g1", end: "f3"),
                MovePair(start: "c7", end: "c6"),
                MovePair(start: "f1", end: "c4"),
                MovePair(start: "c8", end: "f5")
            ],
            moveNames: ["1. e4", "1... d5", "2. exd5", "2... Qxd5", "3. Nc3", "3... Qa5", "4. d4", "4... Nf6", "5. Nf3", "5... c6", "6. Bc4", "6... Bf5"]
        ),
        Opening(
            id: "kings_indian",
            name: "King's Indian Defense",
            nameGerman: "Königsindische Verteidigung",
            description: "Eine dynamische, hypermoderne Eröffnung. Schwarz erlaubt Weiß das Zentrum zu besetzen, um es später zu kontern.",
            moves: [
                MovePair(start: "d2", end: "d4"),
                MovePair(start: "g8", end: "f6"),
                MovePair(start: "c2", end: "c4"),
                MovePair(start: "g7", end: "g6"),
                MovePair(start: "b1", end: "c3"),
                MovePair(start: "f8", end: "g7"),
                MovePair(start: "e2", end: "e4"),
                MovePair(start: "d7", end: "d6"),
                MovePair(start: "g1", end: "f3"),
                MovePair(start: "b8", end: "d7"),
                MovePair(start: "f1", end: "e2"),
                MovePair(start: "e7", end: "e5"),
                MovePair(start: "d4", end: "d5"),
                MovePair(start: "d7", end: "c5")
            ],
            moveNames: ["1. d4", "1... Nf6", "2. c4", "2... g6", "3. Nc3", "3... Bg7", "4. e4", "4... d6", "5. Nf3", "5... Nbd7", "6. Be2", "6... e5", "7. d5", "7... Nc5"]
        ),
        Opening(
            id: "petrov_defense",
            name: "Petrov's Defense",
            nameGerman: "Russische Verteidigung",
            description: "Schwarz greift sofort den weißen e4-Bauern an, was oft zu sehr symmetrischen, remislastigen Strukturen führt.",
            moves: [
                MovePair(start: "e2", end: "e4"),
                MovePair(start: "e7", end: "e5"),
                MovePair(start: "g1", end: "f3"),
                MovePair(start: "g8", end: "f6"),
                MovePair(start: "f3", end: "e5"),
                MovePair(start: "d7", end: "d6"),
                MovePair(start: "e5", end: "f3"),
                MovePair(start: "f6", end: "e4")
            ],
            moveNames: ["1. e4", "1... e5", "2. Nf3", "2... Nf6", "3. Nxe5", "3... d6", "4. Nf3", "4... Nxe4"]
        ),
        Opening(
            id: "scotch_game",
            name: "Scotch Game",
            nameGerman: "Schottische Partie",
            description: "Weiß öffnet das Zentrum sofort mit d4, was zu einem lebhaften Figurenspiel führt.",
            moves: [
                MovePair(start: "e2", end: "e4"),
                MovePair(start: "e7", end: "e5"),
                MovePair(start: "g1", end: "f3"),
                MovePair(start: "b8", end: "c6"),
                MovePair(start: "d2", end: "d4"),
                MovePair(start: "e5", end: "d4"),
                MovePair(start: "f3", end: "d4")
            ],
            moveNames: ["1. e4", "1... e5", "2. Nf3", "2... Nc6", "3. d4", "3... exd4", "4. Nxd4"]
        ),
        Opening(
            id: "four_knights",
            name: "Four Knights Game",
            nameGerman: "Vierspringerspiel",
            description: "Ein sehr solides und klassisches Spiel, bei dem alle vier Springer früh entwickelt werden.",
            moves: [
                MovePair(start: "e2", end: "e4"),
                MovePair(start: "e7", end: "e5"),
                MovePair(start: "g1", end: "f3"),
                MovePair(start: "b8", end: "c6"),
                MovePair(start: "b1", end: "c3"),
                MovePair(start: "g8", end: "f6"),
                MovePair(start: "f1", end: "b5"),
                MovePair(start: "f8", end: "b4")
            ],
            moveNames: ["1. e4", "1... e5", "2. Nf3", "2... Nc6", "3. Nc3", "3... Nf6", "4. Bb5", "4... Bb4"]
        ),
        Opening(
            id: "slav_defense",
            name: "Slav Defense",
            nameGerman: "Slawische Verteidigung",
            description: "Schwarz stützt das d5-Zentrum mit c6, um den weißfeldrigen Läufer aktiv entwickeln zu können.",
            moves: [
                MovePair(start: "d2", end: "d4"),
                MovePair(start: "d7", end: "d5"),
                MovePair(start: "c2", end: "c4"),
                MovePair(start: "c7", end: "c6"),
                MovePair(start: "g1", end: "f3"),
                MovePair(start: "g8", end: "f6"),
                MovePair(start: "b1", end: "c3"),
                MovePair(start: "e7", end: "e6")
            ],
            moveNames: ["1. d4", "1... d5", "2. c4", "2... c6", "3. Nf3", "3... Nf6", "4. Nc3", "4... e6"]
        ),
        Opening(
            id: "vienna_game",
            name: "Vienna Game",
            nameGerman: "Wiener Partie",
            description: "Ein offenes Spiel, bei dem Weiß den Damenritter vor dem Königsritter entwickelt, um f4 vorzubereiten.",
            moves: [
                MovePair(start: "e2", end: "e4"),
                MovePair(start: "e7", end: "e5"),
                MovePair(start: "b1", end: "c3"),
                MovePair(start: "g8", end: "f6"),
                MovePair(start: "f2", end: "f4")
            ],
            moveNames: ["1. e4", "1... e5", "2. Nc3", "2... Nf6", "3. f4"]
        ),
        Opening(
            id: "philidor_defense",
            name: "Philidor Defense",
            nameGerman: "Philidor-Verteidigung",
            description: "Eine solide, aber etwas passive Verteidigung für Schwarz, die das e5-Zentrum mit d6 stützt.",
            moves: [
                MovePair(start: "e2", end: "e4"),
                MovePair(start: "e7", end: "e5"),
                MovePair(start: "g1", end: "f3"),
                MovePair(start: "d7", end: "d6"),
                MovePair(start: "d2", end: "d4")
            ],
            moveNames: ["1. e4", "1... e5", "2. Nf3", "2... d6", "3. d4"]
        ),
        Opening(
            id: "pirc_defense",
            name: "Pirc Defense",
            nameGerman: "Pirc-Verteidigung",
            description: "Eine hypermoderne Verteidigung, bei der Schwarz Weiß das Zentrum überlässt und es später angreift.",
            moves: [
                MovePair(start: "e2", end: "e4"),
                MovePair(start: "d7", end: "d6"),
                MovePair(start: "d2", end: "d4"),
                MovePair(start: "g8", end: "f6"),
                MovePair(start: "b1", end: "c3"),
                MovePair(start: "g7", end: "g6")
            ],
            moveNames: ["1. e4", "1... d6", "2. d4", "2... Nf6", "3. Nc3", "3... g6"]
        ),
        Opening(
            id: "kings_gambit",
            name: "King's Gambit",
            nameGerman: "Königsgambit",
            description: "Eine romantische Eröffnung, bei der Weiß früh f4 spielt, um die e-Linie zu öffnen und das Zentrum zu erobern.",
            moves: [
                MovePair(start: "e2", end: "e4"),
                MovePair(start: "e7", end: "e5"),
                MovePair(start: "f2", end: "f4"),
                MovePair(start: "e5", end: "f4"),
                MovePair(start: "g1", end: "f3")
            ],
            moveNames: ["1. e4", "1... e5", "2. f4", "2... exf4", "3. Nf3"]
        ),
        Opening(
            id: "london_system",
            name: "London System",
            nameGerman: "Londoner System",
            description: "Ein sehr populärer und solider Aufbau für Weiß, der unabhängig von den Zügen des Gegners gespielt werden kann.",
            moves: [
                MovePair(start: "d2", end: "d4"),
                MovePair(start: "d7", end: "d5"),
                MovePair(start: "g1", end: "f3"),
                MovePair(start: "g8", end: "f6"),
                MovePair(start: "c1", end: "f4")
            ],
            moveNames: ["1. d4", "1... d5", "2. Nf3", "2... Nf6", "3. Bf4"]
        )
    ]
    
    // Set of reached position FENs for all openings to support transpositions robustly
    static let bookFENs: Set<String> = {
        var fens = Set<String>()
        // Always include the starting board position as a book position
        let startBoard = Board()
        fens.insert(simplifiedFEN(startBoard.position.fen))
        
        for opening in allOpenings {
            var board = Board()
            for movePair in opening.moves {
                let startSquare = Square(movePair.start)
                let endSquare = Square(movePair.end)
                _ = board.move(pieceAt: startSquare, to: endSquare)
                fens.insert(simplifiedFEN(board.position.fen))
            }
        }
        return fens
    }()
    
    // Map of reached simplified FENs to their corresponding Opening
    static let fenToOpeningMap: [String: Opening] = {
        var map = [String: Opening]()
        for opening in allOpenings {
            var board = Board()
            for movePair in opening.moves {
                let startSquare = Square(movePair.start)
                let endSquare = Square(movePair.end)
                _ = board.move(pieceAt: startSquare, to: endSquare)
                let simp = simplifiedFEN(board.position.fen)
                if let existing = map[simp] {
                    // Prefer the opening with the longer sequence (more specific)
                    if opening.moves.count > existing.moves.count {
                        map[simp] = opening
                    }
                } else {
                    map[simp] = opening
                }
            }
        }
        return map
    }()
    
    static func simplifiedFEN(_ fen: String) -> String {
        let parts = fen.split(separator: " ")
        if parts.count >= 4 {
            return parts[0...3].joined(separator: " ")
        }
        return fen
    }
}
