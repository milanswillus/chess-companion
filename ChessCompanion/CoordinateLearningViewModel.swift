import SwiftUI
import ChessKit
import Combine

class CoordinateLearningViewModel: ObservableObject {
    enum GameState {
        case menu
        case playing
        case gameOver
    }
    
    enum GameMode {
        case rated
        case endless
    }
    
    // Game Setup
    @Published var gameState: GameState = .menu
    @Published var selectedMode: GameMode = .rated
    @Published var showLabels: Bool = true
    
    // Active Game Stats
    @Published var targetSquare: Square?
    @Published var correctCount: Int = 0
    @Published var incorrectCount: Int = 0
    @Published var currentElo: Int = 1000
    @Published var timeLeft: Int = 60
    
    // Realtime Feedback Flashes
    @Published var showGreenFlash: Bool = false
    @Published var showRedFlash: Bool = false
    @Published var lastTappedSquare: Square?
    
    // Endless mode metrics
    @Published var totalTimeSpent: Double = 0.0
    @Published var currentAverageTime: Double = 0.0
    
    // Game Over Results
    @Published var finalElo: Int = 1000
    @Published var finalScore: Int = 0
    @Published var isNewHighScore: Bool = false
    
    private var timer: Timer?
    private var gameStartTime: Date?
    private var lastSquareStartTime: Date = Date()
    private var scoresStore = CoordinateLearningStore.shared
    
    // Clean up timer
    deinit {
        timer?.invalidate()
    }
    
    func startGame(mode: GameMode) {
        selectedMode = mode
        correctCount = 0
        incorrectCount = 0
        currentElo = 1000
        timeLeft = 60
        totalTimeSpent = 0.0
        currentAverageTime = 0.0
        isNewHighScore = false
        showGreenFlash = false
        showRedFlash = false
        lastTappedSquare = nil
        
        generateRandomSquare()
        gameState = .playing
        gameStartTime = Date()
        lastSquareStartTime = Date()
        
        HapticManager.shared.playImpact(.medium)
        
        timer?.invalidate()
        if mode == .rated {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if self.timeLeft > 1 {
                        self.timeLeft -= 1
                    } else {
                        self.timeLeft = 0
                        self.endGame()
                    }
                }
            }
        } else {
            // Endless timer just to track overall elapsed time if needed
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    // Update average time in real-time even if they haven't clicked yet
                    if self.correctCount > 0, let start = self.gameStartTime {
                        let totalElapsed = Date().timeIntervalSince(start)
                        self.currentAverageTime = totalElapsed / Double(self.correctCount)
                    }
                }
            }
        }
    }
    
    func selectSquare(_ square: Square) {
        guard gameState == .playing, let target = targetSquare else { return }
        
        let now = Date()
        let timeTaken = now.timeIntervalSince(lastSquareStartTime)
        lastTappedSquare = square
        
        if square == target {
            // Correct tap
            correctCount += 1
            totalTimeSpent += timeTaken
            
            // Trigger green flash
            showGreenFlash = true
            showRedFlash = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.showGreenFlash = false
            }
            
            HapticManager.shared.playImpact(.light)
            
            if selectedMode == .rated {
                // ELO system: +20 base, plus speed bonus up to +15 if under 1.5 seconds
                let baseGain = 20
                let speedBonus = max(0, Int(15.0 * (1.5 - timeTaken) / 1.5))
                currentElo += (baseGain + speedBonus)
            } else {
                // Endless average calculation
                currentAverageTime = totalTimeSpent / Double(correctCount)
            }
            
            generateRandomSquare()
        } else {
            // Incorrect tap
            incorrectCount += 1
            
            // Trigger red flash
            showRedFlash = true
            showGreenFlash = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.showRedFlash = false
            }
            
            HapticManager.shared.playNotification(.error)
            
            if selectedMode == .rated {
                // ELO system: -30 penalty
                currentElo = max(100, currentElo - 30)
                generateRandomSquare()
            } else {
                // Endless: Game over on first mistake!
                endGame()
            }
        }
    }
    
    private func endGame() {
        timer?.invalidate()
        timer = nil
        gameState = .gameOver
        
        if selectedMode == .rated {
            finalElo = currentElo
            let previousHighScore = showLabels ? scoresStore.scores.ratedWithLabels : scoresStore.scores.ratedWithoutLabels
            isNewHighScore = finalElo > previousHighScore
            scoresStore.updateRatedScore(elo: finalElo, withLabels: showLabels)
        } else {
            // Endless score formula: correct * (10 / max(avgTime, 0.5)) * 100
            let avg = correctCount > 0 ? totalTimeSpent / Double(correctCount) : 0.0
            currentAverageTime = avg
            
            if correctCount == 0 {
                finalScore = 0
            } else {
                let speedFactor = 10.0 / max(avg, 0.5)
                finalScore = Int(Double(correctCount) * speedFactor * 100.0)
            }
            
            let previousHighScore = showLabels ? scoresStore.scores.endlessWithLabels : scoresStore.scores.endlessWithoutLabels
            isNewHighScore = finalScore > previousHighScore
            scoresStore.updateEndlessScore(score: finalScore, avgTime: avg, withLabels: showLabels)
        }
        
        HapticManager.shared.playNotification(isNewHighScore ? .success : .warning)
    }
    
    func reset() {
        timer?.invalidate()
        timer = nil
        gameState = .menu
        showGreenFlash = false
        showRedFlash = false
        lastTappedSquare = nil
    }
    
    private func generateRandomSquare() {
        let files = ["a", "b", "c", "d", "e", "f", "g", "h"]
        let ranks = ["1", "2", "3", "4", "5", "6", "7", "8"]
        var newSquare: Square
        repeat {
            let f = files.randomElement()!
            let r = ranks.randomElement()!
            newSquare = Square("\(f)\(r)")
        } while targetSquare == newSquare
        targetSquare = newSquare
        lastSquareStartTime = Date()
    }
}
