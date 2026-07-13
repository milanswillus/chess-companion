import SwiftUI
import Combine
import ChessKit

// MARK: - Saved Game Model

struct SavedGame: Identifiable, Codable {
    let id: UUID
    let date: Date
    let playerColor: String      // "white" or "black"
    let finalElo: Int
    let gameResult: String
    // Player's accuracy for this game (0...100)
    let accuracy: Double
    // Whether this was a Challenge (unsupported) game
    let isChallenge: Bool
    // Classification counts for the player
    let brilliant: Int
    let great: Int
    let best: Int
    let excellent: Int
    let good: Int
    let book: Int
    let inaccuracy: Int
    let mistake: Int
    let blunder: Int

    init(id: UUID = UUID(),
         date: Date = Date(),
         playerColor: String,
         finalElo: Int,
         gameResult: String,
         accuracy: Double = 0,
         isChallenge: Bool = false,
         counts: [MoveClassification: Int]) {
        self.id = id
        self.date = date
        self.playerColor = playerColor
        self.finalElo = finalElo
        self.gameResult = gameResult
        self.accuracy = accuracy
        self.isChallenge = isChallenge
        self.brilliant   = counts[.brilliant]   ?? 0
        self.great       = counts[.great]       ?? 0
        self.best        = counts[.best]        ?? 0
        self.excellent   = counts[.excellent]   ?? 0
        self.good        = counts[.good]        ?? 0
        self.book        = counts[.book]        ?? 0
        self.inaccuracy  = counts[.inaccuracy]  ?? 0
        self.mistake     = counts[.mistake]     ?? 0
        self.blunder     = counts[.blunder]     ?? 0
    }

    // Backward-compatible decoding: games saved before accuracy/isChallenge
    // existed default to accuracy 0 and normal (non-challenge).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(UUID.self, forKey: .id)
        date        = try c.decode(Date.self, forKey: .date)
        playerColor = try c.decode(String.self, forKey: .playerColor)
        finalElo    = try c.decode(Int.self, forKey: .finalElo)
        gameResult  = try c.decode(String.self, forKey: .gameResult)
        accuracy    = try c.decodeIfPresent(Double.self, forKey: .accuracy) ?? 0
        isChallenge = try c.decodeIfPresent(Bool.self, forKey: .isChallenge) ?? false
        brilliant   = try c.decodeIfPresent(Int.self, forKey: .brilliant)  ?? 0
        great       = try c.decodeIfPresent(Int.self, forKey: .great)      ?? 0
        best        = try c.decodeIfPresent(Int.self, forKey: .best)       ?? 0
        excellent   = try c.decodeIfPresent(Int.self, forKey: .excellent)  ?? 0
        good        = try c.decodeIfPresent(Int.self, forKey: .good)       ?? 0
        book        = try c.decodeIfPresent(Int.self, forKey: .book)       ?? 0
        inaccuracy  = try c.decodeIfPresent(Int.self, forKey: .inaccuracy) ?? 0
        mistake     = try c.decodeIfPresent(Int.self, forKey: .mistake)    ?? 0
        blunder     = try c.decodeIfPresent(Int.self, forKey: .blunder)    ?? 0
    }
    
    var countsDict: [MoveClassification: Int] {
        var d: [MoveClassification: Int] = [:]
        d[.brilliant]  = brilliant
        d[.great]      = great
        d[.best]       = best
        d[.excellent]  = excellent
        d[.good]       = good
        d[.book]       = book
        d[.inaccuracy] = inaccuracy
        d[.mistake]    = mistake
        d[.blunder]    = blunder
        return d
    }
}

// MARK: - Game History Store

class GameHistoryStore: ObservableObject {
    static let shared = GameHistoryStore()
    
    @Published var games: [SavedGame] = []
    
    private let storageKey = "saved_games_v1"
    
    init() { load() }
    
    func save(game: SavedGame) {
        games.insert(game, at: 0)
        persist()
    }
    
    func delete(at offsets: IndexSet) {
        games.remove(atOffsets: offsets)
        persist()
    }
    
    func delete(game: SavedGame) {
        if let index = games.firstIndex(where: { $0.id == game.id }) {
            games.remove(at: index)
            persist()
        }
    }
    
    func clearAll() {
        games.removeAll()
        persist()
    }

    // MARK: - Challenge stats (used by the Profile view)

    /// Challenge games ordered oldest -> newest (for time-series graphs).
    var challengeGamesChronological: [SavedGame] {
        games.filter { $0.isChallenge }.sorted { $0.date < $1.date }
    }

    /// Average performance rating across all challenge games.
    var averageChallengeRating: Int? {
        let g = games.filter { $0.isChallenge }
        guard !g.isEmpty else { return nil }
        return Int((g.map { Double($0.finalElo) }.reduce(0, +) / Double(g.count)).rounded())
    }

    /// Average accuracy across all challenge games (0...100).
    var averageChallengeAccuracy: Double? {
        let g = games.filter { $0.isChallenge }
        guard !g.isEmpty else { return nil }
        return g.map { $0.accuracy }.reduce(0, +) / Double(g.count)
    }
    
    private func persist() {
        if let data = try? JSONEncoder().encode(games) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([SavedGame].self, from: data) {
            games = decoded
        }
    }
}
