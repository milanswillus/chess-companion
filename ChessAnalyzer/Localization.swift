import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case de = "de"
    case en = "en"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .de: return "Deutsch"
        case .en: return "English"
        }
    }
}

struct L10n {
    static var currentLanguage: String {
        UserDefaults.standard.string(forKey: "appLanguage") ?? "de"
    }
    
    static func tr(_ key: String) -> String {
        let lang = currentLanguage
        if let dict = translations[key] {
            return dict[lang] ?? dict["de"] ?? key
        }
        return key
    }
    
    static func translateResult(_ result: String) -> String {
        let isDe = currentLanguage == "de"
        if isDe {
            return result
        }
        
        // Translate to English
        if result.contains("gewinnt durch Schachmatt") {
            let winner = result.contains("Weiß") ? "White" : "Black"
            return "\(winner) wins by checkmate!"
        }
        if result.contains("verliert durch Zeitüberschreitung") {
            let loser = result.contains("Weiß") ? "White" : "Black"
            return "\(loser) loses on time"
        }
        if result == "Remis durch Patt" || result == "Patt!" {
            return "Draw by stalemate"
        }
        if result == "Remis durch 50-Züge-Regel" {
            return "Draw by 50-move rule"
        }
        if result == "Remis durch Zugwiederholung" {
            return "Draw by repetition"
        }
        if result == "Remis durch unzureichendes Material" {
            return "Draw by insufficient material"
        }
        if result == "Remis durch Einigung" {
            return "Draw by agreement"
        }
        if result == "Remis durch unzureichendes Material (Zeit abgelaufen)" {
            return "Draw due to insufficient material (time expired)"
        }
        
        // Fallbacks for contains
        if result.contains("unzureichendem Material") {
            return "Draw due to insufficient material"
        }
        if result.contains("Zeit abgelaufen") {
            return "Time expired"
        }
        
        return result
    }
    
    private static let translations: [String: [String: String]] = [
        // Tabs
        "game": ["de": "Spiel", "en": "Game"],
        "history": ["de": "Verlauf", "en": "History"],
        "openings": ["de": "Eröffnungen", "en": "Openings"],
        "training": ["de": "Training", "en": "Training"],
        "analysis": ["de": "Analyse", "en": "Analysis"],
        "analysis_setup_title": ["de": "Brett-Analyse", "en": "Board Analysis"],
        "analysis_setup_subtitle": ["de": "Analysiere Stellungen und spiele Züge für beide Seiten.", "en": "Analyze positions and play moves for both sides."],
        "start_analysis": ["de": "Analyse starten", "en": "Start Analysis"],
        "learn_coordinates": ["de": "Felder lernen", "en": "Coordinate Trainer"],
        "settings": ["de": "Einstellungen", "en": "Settings"],
        
        // Settings Tab
        "language": ["de": "Sprache", "en": "Language"],
        "theme": ["de": "Design", "en": "Theme"],
        "standard": ["de": "Elysium", "en": "Elysium"],
        "dark_neon": ["de": "Nebula", "en": "Nebula"],
        "midnight_gold": ["de": "Eclipse", "en": "Eclipse"],
        "sweet_rose": ["de": "Sophie", "en": "Sophie"],
        "board_coordinates": ["de": "Feldbezeichnungen anzeigen", "en": "Show Board Coordinates"],
        "reset_history": ["de": "Verlauf zurücksetzen", "en": "Reset History"],
        "confirm_reset": ["de": "Möchtest du wirklich alle aufgezeichneten Spiele löschen?", "en": "Are you sure you want to delete all saved games?"],
        "delete": ["de": "Löschen", "en": "Delete"],
        "cancel": ["de": "Abbrechen", "en": "Cancel"],
        "theme_selection": ["de": "Design-Thema", "en": "Theme Selection"],
        "lang_selection": ["de": "Sprachauswahl", "en": "Language Selection"],
        "app_icon_selection": ["de": "App-Symbol", "en": "App Icon"],
        "danger_zone": ["de": "Gefahrenzone", "en": "Danger Zone"],
        "about_app": ["de": "Über die App", "en": "About the App"],
        "about_desc": ["de": "ChessAnalyzer v1.1.0\nEntwickelt für Schachtraining und Spielanalyse.", "en": "ChessAnalyzer v1.1.0\nDeveloped for chess training and game analysis."],
        
        // Game Setup Screen
        "singleplayer": ["de": "Einzelspiel", "en": "Singleplayer"],
        "setup_subtitle": ["de": "Konfiguriere dein Spiel gegen Stockfish und trainiere deine Taktik.", "en": "Configure your game against Stockfish and train your tactics."],
        "play_as": ["de": "Spielen als", "en": "Play as"],
        "white": ["de": "Weiß", "en": "White"],
        "black": ["de": "Schwarz", "en": "Black"],
        "random": ["de": "Zufall", "en": "Random"],
        "computer_strength": ["de": "Computer Spielstärke (Elo)", "en": "Computer Strength (Elo)"],
        "time_control": ["de": "Bedenkzeit", "en": "Time Control"],
        "activate_clock": ["de": "Schach-Uhr aktivieren", "en": "Enable Chess Clock"],
        "minutes": ["de": "Minuten", "en": "Minutes"],
        "start_game": ["de": "Spiel starten", "en": "Start Game"],
        "new_game": ["de": "Neues Spiel", "en": "New Game"],
        
        // Difficulty Levels
        "beginner": ["de": "Anfänger", "en": "Beginner"],
        "intermediate": ["de": "Fortgeschritten", "en": "Intermediate"],
        "advanced": ["de": "Clubspieler", "en": "Advanced"],
        "master": ["de": "Meister", "en": "Master"],
        "grandmaster": ["de": "Großmeister", "en": "Grandmaster"],
        
        // In-Game UI
        "best_move": ["de": "Bester Zug", "en": "Best Move"],
        "show_arrow": ["de": "Pfeil zeigen", "en": "Show Arrow"],
        "hint": ["de": "Tipp zeigen", "en": "Show Hint"],
        "hint_narrow": ["de": "Figur eingrenzen", "en": "Narrow Piece"],
        "hint_hide": ["de": "Tipp ausblenden", "en": "Hide Hint"],
        "live_strength": ["de": "Live-Spielstärke", "en": "Live Elo Rating"],
        "accuracy": ["de": "Genauigkeit", "en": "Accuracy"],
        "game_over": ["de": "Spiel vorbei", "en": "Game Over"],
        "mate_alert": ["de": "Schachmatt!", "en": "Checkmate!"],
        "stalemate_alert": ["de": "Patt!", "en": "Stalemate!"],
        "draw_insufficient": ["de": "Remis wegen unzureichendem Material", "en": "Draw due to insufficient material"],
        "time_expired": ["de": "Zeit abgelaufen", "en": "Time Expired"],
        "expired_desc": ["de": "Die Bedenkzeit ist abgelaufen.", "en": "The thinking time has expired."],
        "close": ["de": "Schließen", "en": "Close"],
        "promotion_title": ["de": "Bauernumwandlung", "en": "Pawn Promotion"],
        "promotion_msg": ["de": "Wähle eine Figur", "en": "Choose a piece"],
        "queen": ["de": "Dame", "en": "Queen"],
        "knight": ["de": "Springer", "en": "Knight"],
        "rook": ["de": "Turm", "en": "Rook"],
        "bishop": ["de": "Läufer", "en": "Bishop"],
        "user_player": ["de": "Spieler", "en": "Player"],
        "stockfish": ["de": "Stockfish", "en": "Stockfish"],
        "active_analysis": ["de": "Live Analyse", "en": "Live Analysis"],
        "eval_advantage": ["de": "Vorteil", "en": "Advantage"],
        "show_analysis_toggle": ["de": "Zug-Analyse anzeigen", "en": "Show Move Analysis"],
        
        // Move Classifications
        "brilliant": ["de": "Brillant", "en": "Brilliant"],
        "great": ["de": "Großartig", "en": "Great Move"],
        "best": ["de": "Bester Zug", "en": "Best Move"],
        "excellent": ["de": "Exzellent", "en": "Excellent"],
        "good": ["de": "Gut", "en": "Good"],
        "inaccuracy": ["de": "Ungenauigkeit", "en": "Inaccuracy"],
        "mistake": ["de": "Fehler", "en": "Mistake"],
        "blunder": ["de": "Grober Fehler", "en": "Blunder"],
        "missed": ["de": "Verpasst", "en": "Missed Win"],
        "book": ["de": "Buchzug", "en": "Book Move"],
        "forced": ["de": "Erzwungen", "en": "Forced"],
        
        // Game History Screen
        "saved_games": ["de": "Gespeicherte Spiele", "en": "Saved Games"],
        "no_saved_games": ["de": "Noch keine Spiele absolviert.", "en": "No games played yet."],
        "game_history_desc": ["de": "Hier findest du eine Übersicht deiner gespielten Partien und deiner Performance.", "en": "Here is an overview of your played games and your performance."],
        "win_rate": ["de": "Winrate", "en": "Win Rate"],
        "result_win": ["de": "Sieg", "en": "Victory"],
        "result_loss": ["de": "Niederlage", "en": "Loss"],
        "result_draw": ["de": "Remis", "en": "Draw"],
        "played_at": ["de": "Gespielt am", "en": "Played on"],
        "game_history": ["de": "Spielverlauf", "en": "Game History"],
        "clear_history": ["de": "Verlauf löschen", "en": "Clear History"],
        "complete_game_to_view": ["de": "Beende ein Spiel, um es hier zu sehen", "en": "Complete a game to view it here"],
        "final_elo": ["de": "End-Elo", "en": "Final Elo"],
        "none": ["de": "Keine", "en": "None"],
        
        // Opening Trainer Screen
        "theory_text": ["de": "Meistere die Theorie der bekanntesten Schacheröffnungen spielerisch gegen den Bot.", "en": "Master the theory of the most famous chess openings playfully against the bot."],
        "choose_color": ["de": "Farbe wählen", "en": "Choose Color"],
        "train_as": ["de": "Trainiere als", "en": "Train as"],
        "start_training": ["de": "Training starten", "en": "Start Training"],
        "back": ["de": "Zurück", "en": "Back"],
        "completed": ["de": "Abgeschlossen", "en": "Completed"],
        "wrong_move": ["de": "Falscher Zug!", "en": "Wrong Move!"],
        "try_again": ["de": "Nochmal versuchen", "en": "Try Again"],
        "well_done": ["de": "Gut gemacht!", "en": "Well done!"],
        "opening_finished": ["de": "Du hast alle theoretischen Züge dieser Eröffnung gelernt.", "en": "You have learned all theoretical moves of this opening."],
        "tip_btn": ["de": "Tipp zeigen", "en": "Show Hint"],
        "narrow_piece_btn": ["de": "Figur eingrenzen", "en": "Narrow Piece"],
        "show_arrow_btn": ["de": "Pfeil zeigen", "en": "Show Arrow"],
        "hide_tip_btn": ["de": "Tipp ausblenden", "en": "Hide Hint"],
        "current_line": ["de": "Aktuelle Linie", "en": "Current Line"],
        
        // Mate Scenarios Screen
        "mate_scenarios": ["de": "Matt-Szenarien", "en": "Checkmate Scenarios"],
        "openings_training": ["de": "Eröffnungen trainieren", "en": "Train Openings"],
        "mate_training_desc": ["de": "Gewinne elementare Endspiele fehlerfrei gegen Stockfish auf Maximum.", "en": "Win basic endgames flawlessly against Stockfish set to maximum."],
        "openings_training_desc": ["de": "Meistere die Theorie der bekanntesten Schacheröffnungen.", "en": "Master the theory of the most famous chess openings."],
        "scenarios": ["de": "Szenarien", "en": "Scenarios"],
        "draw_error_title": ["de": "Fehler!", "en": "Mistake!"],
        "draw_error_msg": ["de": "Dieser Zug führt zu einem Remis. Versuch es noch einmal!", "en": "This move leads to a draw. Try again!"],
        "mate_success_title": ["de": "Schachmatt!", "en": "Checkmate!"],
        "mate_success_msg": ["de": "Gut gemacht! Du hast den Bot mattgesetzt.", "en": "Well done! You checkmated the bot."],
        
        // Coordinate Learning Screen
        "coord_title": ["de": "Felder lernen", "en": "Coordinate Trainer"],
        "coord_desc": ["de": "Verbessere deine Brett-Visualisierung", "en": "Improve your board visualization"],
        "high_scores": ["de": "Deine Highscores", "en": "Your High Scores"],
        "labeled": ["de": "Mit Beschriftung", "en": "With Labels"],
        "unlabeled": ["de": "Ohne Beschriftung", "en": "Without Labels"],
        "select_mode": ["de": "Spielmodus wählen", "en": "Select Game Mode"],
        "start_rated": ["de": "Rated-Modus starten", "en": "Start Rated Mode"],
        "rated_desc": ["de": "Erspiele dir unter Zeitdruck ein hohes ELO-Rating. Schnelle Antworten geben Speed-Bonus-Elo. Falsche Antworten ziehen Elo ab.", "en": "Gain a high ELO rating under time pressure. Fast answers give speed bonus Elo. Wrong answers deduct Elo."],
        "start_endless": ["de": "Endless-Modus starten", "en": "Start Endless Mode"],
        "endless_desc": ["de": "Übe ohne Zeitlimit, aber jeder Fehler beendet das Spiel sofort. Dein Score wird aus der Anzahl korrekter Felder und deiner Durchschnittsgeschwindigkeit berechnet.", "en": "Practice without time limit, but any mistake ends the game immediately. Your score is based on correct squares and average speed."],
        "pts": ["de": "Pkt.", "en": "Pts."],
        "average": ["de": "Schnitt", "en": "Average"],
        "abort": ["de": "Abbrechen", "en": "Abort"],
        "squares": ["de": "Felder", "en": "Squares"],
        "find_square": ["de": "Finde das Feld:", "en": "Find the square:"],
        "game_finished": ["de": "Spiel beendet!", "en": "Game Finished!"],
        "new_high_score": ["de": "NEUER HIGHSCORE!", "en": "NEW HIGH SCORE!"],
        "achieved_rating": ["de": "Erreichtes Rating", "en": "Achieved Rating"],
        "correct_squares": ["de": "Richtige Felder", "en": "Correct Squares"],
        "incorrect_squares": ["de": "Falsche Felder", "en": "Incorrect Squares"],
        "endless_score": ["de": "Endless-Score", "en": "Endless Score"],
        "play_again": ["de": "Nochmal spielen", "en": "Play Again"],
        "main_menu": ["de": "Zum Hauptmenü", "en": "To Main Menu"],
        
        // Miscellaneous
        "game_settings": ["de": "Spiel-Einstellungen", "en": "Game Settings"],
        "haptic_feedback": ["de": "Haptisches Feedback", "en": "Haptic Feedback"],
        "screen_shake": ["de": "Bildschirmschütteln bei Zug", "en": "Screen Shake on Move"],
        "bot_name_label": ["de": "Gegner-Name", "en": "Opponent Name"],
        "step_num": ["de": "Zug %d", "en": "Move %d"],
        "mate_in": ["de": "Matt in %@", "en": "Mate in %@"],
        "more_moves_than_needed": ["de": "%d mehr Züge als nötig", "en": "%d more moves than needed"],
    ]
}
