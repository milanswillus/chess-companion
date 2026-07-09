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
         counts: [MoveClassification: Int]) {
        self.id = id
        self.date = date
        self.playerColor = playerColor
        self.finalElo = finalElo
        self.gameResult = gameResult
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
