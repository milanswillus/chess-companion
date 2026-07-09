import SwiftUI
import Combine

struct CoordinateHighScores: Codable {
    var ratedWithLabels: Int = 1000
    var ratedWithoutLabels: Int = 1000
    var endlessWithLabels: Int = 0
    var endlessWithoutLabels: Int = 0
    var endlessWithLabelsAvgTime: Double = 0.0
    var endlessWithoutLabelsAvgTime: Double = 0.0
}

class CoordinateLearningStore: ObservableObject {
    static let shared = CoordinateLearningStore()
    
    @Published var scores = CoordinateHighScores()
    
    private let storageKey = "coordinate_high_scores_v1"
    
    init() {
        load()
    }
    
    func updateRatedScore(elo: Int, withLabels: Bool) {
        if withLabels {
            if elo > scores.ratedWithLabels {
                scores.ratedWithLabels = elo
                persist()
            }
        } else {
            if elo > scores.ratedWithoutLabels {
                scores.ratedWithoutLabels = elo
                persist()
            }
        }
    }
    
    func updateEndlessScore(score: Int, avgTime: Double, withLabels: Bool) {
        if withLabels {
            if score > scores.endlessWithLabels {
                scores.endlessWithLabels = score
                scores.endlessWithLabelsAvgTime = avgTime
                persist()
            }
        } else {
            if score > scores.endlessWithoutLabels {
                scores.endlessWithoutLabels = score
                scores.endlessWithoutLabelsAvgTime = avgTime
                persist()
            }
        }
    }
    
    private func persist() {
        if let data = try? JSONEncoder().encode(scores) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(CoordinateHighScores.self, from: data) {
            scores = decoded
        }
    }
}
