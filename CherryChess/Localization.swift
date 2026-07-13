import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case en = "en"
    case de = "de"
    case es = "es"
    case fr = "fr"
    case it = "it"
    case pt = "pt"
    case nl = "nl"
    case ru = "ru"
    case ja = "ja"
    case zh = "zh"

    var id: String { rawValue }

    /// Native display name, as a professional app lists its languages.
    var displayName: String {
        switch self {
        case .en: return "English"
        case .de: return "Deutsch"
        case .es: return "Español"
        case .fr: return "Français"
        case .it: return "Italiano"
        case .pt: return "Português"
        case .nl: return "Nederlands"
        case .ru: return "Русский"
        case .ja: return "日本語"
        case .zh: return "中文"
        }
    }

    /// The supported language best matching the user's device/region preferences.
    /// Falls back to English when no preferred language is supported.
    static var deviceDefault: String {
        let supported = Set(AppLanguage.allCases.map { $0.rawValue })
        for preferred in Locale.preferredLanguages {
            // Preferred entries look like "en-US", "pt-BR", "zh-Hans-CN" → take the base code.
            let base = preferred.split(separator: "-").first.map(String.init)?.lowercased() ?? ""
            if supported.contains(base) { return base }
        }
        return "en"
    }

    /// Call once at launch so `@AppStorage("appLanguage")` and `L10n` default to
    /// the user's region on first run (before onboarding), without persisting until
    /// the user explicitly picks a language.
    static func registerDeviceDefault() {
        UserDefaults.standard.register(defaults: ["appLanguage": deviceDefault])
    }
}

struct L10n {
    static var currentLanguage: String {
        UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.deviceDefault
    }

    static func tr(_ key: String) -> String {
        let lang = currentLanguage
        if let dict = translations[key] {
            return dict[lang] ?? dict["en"] ?? dict["de"] ?? key
        }
        return key
    }

    static func translateResult(_ result: String) -> String {
        // Game-result strings are generated in German; translate to English for every
        // non-German locale (English is the shared fallback across the other languages).
        let isDe = currentLanguage == "de"
        if isDe {
            return result
        }

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
        if result.contains("unzureichendem Material") {
            return "Draw due to insufficient material"
        }
        if result.contains("Zeit abgelaufen") {
            return "Time expired"
        }

        return result
    }

    // Order of languages per entry: de, en, es, fr, it, pt, nl, ru, ja, zh
    private static let translations: [String: [String: String]] = [
        // Tabs
        "game": ["de": "Spiel", "en": "Game", "es": "Juego", "fr": "Partie", "it": "Gioco", "pt": "Jogo", "nl": "Spel", "ru": "Игра", "ja": "対局", "zh": "对弈"],
        "history": ["de": "Verlauf", "en": "History", "es": "Historial", "fr": "Historique", "it": "Cronologia", "pt": "Histórico", "nl": "Geschiedenis", "ru": "История", "ja": "履歴", "zh": "历史"],
        "openings": ["de": "Eröffnungen", "en": "Openings", "es": "Aperturas", "fr": "Ouvertures", "it": "Aperture", "pt": "Aberturas", "nl": "Openingen", "ru": "Дебюты", "ja": "定跡", "zh": "开局"],
        "training": ["de": "Training", "en": "Training", "es": "Entrenamiento", "fr": "Entraînement", "it": "Allenamento", "pt": "Treino", "nl": "Training", "ru": "Тренировка", "ja": "トレーニング", "zh": "训练"],
        "analysis": ["de": "Analyse", "en": "Analysis", "es": "Análisis", "fr": "Analyse", "it": "Analisi", "pt": "Análise", "nl": "Analyse", "ru": "Анализ", "ja": "解析", "zh": "分析"],
        "analysis_setup_title": ["de": "Brett-Analyse", "en": "Board Analysis", "es": "Análisis del tablero", "fr": "Analyse de l'échiquier", "it": "Analisi della scacchiera", "pt": "Análise do tabuleiro", "nl": "Bordanalyse", "ru": "Анализ позиции", "ja": "盤面解析", "zh": "棋盘分析"],
        "analysis_setup_subtitle": ["de": "Analysiere Stellungen und spiele Züge für beide Seiten.", "en": "Analyze positions and play moves for both sides.", "es": "Analiza posiciones y juega para ambos bandos.", "fr": "Analysez des positions et jouez pour les deux camps.", "it": "Analizza le posizioni e gioca per entrambi i lati.", "pt": "Analise posições e jogue para os dois lados.", "nl": "Analyseer stellingen en speel zetten voor beide kanten.", "ru": "Анализируйте позиции и делайте ходы за обе стороны.", "ja": "局面を解析し、両陣営の手を指せます。", "zh": "分析局面并为双方走子。"],
        "start_analysis": ["de": "Analyse starten", "en": "Start Analysis", "es": "Iniciar análisis", "fr": "Démarrer l'analyse", "it": "Avvia analisi", "pt": "Iniciar análise", "nl": "Analyse starten", "ru": "Начать анализ", "ja": "解析を開始", "zh": "开始分析"],
        "learn_coordinates": ["de": "Felder lernen", "en": "Coordinate Trainer", "es": "Entrenar casillas", "fr": "Entraîneur de cases", "it": "Allenatore di caselle", "pt": "Treino de casas", "nl": "Coördinatentrainer", "ru": "Тренажёр координат", "ja": "座標トレーナー", "zh": "坐标训练"],
        "settings": ["de": "Einstellungen", "en": "Settings", "es": "Ajustes", "fr": "Réglages", "it": "Impostazioni", "pt": "Definições", "nl": "Instellingen", "ru": "Настройки", "ja": "設定", "zh": "设置"],

        // Settings Tab
        "language": ["de": "Sprache", "en": "Language", "es": "Idioma", "fr": "Langue", "it": "Lingua", "pt": "Idioma", "nl": "Taal", "ru": "Язык", "ja": "言語", "zh": "语言"],
        "theme": ["de": "Design", "en": "Theme", "es": "Tema", "fr": "Thème", "it": "Tema", "pt": "Tema", "nl": "Thema", "ru": "Тема", "ja": "テーマ", "zh": "主题"],
        "standard": ["de": "Elysium", "en": "Elysium", "es": "Elysium", "fr": "Elysium", "it": "Elysium", "pt": "Elysium", "nl": "Elysium", "ru": "Elysium", "ja": "Elysium", "zh": "Elysium"],
        "cherry": ["de": "Cherry", "en": "Cherry", "es": "Cherry", "fr": "Cherry", "it": "Cherry", "pt": "Cherry", "nl": "Cherry", "ru": "Cherry", "ja": "Cherry", "zh": "Cherry"],
        "frost": ["de": "Frost", "en": "Frost", "es": "Frost", "fr": "Frost", "it": "Frost", "pt": "Frost", "nl": "Frost", "ru": "Frost", "ja": "Frost", "zh": "Frost"],
        "dark_neon": ["de": "Nebula", "en": "Nebula", "es": "Nebula", "fr": "Nebula", "it": "Nebula", "pt": "Nebula", "nl": "Nebula", "ru": "Nebula", "ja": "Nebula", "zh": "Nebula"],
        "midnight_gold": ["de": "Eclipse", "en": "Eclipse", "es": "Eclipse", "fr": "Eclipse", "it": "Eclipse", "pt": "Eclipse", "nl": "Eclipse", "ru": "Eclipse", "ja": "Eclipse", "zh": "Eclipse"],
        "sweet_rose": ["de": "Sophie", "en": "Sophie", "es": "Sophie", "fr": "Sophie", "it": "Sophie", "pt": "Sophie", "nl": "Sophie", "ru": "Sophie", "ja": "Sophie", "zh": "Sophie"],
        "onyx": ["de": "Onyx", "en": "Onyx", "es": "Onyx", "fr": "Onyx", "it": "Onyx", "pt": "Onyx", "nl": "Onyx", "ru": "Onyx", "ja": "Onyx", "zh": "Onyx"],
        "aquamarine": ["de": "Aquamarine", "en": "Aquamarine", "es": "Aquamarine", "fr": "Aquamarine", "it": "Aquamarine", "pt": "Aquamarine", "nl": "Aquamarine", "ru": "Aquamarine", "ja": "Aquamarine", "zh": "Aquamarine"],
        "board_coordinates": ["de": "Feldbezeichnungen anzeigen", "en": "Show Board Coordinates", "es": "Mostrar coordenadas", "fr": "Afficher les coordonnées", "it": "Mostra coordinate", "pt": "Mostrar coordenadas", "nl": "Coördinaten tonen", "ru": "Показывать координаты", "ja": "座標を表示", "zh": "显示坐标"],
        "reset_history": ["de": "Verlauf zurücksetzen", "en": "Reset History", "es": "Restablecer historial", "fr": "Réinitialiser l'historique", "it": "Reimposta cronologia", "pt": "Repor histórico", "nl": "Geschiedenis wissen", "ru": "Сбросить историю", "ja": "履歴をリセット", "zh": "重置历史"],
        "confirm_reset": ["de": "Möchtest du wirklich alle aufgezeichneten Spiele löschen?", "en": "Are you sure you want to delete all saved games?", "es": "¿Seguro que quieres eliminar todas las partidas guardadas?", "fr": "Voulez-vous vraiment supprimer toutes les parties enregistrées ?", "it": "Vuoi davvero eliminare tutte le partite salvate?", "pt": "Tens a certeza de que queres apagar todos os jogos guardados?", "nl": "Weet je zeker dat je alle opgeslagen partijen wilt verwijderen?", "ru": "Удалить все сохранённые партии?", "ja": "保存したすべての対局を削除しますか？", "zh": "确定要删除所有已保存的对局吗？"],
        "delete": ["de": "Löschen", "en": "Delete", "es": "Eliminar", "fr": "Supprimer", "it": "Elimina", "pt": "Apagar", "nl": "Verwijderen", "ru": "Удалить", "ja": "削除", "zh": "删除"],
        "cancel": ["de": "Abbrechen", "en": "Cancel", "es": "Cancelar", "fr": "Annuler", "it": "Annulla", "pt": "Cancelar", "nl": "Annuleren", "ru": "Отмена", "ja": "キャンセル", "zh": "取消"],
        "theme_selection": ["de": "Design-Thema", "en": "Theme Selection", "es": "Selección de tema", "fr": "Choix du thème", "it": "Selezione tema", "pt": "Seleção de tema", "nl": "Themakeuze", "ru": "Выбор темы", "ja": "テーマ選択", "zh": "主题选择"],
        "lang_selection": ["de": "Sprachauswahl", "en": "Language Selection", "es": "Selección de idioma", "fr": "Choix de la langue", "it": "Selezione lingua", "pt": "Seleção de idioma", "nl": "Taalkeuze", "ru": "Выбор языка", "ja": "言語選択", "zh": "语言选择"],
        "app_icon_selection": ["de": "App-Symbol", "en": "App Icon", "es": "Icono de la app", "fr": "Icône de l'app", "it": "Icona dell'app", "pt": "Ícone da app", "nl": "App-pictogram", "ru": "Значок приложения", "ja": "アプリアイコン", "zh": "应用图标"],
        "danger_zone": ["de": "Gefahrenzone", "en": "Danger Zone", "es": "Zona de peligro", "fr": "Zone sensible", "it": "Zona pericolosa", "pt": "Zona de perigo", "nl": "Gevarenzone", "ru": "Опасная зона", "ja": "危険な操作", "zh": "危险区域"],
        "about_app": ["de": "Über die App", "en": "About the App", "es": "Acerca de la app", "fr": "À propos de l'app", "it": "Informazioni sull'app", "pt": "Sobre a app", "nl": "Over de app", "ru": "О приложении", "ja": "アプリについて", "zh": "关于应用"],
        "about_desc": ["de": "Cherry Chess\nSpiele, trainiere und analysiere deine Schachpartien.\nby Milan", "en": "Cherry Chess\nPlay, train, and analyze your chess games.\nby Milan", "es": "Cherry Chess\nJuega, entrena y analiza tus partidas de ajedrez.\nby Milan", "fr": "Cherry Chess\nJouez, entraînez-vous et analysez vos parties d'échecs.\nby Milan", "it": "Cherry Chess\nGioca, allenati e analizza le tue partite di scacchi.\nby Milan", "pt": "Cherry Chess\nJoga, treina e analisa as tuas partidas de xadrez.\nby Milan", "nl": "Cherry Chess\nSpeel, train en analyseer je schaakpartijen.\nby Milan", "ru": "Cherry Chess\nИграйте, тренируйтесь и анализируйте свои шахматные партии.\nby Milan", "ja": "Cherry Chess\nチェスを指し、鍛え、解析しよう。\nby Milan", "zh": "Cherry Chess\n下棋、训练并分析你的对局。\nby Milan"],

        // Game Setup Screen
        "singleplayer": ["de": "Einzelspiel", "en": "Singleplayer", "es": "Un jugador", "fr": "Solo", "it": "Giocatore singolo", "pt": "Um jogador", "nl": "Één speler", "ru": "Одиночная игра", "ja": "シングルプレイ", "zh": "单人"],
        "setup_subtitle": ["de": "Konfiguriere dein Spiel gegen Stockfish und trainiere deine Taktik.", "en": "Configure your game against Stockfish and train your tactics.", "es": "Configura tu partida contra Stockfish y entrena tu táctica.", "fr": "Configurez votre partie contre Stockfish et travaillez votre tactique.", "it": "Configura la partita contro Stockfish e allena la tua tattica.", "pt": "Configura o teu jogo contra o Stockfish e treina a tua tática.", "nl": "Stel je partij tegen Stockfish in en train je tactiek.", "ru": "Настройте партию против Stockfish и тренируйте тактику.", "ja": "Stockfish との対局を設定し、戦術を鍛えよう。", "zh": "配置与 Stockfish 的对局并训练战术。"],
        "choose_mode": ["de": "Modus wählen", "en": "Choose Mode", "es": "Elegir modo", "fr": "Choisir le mode", "it": "Scegli modalità", "pt": "Escolher modo", "nl": "Kies modus", "ru": "Выбор режима", "ja": "モードを選択", "zh": "选择模式"],
        "choose_mode_subtitle": ["de": "Wähle aus, ob du gegen den Bot oder einen Freund spielen möchtest.", "en": "Choose if you want to play against the bot or a friend.", "es": "Elige si quieres jugar contra el bot o un amigo.", "fr": "Choisissez de jouer contre le bot ou un ami.", "it": "Scegli se giocare contro il bot o un amico.", "pt": "Escolhe se queres jogar contra o bot ou um amigo.", "nl": "Kies of je tegen de bot of een vriend wilt spelen.", "ru": "Выберите игру против бота или друга.", "ja": "ボットと友達のどちらと対局するか選択してください。", "zh": "选择与机器人还是好友对弈。"],
        "play_against_bot": ["de": "Gegen Bot spielen", "en": "Against Bot", "es": "Contra el bot", "fr": "Contre le bot", "it": "Contro il bot", "pt": "Contra o bot", "nl": "Tegen de bot", "ru": "Против бота", "ja": "ボットと対局", "zh": "对战机器人"],
        "play_against_friend": ["de": "Gegen Freund spielen", "en": "Against Friend", "es": "Contra un amigo", "fr": "Contre un ami", "it": "Contro un amico", "pt": "Contra um amigo", "nl": "Tegen een vriend", "ru": "Против друга", "ja": "友達と対局", "zh": "对战好友"],
        "bot_mode_desc": ["de": "Spiele gegen den Computer mit einstellbarer Spielstärke.", "en": "Play against the computer with adjustable strength.", "es": "Juega contra el ordenador con fuerza ajustable.", "fr": "Jouez contre l'ordinateur avec une force réglable.", "it": "Gioca contro il computer con forza regolabile.", "pt": "Joga contra o computador com força ajustável.", "nl": "Speel tegen de computer met instelbare sterkte.", "ru": "Играйте против компьютера с настраиваемой силой.", "ja": "強さを調整できるコンピューターと対局。", "zh": "与可调节强度的电脑对弈。"],
        "friend_mode_desc": ["de": "Spiele gegen einen Freund am selben Gerät.", "en": "Play against a friend on the same device.", "es": "Juega contra un amigo en el mismo dispositivo.", "fr": "Jouez contre un ami sur le même appareil.", "it": "Gioca contro un amico sullo stesso dispositivo.", "pt": "Joga contra um amigo no mesmo dispositivo.", "nl": "Speel tegen een vriend op hetzelfde apparaat.", "ru": "Играйте с другом на одном устройстве.", "ja": "同じ端末で友達と対局。", "zh": "在同一设备上与好友对弈。"],
        "allow_hints": ["de": "Hinweise erlauben", "en": "Allow Hints", "es": "Permitir pistas", "fr": "Autoriser les indices", "it": "Consenti suggerimenti", "pt": "Permitir dicas", "nl": "Hints toestaan", "ru": "Разрешить подсказки", "ja": "ヒントを許可", "zh": "允许提示"],
        "show_best_moves_retro": ["de": "Beste Züge nachträglich anzeigen", "en": "Show Best Moves Retrospectively", "es": "Mostrar mejores jugadas después", "fr": "Afficher les meilleurs coups après coup", "it": "Mostra le mosse migliori a posteriori", "pt": "Mostrar melhores lances depois", "nl": "Beste zetten achteraf tonen", "ru": "Показывать лучшие ходы после", "ja": "後から最善手を表示", "zh": "事后显示最佳着法"],
        "flip_board_after_moves": ["de": "Brett nach Zügen drehen", "en": "Flip Board after Moves", "es": "Girar tablero tras jugadas", "fr": "Pivoter l'échiquier après les coups", "it": "Ruota la scacchiera dopo le mosse", "pt": "Virar tabuleiro após lances", "nl": "Bord draaien na zetten", "ru": "Переворачивать доску после ходов", "ja": "手番ごとに盤を反転", "zh": "走子后翻转棋盘"],
        "setup_friend_title": ["de": "Gegen einen Freund", "en": "Against a Friend", "es": "Contra un amigo", "fr": "Contre un ami", "it": "Contro un amico", "pt": "Contra um amigo", "nl": "Tegen een vriend", "ru": "Против друга", "ja": "友達と対局", "zh": "对战好友"],
        "setup_friend_subtitle": ["de": "Tritt gegen einen Freund an und reicht das Handy weiter.", "en": "Compete against a friend and pass the phone.", "es": "Compite contra un amigo y pasad el teléfono.", "fr": "Affrontez un ami et passez-vous le téléphone.", "it": "Sfida un amico e passatevi il telefono.", "pt": "Compete contra um amigo e passem o telemóvel.", "nl": "Speel tegen een vriend en geef de telefoon door.", "ru": "Играйте с другом, передавая телефон.", "ja": "友達と対戦し、端末を渡し合おう。", "zh": "与好友对战，轮流传递手机。"],
        "play_as": ["de": "Spielen als", "en": "Play as", "es": "Jugar como", "fr": "Jouer avec", "it": "Gioca come", "pt": "Jogar como", "nl": "Speel als", "ru": "Играть за", "ja": "手番を選択", "zh": "执子"],
        "white": ["de": "Weiß", "en": "White", "es": "Blancas", "fr": "Blancs", "it": "Bianco", "pt": "Brancas", "nl": "Wit", "ru": "Белые", "ja": "白", "zh": "白方"],
        "black": ["de": "Schwarz", "en": "Black", "es": "Negras", "fr": "Noirs", "it": "Nero", "pt": "Pretas", "nl": "Zwart", "ru": "Чёрные", "ja": "黒", "zh": "黑方"],
        "random": ["de": "Zufall", "en": "Random", "es": "Aleatorio", "fr": "Aléatoire", "it": "Casuale", "pt": "Aleatório", "nl": "Willekeurig", "ru": "Случайно", "ja": "ランダム", "zh": "随机"],
        "computer_strength": ["de": "Computer Spielstärke (Elo)", "en": "Computer Strength (Elo)", "es": "Fuerza del ordenador (Elo)", "fr": "Force de l'ordinateur (Elo)", "it": "Forza del computer (Elo)", "pt": "Força do computador (Elo)", "nl": "Computersterkte (Elo)", "ru": "Сила компьютера (Elo)", "ja": "コンピューターの強さ (Elo)", "zh": "电脑强度 (Elo)"],
        "time_control": ["de": "Bedenkzeit", "en": "Time Control", "es": "Control de tiempo", "fr": "Cadence", "it": "Controllo del tempo", "pt": "Controlo de tempo", "nl": "Speeltempo", "ru": "Контроль времени", "ja": "持ち時間", "zh": "时间控制"],
        "activate_clock": ["de": "Schach-Uhr aktivieren", "en": "Enable Chess Clock", "es": "Activar reloj de ajedrez", "fr": "Activer la pendule", "it": "Attiva orologio", "pt": "Ativar relógio de xadrez", "nl": "Schaakklok inschakelen", "ru": "Включить шахматные часы", "ja": "チェスクロックを有効化", "zh": "启用棋钟"],
        "minutes": ["de": "Minuten", "en": "Minutes", "es": "Minutos", "fr": "Minutes", "it": "Minuti", "pt": "Minutos", "nl": "Minuten", "ru": "Минуты", "ja": "分", "zh": "分钟"],
        "start_game": ["de": "Spiel starten", "en": "Start Game", "es": "Empezar partida", "fr": "Démarrer la partie", "it": "Inizia partita", "pt": "Iniciar jogo", "nl": "Spel starten", "ru": "Начать игру", "ja": "対局を開始", "zh": "开始对弈"],
        "new_game": ["de": "Neues Spiel", "en": "New Game", "es": "Nueva partida", "fr": "Nouvelle partie", "it": "Nuova partita", "pt": "Novo jogo", "nl": "Nieuw spel", "ru": "Новая игра", "ja": "新しい対局", "zh": "新对局"],

        // Difficulty Levels
        "beginner": ["de": "Anfänger", "en": "Beginner", "es": "Principiante", "fr": "Débutant", "it": "Principiante", "pt": "Iniciante", "nl": "Beginner", "ru": "Новичок", "ja": "初級", "zh": "初学者"],
        "intermediate": ["de": "Fortgeschritten", "en": "Intermediate", "es": "Intermedio", "fr": "Intermédiaire", "it": "Intermedio", "pt": "Intermédio", "nl": "Gevorderd", "ru": "Средний", "ja": "中級", "zh": "进阶"],
        "advanced": ["de": "Clubspieler", "en": "Advanced", "es": "Avanzado", "fr": "Avancé", "it": "Avanzato", "pt": "Avançado", "nl": "Clubspeler", "ru": "Продвинутый", "ja": "上級", "zh": "高级"],
        "master": ["de": "Meister", "en": "Master", "es": "Maestro", "fr": "Maître", "it": "Maestro", "pt": "Mestre", "nl": "Meester", "ru": "Мастер", "ja": "マスター", "zh": "大师"],
        "grandmaster": ["de": "Großmeister", "en": "Grandmaster", "es": "Gran maestro", "fr": "Grand maître", "it": "Gran maestro", "pt": "Grande mestre", "nl": "Grootmeester", "ru": "Гроссмейстер", "ja": "グランドマスター", "zh": "特级大师"],

        // In-Game UI
        "best_move": ["de": "Bester Zug", "en": "Best Move", "es": "Mejor jugada", "fr": "Meilleur coup", "it": "Mossa migliore", "pt": "Melhor lance", "nl": "Beste zet", "ru": "Лучший ход", "ja": "最善手", "zh": "最佳着法"],
        "show_arrow": ["de": "Pfeil zeigen", "en": "Show Arrow", "es": "Mostrar flecha", "fr": "Afficher la flèche", "it": "Mostra freccia", "pt": "Mostrar seta", "nl": "Pijl tonen", "ru": "Показать стрелку", "ja": "矢印を表示", "zh": "显示箭头"],
        "hint": ["de": "Tipp zeigen", "en": "Show Hint", "es": "Mostrar pista", "fr": "Afficher l'indice", "it": "Mostra suggerimento", "pt": "Mostrar dica", "nl": "Hint tonen", "ru": "Показать подсказку", "ja": "ヒントを表示", "zh": "显示提示"],
        "hint_narrow": ["de": "Figur eingrenzen", "en": "Narrow Piece", "es": "Acotar pieza", "fr": "Cibler la pièce", "it": "Restringi il pezzo", "pt": "Restringir peça", "nl": "Stuk beperken", "ru": "Сузить до фигуры", "ja": "駒を絞る", "zh": "缩小棋子范围"],
        "hint_hide": ["de": "Tipp ausblenden", "en": "Hide Hint", "es": "Ocultar pista", "fr": "Masquer l'indice", "it": "Nascondi suggerimento", "pt": "Ocultar dica", "nl": "Hint verbergen", "ru": "Скрыть подсказку", "ja": "ヒントを隠す", "zh": "隐藏提示"],
        "live_strength": ["de": "Live-Spielstärke", "en": "Live Elo Rating", "es": "Elo en vivo", "fr": "Elo en direct", "it": "Elo dal vivo", "pt": "Elo ao vivo", "nl": "Live Elo", "ru": "Elo в реальном времени", "ja": "ライブElo", "zh": "实时 Elo"],
        "accuracy": ["de": "Genauigkeit", "en": "Accuracy", "es": "Precisión", "fr": "Précision", "it": "Precisione", "pt": "Precisão", "nl": "Nauwkeurigheid", "ru": "Точность", "ja": "正確性", "zh": "准确率"],
        "game_over": ["de": "Spiel vorbei", "en": "Game Over", "es": "Partida terminada", "fr": "Partie terminée", "it": "Partita finita", "pt": "Fim do jogo", "nl": "Spel voorbij", "ru": "Игра окончена", "ja": "対局終了", "zh": "对局结束"],
        "mate_alert": ["de": "Schachmatt!", "en": "Checkmate!", "es": "¡Jaque mate!", "fr": "Échec et mat !", "it": "Scacco matto!", "pt": "Xeque-mate!", "nl": "Schaakmat!", "ru": "Мат!", "ja": "チェックメイト！", "zh": "将死！"],
        "stalemate_alert": ["de": "Patt!", "en": "Stalemate!", "es": "¡Ahogado!", "fr": "Pat !", "it": "Stallo!", "pt": "Afogamento!", "nl": "Pat!", "ru": "Пат!", "ja": "ステイルメイト！", "zh": "逼和！"],
        "draw_insufficient": ["de": "Remis wegen unzureichendem Material", "en": "Draw due to insufficient material", "es": "Tablas por material insuficiente", "fr": "Nulle par manque de matériel", "it": "Patta per materiale insufficiente", "pt": "Empate por material insuficiente", "nl": "Remise door onvoldoende materiaal", "ru": "Ничья из-за недостатка материала", "ja": "駒不足による引き分け", "zh": "子力不足和棋"],
        "time_expired": ["de": "Zeit abgelaufen", "en": "Time Expired", "es": "Tiempo agotado", "fr": "Temps écoulé", "it": "Tempo scaduto", "pt": "Tempo esgotado", "nl": "Tijd verstreken", "ru": "Время истекло", "ja": "時間切れ", "zh": "时间到"],
        "expired_desc": ["de": "Die Bedenkzeit ist abgelaufen.", "en": "The thinking time has expired.", "es": "El tiempo de reflexión se ha agotado.", "fr": "Le temps de réflexion est écoulé.", "it": "Il tempo di riflessione è scaduto.", "pt": "O tempo de reflexão esgotou-se.", "nl": "De bedenktijd is verstreken.", "ru": "Время на обдумывание истекло.", "ja": "持ち時間が切れました。", "zh": "思考时间已用完。"],
        "close": ["de": "Schließen", "en": "Close", "es": "Cerrar", "fr": "Fermer", "it": "Chiudi", "pt": "Fechar", "nl": "Sluiten", "ru": "Закрыть", "ja": "閉じる", "zh": "关闭"],
        "promotion_title": ["de": "Bauernumwandlung", "en": "Pawn Promotion", "es": "Promoción de peón", "fr": "Promotion du pion", "it": "Promozione del pedone", "pt": "Promoção de peão", "nl": "Pionpromotie", "ru": "Превращение пешки", "ja": "ポーンの昇格", "zh": "兵的升变"],
        "promotion_msg": ["de": "Wähle eine Figur", "en": "Choose a piece", "es": "Elige una pieza", "fr": "Choisissez une pièce", "it": "Scegli un pezzo", "pt": "Escolhe uma peça", "nl": "Kies een stuk", "ru": "Выберите фигуру", "ja": "駒を選択", "zh": "选择棋子"],
        "queen": ["de": "Dame", "en": "Queen", "es": "Dama", "fr": "Dame", "it": "Donna", "pt": "Dama", "nl": "Dame", "ru": "Ферзь", "ja": "クイーン", "zh": "后"],
        "knight": ["de": "Springer", "en": "Knight", "es": "Caballo", "fr": "Cavalier", "it": "Cavallo", "pt": "Cavalo", "nl": "Paard", "ru": "Конь", "ja": "ナイト", "zh": "马"],
        "rook": ["de": "Turm", "en": "Rook", "es": "Torre", "fr": "Tour", "it": "Torre", "pt": "Torre", "nl": "Toren", "ru": "Ладья", "ja": "ルーク", "zh": "车"],
        "bishop": ["de": "Läufer", "en": "Bishop", "es": "Alfil", "fr": "Fou", "it": "Alfiere", "pt": "Bispo", "nl": "Loper", "ru": "Слон", "ja": "ビショップ", "zh": "象"],
        "user_player": ["de": "Spieler", "en": "Player", "es": "Jugador", "fr": "Joueur", "it": "Giocatore", "pt": "Jogador", "nl": "Speler", "ru": "Игрок", "ja": "プレイヤー", "zh": "玩家"],
        "stockfish": ["de": "Stockfish", "en": "Stockfish", "es": "Stockfish", "fr": "Stockfish", "it": "Stockfish", "pt": "Stockfish", "nl": "Stockfish", "ru": "Stockfish", "ja": "Stockfish", "zh": "Stockfish"],
        "active_analysis": ["de": "Live Analyse", "en": "Live Analysis", "es": "Análisis en vivo", "fr": "Analyse en direct", "it": "Analisi dal vivo", "pt": "Análise ao vivo", "nl": "Live analyse", "ru": "Анализ вживую", "ja": "ライブ解析", "zh": "实时分析"],
        "eval_advantage": ["de": "Vorteil", "en": "Advantage", "es": "Ventaja", "fr": "Avantage", "it": "Vantaggio", "pt": "Vantagem", "nl": "Voordeel", "ru": "Преимущество", "ja": "優勢", "zh": "优势"],
        "show_analysis_toggle": ["de": "Zug-Analyse anzeigen", "en": "Show Move Analysis", "es": "Mostrar análisis de jugadas", "fr": "Afficher l'analyse des coups", "it": "Mostra analisi delle mosse", "pt": "Mostrar análise de lances", "nl": "Zetanalyse tonen", "ru": "Показывать анализ ходов", "ja": "着手解析を表示", "zh": "显示着法分析"],

        // Move Classifications
        "brilliant": ["de": "Brillant", "en": "Brilliant", "es": "Brillante", "fr": "Brillant", "it": "Brillante", "pt": "Brilhante", "nl": "Briljant", "ru": "Блестяще", "ja": "妙手", "zh": "精彩"],
        "great": ["de": "Großartig", "en": "Great Move", "es": "Gran jugada", "fr": "Excellent coup", "it": "Gran mossa", "pt": "Ótimo lance", "nl": "Sterke zet", "ru": "Отличный ход", "ja": "好手", "zh": "好棋"],
        "best": ["de": "Bester Zug", "en": "Best Move", "es": "Mejor jugada", "fr": "Meilleur coup", "it": "Mossa migliore", "pt": "Melhor lance", "nl": "Beste zet", "ru": "Лучший ход", "ja": "最善手", "zh": "最佳着法"],
        "excellent": ["de": "Exzellent", "en": "Excellent", "es": "Excelente", "fr": "Excellent", "it": "Eccellente", "pt": "Excelente", "nl": "Uitstekend", "ru": "Превосходно", "ja": "秀逸", "zh": "优秀"],
        "good": ["de": "Gut", "en": "Good", "es": "Buena", "fr": "Bon", "it": "Buona", "pt": "Bom", "nl": "Goed", "ru": "Хорошо", "ja": "良手", "zh": "良好"],
        "inaccuracy": ["de": "Ungenauigkeit", "en": "Inaccuracy", "es": "Imprecisión", "fr": "Imprécision", "it": "Imprecisione", "pt": "Imprecisão", "nl": "Onnauwkeurigheid", "ru": "Неточность", "ja": "不正確", "zh": "不精确"],
        "mistake": ["de": "Fehler", "en": "Mistake", "es": "Error", "fr": "Erreur", "it": "Errore", "pt": "Erro", "nl": "Fout", "ru": "Ошибка", "ja": "疑問手", "zh": "错误"],
        "blunder": ["de": "Grober Fehler", "en": "Blunder", "es": "Error grave", "fr": "Gaffe", "it": "Errore grave", "pt": "Erro grave", "nl": "Blunder", "ru": "Грубая ошибка", "ja": "大悪手", "zh": "严重失误"],
        "missed": ["de": "Verpasst", "en": "Missed Win", "es": "Victoria perdida", "fr": "Gain manqué", "it": "Vittoria mancata", "pt": "Vitória perdida", "nl": "Gemiste winst", "ru": "Упущен выигрыш", "ja": "逃した勝ち", "zh": "错失胜机"],
        "book": ["de": "Buchzug", "en": "Book Move", "es": "Jugada de libro", "fr": "Coup de théorie", "it": "Mossa da libro", "pt": "Lance de livro", "nl": "Boekzet", "ru": "Книжный ход", "ja": "定跡手", "zh": "开局理论"],
        "forced": ["de": "Erzwungen", "en": "Forced", "es": "Forzada", "fr": "Forcé", "it": "Forzata", "pt": "Forçado", "nl": "Geforceerd", "ru": "Вынужденно", "ja": "必然手", "zh": "被迫"],

        // Game History Screen
        "saved_games": ["de": "Gespeicherte Spiele", "en": "Saved Games", "es": "Partidas guardadas", "fr": "Parties enregistrées", "it": "Partite salvate", "pt": "Jogos guardados", "nl": "Opgeslagen partijen", "ru": "Сохранённые партии", "ja": "保存した対局", "zh": "已保存对局"],
        "no_saved_games": ["de": "Noch keine Spiele absolviert.", "en": "No games played yet.", "es": "Aún no has jugado partidas.", "fr": "Aucune partie jouée pour l'instant.", "it": "Nessuna partita giocata.", "pt": "Ainda não jogaste nenhum jogo.", "nl": "Nog geen partijen gespeeld.", "ru": "Пока нет сыгранных партий.", "ja": "まだ対局がありません。", "zh": "尚未进行对局。"],
        "game_history_desc": ["de": "Hier findest du eine Übersicht deiner gespielten Partien und deiner Performance.", "en": "Here is an overview of your played games and your performance.", "es": "Aquí tienes un resumen de tus partidas y tu rendimiento.", "fr": "Voici un aperçu de vos parties et de vos performances.", "it": "Ecco una panoramica delle tue partite e delle tue prestazioni.", "pt": "Aqui está uma visão geral dos teus jogos e do teu desempenho.", "nl": "Hier is een overzicht van je partijen en prestaties.", "ru": "Обзор ваших сыгранных партий и результатов.", "ja": "対局とパフォーマンスの概要です。", "zh": "这是你的对局和表现概览。"],
        "win_rate": ["de": "Winrate", "en": "Win Rate", "es": "Ratio de victorias", "fr": "Taux de victoire", "it": "Percentuale di vittorie", "pt": "Taxa de vitórias", "nl": "Winstpercentage", "ru": "Процент побед", "ja": "勝率", "zh": "胜率"],
        "result_win": ["de": "Sieg", "en": "Victory", "es": "Victoria", "fr": "Victoire", "it": "Vittoria", "pt": "Vitória", "nl": "Overwinning", "ru": "Победа", "ja": "勝ち", "zh": "胜"],
        "result_loss": ["de": "Niederlage", "en": "Loss", "es": "Derrota", "fr": "Défaite", "it": "Sconfitta", "pt": "Derrota", "nl": "Verlies", "ru": "Поражение", "ja": "負け", "zh": "负"],
        "result_draw": ["de": "Remis", "en": "Draw", "es": "Tablas", "fr": "Nulle", "it": "Patta", "pt": "Empate", "nl": "Remise", "ru": "Ничья", "ja": "引き分け", "zh": "和"],
        "played_at": ["de": "Gespielt am", "en": "Played on", "es": "Jugada el", "fr": "Jouée le", "it": "Giocata il", "pt": "Jogado em", "nl": "Gespeeld op", "ru": "Сыграно", "ja": "対局日", "zh": "对局于"],
        "game_history": ["de": "Spielverlauf", "en": "Game History", "es": "Historial de partidas", "fr": "Historique des parties", "it": "Cronologia partite", "pt": "Histórico de jogos", "nl": "Partijgeschiedenis", "ru": "История партий", "ja": "対局履歴", "zh": "对局历史"],
        "clear_history": ["de": "Verlauf löschen", "en": "Clear History", "es": "Borrar historial", "fr": "Effacer l'historique", "it": "Cancella cronologia", "pt": "Limpar histórico", "nl": "Geschiedenis wissen", "ru": "Очистить историю", "ja": "履歴を消去", "zh": "清除历史"],
        "complete_game_to_view": ["de": "Beende ein Spiel, um es hier zu sehen", "en": "Complete a game to view it here", "es": "Completa una partida para verla aquí", "fr": "Terminez une partie pour la voir ici", "it": "Completa una partita per vederla qui", "pt": "Completa um jogo para o veres aqui", "nl": "Voltooi een partij om deze hier te zien", "ru": "Завершите партию, чтобы увидеть её здесь", "ja": "対局を終えるとここに表示されます", "zh": "完成一局后可在此查看"],
        "final_elo": ["de": "End-Elo", "en": "Final Elo", "es": "Elo final", "fr": "Elo final", "it": "Elo finale", "pt": "Elo final", "nl": "Eind-Elo", "ru": "Итоговый Elo", "ja": "最終Elo", "zh": "最终 Elo"],
        "none": ["de": "Keine", "en": "None", "es": "Ninguno", "fr": "Aucun", "it": "Nessuno", "pt": "Nenhum", "nl": "Geen", "ru": "Нет", "ja": "なし", "zh": "无"],

        // Opening Trainer Screen
        "theory_text": ["de": "Meistere die Theorie der bekanntesten Schacheröffnungen spielerisch gegen den Bot.", "en": "Master the theory of the most famous chess openings playfully against the bot.", "es": "Domina la teoría de las aperturas más famosas jugando contra el bot.", "fr": "Maîtrisez la théorie des ouvertures les plus connues en jouant contre le bot.", "it": "Padroneggia la teoria delle aperture più famose giocando contro il bot.", "pt": "Domina a teoria das aberturas mais famosas jogando contra o bot.", "nl": "Beheers de theorie van de bekendste openingen spelenderwijs tegen de bot.", "ru": "Освойте теорию известнейших дебютов в игре против бота.", "ja": "ボットと対局しながら有名な定跡の理論を習得しよう。", "zh": "在与机器人对弈中掌握最著名开局的理论。"],
        "choose_color": ["de": "Farbe wählen", "en": "Choose Color", "es": "Elegir color", "fr": "Choisir la couleur", "it": "Scegli il colore", "pt": "Escolher cor", "nl": "Kies kleur", "ru": "Выбор цвета", "ja": "色を選択", "zh": "选择颜色"],
        "train_as": ["de": "Trainiere als", "en": "Train as", "es": "Entrenar como", "fr": "S'entraîner avec", "it": "Allenati come", "pt": "Treinar como", "nl": "Train als", "ru": "Тренироваться за", "ja": "手番を選択", "zh": "训练执子"],
        "start_training": ["de": "Training starten", "en": "Start Training", "es": "Empezar entrenamiento", "fr": "Démarrer l'entraînement", "it": "Inizia allenamento", "pt": "Iniciar treino", "nl": "Training starten", "ru": "Начать тренировку", "ja": "トレーニングを開始", "zh": "开始训练"],
        "back": ["de": "Zurück", "en": "Back", "es": "Atrás", "fr": "Retour", "it": "Indietro", "pt": "Voltar", "nl": "Terug", "ru": "Назад", "ja": "戻る", "zh": "返回"],
        "completed": ["de": "Abgeschlossen", "en": "Completed", "es": "Completado", "fr": "Terminé", "it": "Completato", "pt": "Concluído", "nl": "Voltooid", "ru": "Завершено", "ja": "完了", "zh": "已完成"],
        "wrong_move": ["de": "Falscher Zug!", "en": "Wrong Move!", "es": "¡Jugada incorrecta!", "fr": "Mauvais coup !", "it": "Mossa sbagliata!", "pt": "Lance errado!", "nl": "Verkeerde zet!", "ru": "Неверный ход!", "ja": "間違いです！", "zh": "着法错误！"],
        "try_again": ["de": "Nochmal versuchen", "en": "Try Again", "es": "Inténtalo de nuevo", "fr": "Réessayer", "it": "Riprova", "pt": "Tentar de novo", "nl": "Opnieuw proberen", "ru": "Попробовать снова", "ja": "もう一度", "zh": "再试一次"],
        "well_done": ["de": "Gut gemacht!", "en": "Well done!", "es": "¡Bien hecho!", "fr": "Bien joué !", "it": "Ben fatto!", "pt": "Muito bem!", "nl": "Goed gedaan!", "ru": "Отлично!", "ja": "よくできました！", "zh": "做得好！"],
        "opening_finished": ["de": "Du hast alle theoretischen Züge dieser Eröffnung gelernt.", "en": "You have learned all theoretical moves of this opening.", "es": "Has aprendido todas las jugadas teóricas de esta apertura.", "fr": "Vous avez appris tous les coups théoriques de cette ouverture.", "it": "Hai imparato tutte le mosse teoriche di questa apertura.", "pt": "Aprendeste todos os lances teóricos desta abertura.", "nl": "Je hebt alle theoretische zetten van deze opening geleerd.", "ru": "Вы изучили все теоретические ходы этого дебюта.", "ja": "この定跡の理論手をすべて学びました。", "zh": "你已学习了该开局的全部理论着法。"],
        "tip_btn": ["de": "Tipp zeigen", "en": "Show Hint", "es": "Mostrar pista", "fr": "Afficher l'indice", "it": "Mostra suggerimento", "pt": "Mostrar dica", "nl": "Hint tonen", "ru": "Показать подсказку", "ja": "ヒントを表示", "zh": "显示提示"],
        "narrow_piece_btn": ["de": "Figur eingrenzen", "en": "Narrow Piece", "es": "Acotar pieza", "fr": "Cibler la pièce", "it": "Restringi il pezzo", "pt": "Restringir peça", "nl": "Stuk beperken", "ru": "Сузить до фигуры", "ja": "駒を絞る", "zh": "缩小棋子范围"],
        "show_arrow_btn": ["de": "Pfeil zeigen", "en": "Show Arrow", "es": "Mostrar flecha", "fr": "Afficher la flèche", "it": "Mostra freccia", "pt": "Mostrar seta", "nl": "Pijl tonen", "ru": "Показать стрелку", "ja": "矢印を表示", "zh": "显示箭头"],
        "hide_tip_btn": ["de": "Tipp ausblenden", "en": "Hide Hint", "es": "Ocultar pista", "fr": "Masquer l'indice", "it": "Nascondi suggerimento", "pt": "Ocultar dica", "nl": "Hint verbergen", "ru": "Скрыть подсказку", "ja": "ヒントを隠す", "zh": "隐藏提示"],
        "current_line": ["de": "Aktuelle Linie", "en": "Current Line", "es": "Línea actual", "fr": "Ligne actuelle", "it": "Linea attuale", "pt": "Linha atual", "nl": "Huidige lijn", "ru": "Текущая линия", "ja": "現在の変化", "zh": "当前变着"],

        // Mate Scenarios Screen
        "mate_scenarios": ["de": "Matt-Szenarien", "en": "Checkmate Scenarios", "es": "Escenarios de mate", "fr": "Scénarios de mat", "it": "Scenari di matto", "pt": "Cenários de mate", "nl": "Matscenario's", "ru": "Сценарии мата", "ja": "詰みシナリオ", "zh": "将杀场景"],
        "openings_training": ["de": "Eröffnungen trainieren", "en": "Train Openings", "es": "Entrenar aperturas", "fr": "Entraîner les ouvertures", "it": "Allena le aperture", "pt": "Treinar aberturas", "nl": "Openingen trainen", "ru": "Тренировать дебюты", "ja": "定跡を練習", "zh": "训练开局"],
        "mate_training_desc": ["de": "Gewinne elementare Endspiele fehlerfrei gegen Stockfish auf Maximum.", "en": "Win basic endgames flawlessly against Stockfish set to maximum.", "es": "Gana finales básicos sin errores contra Stockfish al máximo.", "fr": "Gagnez des finales élémentaires sans faute contre Stockfish au maximum.", "it": "Vinci i finali elementari senza errori contro Stockfish al massimo.", "pt": "Vence finais básicos sem erros contra o Stockfish no máximo.", "nl": "Win basiseindspelen foutloos tegen Stockfish op maximum.", "ru": "Безошибочно выигрывайте базовые окончания против Stockfish на максимуме.", "ja": "最大強度のStockfish相手に基本的な終盤をミスなく勝ち切ろう。", "zh": "在最高强度的 Stockfish 面前无误地赢下基本残局。"],
        "openings_training_desc": ["de": "Meistere die Theorie der bekanntesten Schacheröffnungen.", "en": "Master the theory of the most famous chess openings.", "es": "Domina la teoría de las aperturas más famosas.", "fr": "Maîtrisez la théorie des ouvertures les plus connues.", "it": "Padroneggia la teoria delle aperture più famose.", "pt": "Domina a teoria das aberturas mais famosas.", "nl": "Beheers de theorie van de bekendste openingen.", "ru": "Освойте теорию известнейших дебютов.", "ja": "有名な定跡の理論を習得しよう。", "zh": "掌握最著名开局的理论。"],
        "scenarios": ["de": "Szenarien", "en": "Scenarios", "es": "Escenarios", "fr": "Scénarios", "it": "Scenari", "pt": "Cenários", "nl": "Scenario's", "ru": "Сценарии", "ja": "シナリオ", "zh": "场景"],
        "draw_error_title": ["de": "Fehler!", "en": "Mistake!", "es": "¡Error!", "fr": "Erreur !", "it": "Errore!", "pt": "Erro!", "nl": "Fout!", "ru": "Ошибка!", "ja": "失敗！", "zh": "失误！"],
        "draw_error_msg": ["de": "Dieser Zug führt zu einem Remis. Versuch es noch einmal!", "en": "This move leads to a draw. Try again!", "es": "Esta jugada lleva a tablas. ¡Inténtalo de nuevo!", "fr": "Ce coup mène à la nulle. Réessayez !", "it": "Questa mossa porta alla patta. Riprova!", "pt": "Este lance leva a empate. Tenta de novo!", "nl": "Deze zet leidt tot remise. Probeer opnieuw!", "ru": "Этот ход ведёт к ничьей. Попробуйте снова!", "ja": "この手は引き分けになります。もう一度！", "zh": "此着导致和棋。再试一次！"],
        "mate_success_title": ["de": "Schachmatt!", "en": "Checkmate!", "es": "¡Jaque mate!", "fr": "Échec et mat !", "it": "Scacco matto!", "pt": "Xeque-mate!", "nl": "Schaakmat!", "ru": "Мат!", "ja": "チェックメイト！", "zh": "将死！"],
        "mate_success_msg": ["de": "Gut gemacht! Du hast den Bot mattgesetzt.", "en": "Well done! You checkmated the bot.", "es": "¡Bien hecho! Diste mate al bot.", "fr": "Bien joué ! Vous avez maté le bot.", "it": "Ben fatto! Hai dato scacco matto al bot.", "pt": "Muito bem! Deste mate ao bot.", "nl": "Goed gedaan! Je hebt de bot mat gezet.", "ru": "Отлично! Вы поставили мат боту.", "ja": "お見事！ボットを詰ませました。", "zh": "做得好！你将死了机器人。"],

        // Coordinate Learning Screen
        "coord_title": ["de": "Felder lernen", "en": "Coordinate Trainer", "es": "Entrenar casillas", "fr": "Entraîneur de cases", "it": "Allenatore di caselle", "pt": "Treino de casas", "nl": "Coördinatentrainer", "ru": "Тренажёр координат", "ja": "座標トレーナー", "zh": "坐标训练"],
        "coord_desc": ["de": "Verbessere deine Brett-Visualisierung", "en": "Improve your board visualization", "es": "Mejora tu visualización del tablero", "fr": "Améliorez votre visualisation de l'échiquier", "it": "Migliora la visualizzazione della scacchiera", "pt": "Melhora a tua visualização do tabuleiro", "nl": "Verbeter je bordvisualisatie", "ru": "Улучшайте визуализацию доски", "ja": "盤面の視覚化を鍛えよう", "zh": "提升你的棋盘视觉化能力"],
        "high_scores": ["de": "Deine Highscores", "en": "Your High Scores", "es": "Tus récords", "fr": "Vos meilleurs scores", "it": "I tuoi record", "pt": "Os teus recordes", "nl": "Jouw topscores", "ru": "Ваши рекорды", "ja": "ハイスコア", "zh": "你的最高分"],
        "labeled": ["de": "Mit Beschriftung", "en": "With Labels", "es": "Con etiquetas", "fr": "Avec repères", "it": "Con etichette", "pt": "Com rótulos", "nl": "Met labels", "ru": "С подписями", "ja": "ラベルあり", "zh": "带标注"],
        "unlabeled": ["de": "Ohne Beschriftung", "en": "Without Labels", "es": "Sin etiquetas", "fr": "Sans repères", "it": "Senza etichette", "pt": "Sem rótulos", "nl": "Zonder labels", "ru": "Без подписей", "ja": "ラベルなし", "zh": "无标注"],
        "select_mode": ["de": "Spielmodus wählen", "en": "Select Game Mode", "es": "Selecciona el modo", "fr": "Choisir le mode de jeu", "it": "Seleziona modalità", "pt": "Selecionar modo de jogo", "nl": "Kies spelmodus", "ru": "Выбор режима игры", "ja": "ゲームモードを選択", "zh": "选择游戏模式"],
        "start_rated": ["de": "Rated-Modus starten", "en": "Start Rated Mode", "es": "Iniciar modo puntuado", "fr": "Démarrer le mode classé", "it": "Avvia modalità classificata", "pt": "Iniciar modo classificado", "nl": "Rated-modus starten", "ru": "Запустить рейтинговый режим", "ja": "レート戦を開始", "zh": "开始计分模式"],
        "rated_desc": ["de": "Erspiele dir unter Zeitdruck ein hohes ELO-Rating. Schnelle Antworten geben Speed-Bonus-Elo. Falsche Antworten ziehen Elo ab.", "en": "Gain a high ELO rating under time pressure. Fast answers give speed bonus Elo. Wrong answers deduct Elo.", "es": "Consigue un ELO alto bajo presión de tiempo. Las respuestas rápidas dan Elo extra. Las incorrectas restan Elo.", "fr": "Obtenez un ELO élevé sous pression du temps. Les réponses rapides donnent un bonus d'Elo. Les erreurs retirent de l'Elo.", "it": "Ottieni un ELO alto sotto pressione. Le risposte veloci danno Elo bonus. Quelle sbagliate tolgono Elo.", "pt": "Consegue um ELO alto sob pressão de tempo. Respostas rápidas dão Elo bónus. Erradas tiram Elo.", "nl": "Verdien een hoge ELO onder tijdsdruk. Snelle antwoorden geven bonus-Elo. Foute antwoorden kosten Elo.", "ru": "Набирайте высокий ELO под давлением времени. Быстрые ответы дают бонус, неверные снижают Elo.", "ja": "時間制限の中で高いEloを目指そう。速答でボーナスElo、誤答でElo減少。", "zh": "在时间压力下获得高 ELO。快速作答获得加速奖励 Elo，答错则扣 Elo。"],
        "start_endless": ["de": "Endless-Modus starten", "en": "Start Endless Mode", "es": "Iniciar modo sin fin", "fr": "Démarrer le mode infini", "it": "Avvia modalità infinita", "pt": "Iniciar modo infinito", "nl": "Endless-modus starten", "ru": "Запустить бесконечный режим", "ja": "エンドレスモードを開始", "zh": "开始无尽模式"],
        "endless_desc": ["de": "Übe ohne Zeitlimit, aber jeder Fehler beendet das Spiel sofort. Dein Score wird aus der Anzahl korrekter Felder und deiner Durchschnittsgeschwindigkeit berechnet.", "en": "Practice without time limit, but any mistake ends the game immediately. Your score is based on correct squares and average speed.", "es": "Practica sin límite de tiempo, pero cualquier error termina el juego. Tu puntuación se basa en casillas correctas y velocidad media.", "fr": "Entraînez-vous sans limite de temps, mais toute erreur termine la partie. Votre score dépend des cases correctes et de la vitesse moyenne.", "it": "Allenati senza limite di tempo, ma ogni errore termina il gioco. Il punteggio si basa sulle caselle corrette e sulla velocità media.", "pt": "Pratica sem limite de tempo, mas qualquer erro termina o jogo. A pontuação baseia-se nas casas corretas e na velocidade média.", "nl": "Oefen zonder tijdslimiet, maar elke fout beëindigt het spel. Je score is gebaseerd op juiste velden en gemiddelde snelheid.", "ru": "Тренируйтесь без ограничения времени, но любая ошибка завершает игру. Счёт зависит от верных полей и средней скорости.", "ja": "時間無制限で練習できますが、ミスすると即終了。スコアは正解数と平均速度で決まります。", "zh": "无时间限制练习，但任何错误都会立即结束。分数取决于正确格数和平均速度。"],
        "pts": ["de": "Pkt.", "en": "Pts.", "es": "Pts.", "fr": "Pts", "it": "Pti", "pt": "Pts", "nl": "Ptn", "ru": "очк.", "ja": "点", "zh": "分"],
        "average": ["de": "Schnitt", "en": "Average", "es": "Media", "fr": "Moyenne", "it": "Media", "pt": "Média", "nl": "Gemiddeld", "ru": "Среднее", "ja": "平均", "zh": "平均"],
        "abort": ["de": "Abbrechen", "en": "Abort", "es": "Abandonar", "fr": "Abandonner", "it": "Interrompi", "pt": "Abortar", "nl": "Afbreken", "ru": "Прервать", "ja": "中止", "zh": "中止"],
        "squares": ["de": "Felder", "en": "Squares", "es": "Casillas", "fr": "Cases", "it": "Caselle", "pt": "Casas", "nl": "Velden", "ru": "Поля", "ja": "マス", "zh": "格子"],
        "find_square": ["de": "Finde das Feld:", "en": "Find the square:", "es": "Encuentra la casilla:", "fr": "Trouvez la case :", "it": "Trova la casella:", "pt": "Encontra a casa:", "nl": "Vind het veld:", "ru": "Найдите поле:", "ja": "マスを探せ：", "zh": "找到格子："],
        "game_finished": ["de": "Spiel beendet!", "en": "Game Finished!", "es": "¡Juego terminado!", "fr": "Partie terminée !", "it": "Gioco finito!", "pt": "Jogo terminado!", "nl": "Spel afgelopen!", "ru": "Игра окончена!", "ja": "ゲーム終了！", "zh": "游戏结束！"],
        "new_high_score": ["de": "NEUER HIGHSCORE!", "en": "NEW HIGH SCORE!", "es": "¡NUEVO RÉCORD!", "fr": "NOUVEAU RECORD !", "it": "NUOVO RECORD!", "pt": "NOVO RECORDE!", "nl": "NIEUWE TOPSCORE!", "ru": "НОВЫЙ РЕКОРД!", "ja": "ハイスコア更新！", "zh": "新纪录！"],
        "achieved_rating": ["de": "Erreichtes Rating", "en": "Achieved Rating", "es": "Rating alcanzado", "fr": "Classement atteint", "it": "Rating raggiunto", "pt": "Rating alcançado", "nl": "Behaalde rating", "ru": "Достигнутый рейтинг", "ja": "達成レーティング", "zh": "达到的评分"],
        "correct_squares": ["de": "Richtige Felder", "en": "Correct Squares", "es": "Casillas correctas", "fr": "Cases correctes", "it": "Caselle corrette", "pt": "Casas corretas", "nl": "Juiste velden", "ru": "Верные поля", "ja": "正解のマス", "zh": "正确格数"],
        "incorrect_squares": ["de": "Falsche Felder", "en": "Incorrect Squares", "es": "Casillas incorrectas", "fr": "Cases incorrectes", "it": "Caselle errate", "pt": "Casas incorretas", "nl": "Foute velden", "ru": "Неверные поля", "ja": "不正解のマス", "zh": "错误格数"],
        "endless_score": ["de": "Endless-Score", "en": "Endless Score", "es": "Puntuación sin fin", "fr": "Score infini", "it": "Punteggio infinito", "pt": "Pontuação infinita", "nl": "Endless-score", "ru": "Счёт бесконечного режима", "ja": "エンドレススコア", "zh": "无尽模式分数"],
        "play_again": ["de": "Nochmal spielen", "en": "Play Again", "es": "Jugar otra vez", "fr": "Rejouer", "it": "Gioca ancora", "pt": "Jogar de novo", "nl": "Opnieuw spelen", "ru": "Играть снова", "ja": "もう一度プレイ", "zh": "再来一局"],
        "main_menu": ["de": "Zum Hauptmenü", "en": "To Main Menu", "es": "Al menú principal", "fr": "Menu principal", "it": "Al menu principale", "pt": "Ao menu principal", "nl": "Naar hoofdmenu", "ru": "В главное меню", "ja": "メインメニューへ", "zh": "返回主菜单"],

        // Miscellaneous
        "game_settings": ["de": "Spiel-Einstellungen", "en": "Game Settings", "es": "Ajustes de juego", "fr": "Réglages de jeu", "it": "Impostazioni di gioco", "pt": "Definições de jogo", "nl": "Spelinstellingen", "ru": "Настройки игры", "ja": "ゲーム設定", "zh": "游戏设置"],
        "haptic_feedback": ["de": "Haptisches Feedback", "en": "Haptic Feedback", "es": "Respuesta háptica", "fr": "Retour haptique", "it": "Feedback aptico", "pt": "Feedback tátil", "nl": "Haptische feedback", "ru": "Тактильная отдача", "ja": "触覚フィードバック", "zh": "触觉反馈"],
        "screen_shake": ["de": "Bildschirmschütteln bei Zug", "en": "Screen Shake on Move", "es": "Vibración de pantalla al mover", "fr": "Secousse d'écran au coup", "it": "Vibrazione dello schermo alla mossa", "pt": "Tremer o ecrã ao jogar", "nl": "Schermschudden bij zet", "ru": "Тряска экрана при ходе", "ja": "着手時に画面を揺らす", "zh": "走子时晃动屏幕"],
        "increment_seconds": ["de": "Bonuszeit (Sekunden)", "en": "Bonus Time (Seconds)", "es": "Tiempo extra (segundos)", "fr": "Temps bonus (secondes)", "it": "Tempo bonus (secondi)", "pt": "Tempo bónus (segundos)", "nl": "Bonustijd (seconden)", "ru": "Добавка (секунды)", "ja": "加算時間（秒）", "zh": "加秒（秒）"],
        "bot_name_label": ["de": "Gegner-Name", "en": "Opponent Name", "es": "Nombre del rival", "fr": "Nom de l'adversaire", "it": "Nome avversario", "pt": "Nome do adversário", "nl": "Naam tegenstander", "ru": "Имя соперника", "ja": "対戦相手の名前", "zh": "对手名称"],
        "step_num": ["de": "Zug %d", "en": "Move %d", "es": "Jugada %d", "fr": "Coup %d", "it": "Mossa %d", "pt": "Lance %d", "nl": "Zet %d", "ru": "Ход %d", "ja": "%d手目", "zh": "第 %d 步"],
        "mate_in": ["de": "Matt in %@", "en": "Mate in %@", "es": "Mate en %@", "fr": "Mat en %@", "it": "Matto in %@", "pt": "Mate em %@", "nl": "Mat in %@", "ru": "Мат в %@", "ja": "%@手詰み", "zh": "%@ 步将杀"],
        "more_moves_than_needed": ["de": "%d mehr Züge als nötig", "en": "%d more moves than needed", "es": "%d jugadas más de las necesarias", "fr": "%d coups de plus que nécessaire", "it": "%d mosse in più del necessario", "pt": "%d lances a mais que o necessário", "nl": "%d zetten meer dan nodig", "ru": "на %d ходов больше, чем нужно", "ja": "最短より%d手多い", "zh": "比最短多 %d 步"],

        // Onboarding
        "onboarding_welcome": ["de": "Willkommen bei\nCherry Chess", "en": "Welcome to\nCherry Chess", "es": "Bienvenido a\nCherry Chess", "fr": "Bienvenue sur\nCherry Chess", "it": "Benvenuto su\nCherry Chess", "pt": "Bem-vindo ao\nCherry Chess", "nl": "Welkom bij\nCherry Chess", "ru": "Добро пожаловать в\nCherry Chess", "ja": "Cherry Chess へ\nようこそ", "zh": "欢迎来到\nCherry Chess"],
        "onboarding_subtitle": ["de": "Lass uns dein Profil einrichten. Dein Name erscheint während des Spiels.", "en": "Let's set up your profile. Your name is shown during games.", "es": "Configuremos tu perfil. Tu nombre aparece durante las partidas.", "fr": "Configurons votre profil. Votre nom s'affiche pendant les parties.", "it": "Configuriamo il tuo profilo. Il tuo nome appare durante le partite.", "pt": "Vamos configurar o teu perfil. O teu nome aparece durante os jogos.", "nl": "Laten we je profiel instellen. Je naam verschijnt tijdens partijen.", "ru": "Настроим ваш профиль. Ваше имя отображается во время партий.", "ja": "プロフィールを設定しましょう。名前は対局中に表示されます。", "zh": "来设置你的个人资料吧。你的名字会在对局中显示。"],
        "onboarding_name_title": ["de": "Dein Name", "en": "Your Name", "es": "Tu nombre", "fr": "Votre nom", "it": "Il tuo nome", "pt": "O teu nome", "nl": "Je naam", "ru": "Ваше имя", "ja": "あなたの名前", "zh": "你的名字"],
        "onboarding_name_placeholder": ["de": "Name eingeben", "en": "Enter your name", "es": "Introduce tu nombre", "fr": "Saisissez votre nom", "it": "Inserisci il nome", "pt": "Introduz o teu nome", "nl": "Voer je naam in", "ru": "Введите имя", "ja": "名前を入力", "zh": "输入名字"],
        "onboarding_elo_title": ["de": "Deine Chess.com-Wertung", "en": "Your Chess.com Rating", "es": "Tu rating de Chess.com", "fr": "Votre classement Chess.com", "it": "Il tuo rating Chess.com", "pt": "O teu rating de Chess.com", "nl": "Je Chess.com-rating", "ru": "Ваш рейтинг Chess.com", "ja": "あなたのChess.comレーティング", "zh": "你的 Chess.com 评分"],
        "onboarding_elo_unknown": ["de": "Ich kenne meine Wertung nicht", "en": "I don't know my rating", "es": "No conozco mi rating", "fr": "Je ne connais pas mon classement", "it": "Non conosco il mio rating", "pt": "Não sei o meu rating", "nl": "Ik ken mijn rating niet", "ru": "Я не знаю свой рейтинг", "ja": "レーティングがわからない", "zh": "我不知道我的评分"],
        "onboarding_continue": ["de": "Los geht's", "en": "Get Started", "es": "Empezar", "fr": "Commencer", "it": "Inizia", "pt": "Começar", "nl": "Beginnen", "ru": "Начать", "ja": "はじめる", "zh": "开始"],

        // Profile Tab
        "profile": ["de": "Profil", "en": "Profile", "es": "Perfil", "fr": "Profil", "it": "Profilo", "pt": "Perfil", "nl": "Profiel", "ru": "Профиль", "ja": "プロフィール", "zh": "个人资料"],
        "profile_subtitle": ["de": "Deine Statistiken, Wertung und Fortschritt.", "en": "Your stats, rating and progress.", "es": "Tus estadísticas, rating y progreso.", "fr": "Vos statistiques, votre classement et vos progrès.", "it": "Le tue statistiche, il rating e i progressi.", "pt": "As tuas estatísticas, rating e progresso.", "nl": "Je statistieken, rating en voortgang.", "ru": "Ваша статистика, рейтинг и прогресс.", "ja": "統計、レーティング、進捗。", "zh": "你的统计、评分与进度。"],
        "profile_avg_rating": ["de": "Ø Rating", "en": "Avg Rating", "es": "Rating medio", "fr": "Classement moyen", "it": "Rating medio", "pt": "Rating médio", "nl": "Gem. rating", "ru": "Средний рейтинг", "ja": "平均レート", "zh": "平均评分"],
        "profile_avg_accuracy": ["de": "Ø Genauigkeit", "en": "Avg Accuracy", "es": "Precisión media", "fr": "Précision moyenne", "it": "Precisione media", "pt": "Precisão média", "nl": "Gem. nauwkeurigheid", "ru": "Средняя точность", "ja": "平均正確性", "zh": "平均准确率"],
        "profile_games_played": ["de": "Challenge-Spiele", "en": "Challenge Games", "es": "Partidas Challenge", "fr": "Parties Challenge", "it": "Partite Challenge", "pt": "Jogos Challenge", "nl": "Challenge-partijen", "ru": "Игры Challenge", "ja": "チャレンジ対局", "zh": "挑战对局"],
        "profile_rating_trend": ["de": "Rating-Verlauf", "en": "Rating Over Time", "es": "Rating a lo largo del tiempo", "fr": "Évolution du classement", "it": "Andamento del rating", "pt": "Rating ao longo do tempo", "nl": "Rating in de tijd", "ru": "Динамика рейтинга", "ja": "レーティング推移", "zh": "评分走势"],
        "profile_accuracy_trend": ["de": "Genauigkeits-Verlauf", "en": "Accuracy Over Time", "es": "Precisión a lo largo del tiempo", "fr": "Évolution de la précision", "it": "Andamento della precisione", "pt": "Precisão ao longo do tempo", "nl": "Nauwkeurigheid in de tijd", "ru": "Динамика точности", "ja": "正確性の推移", "zh": "准确率走势"],
        "profile_no_stats": ["de": "Noch keine Statistiken", "en": "No stats yet", "es": "Aún no hay estadísticas", "fr": "Pas encore de statistiques", "it": "Ancora nessuna statistica", "pt": "Ainda sem estatísticas", "nl": "Nog geen statistieken", "ru": "Пока нет статистики", "ja": "統計はまだありません", "zh": "暂无统计"],
        "profile_no_stats_desc": ["de": "Spiele ein Challenge-Spiel, um deine Wertung und Genauigkeit aufzubauen.", "en": "Play a Challenge game to build your rating and accuracy.", "es": "Juega una partida Challenge para construir tu rating y precisión.", "fr": "Jouez une partie Challenge pour construire votre classement et votre précision.", "it": "Gioca una partita Challenge per costruire rating e precisione.", "pt": "Joga uma partida Challenge para construir o teu rating e precisão.", "nl": "Speel een Challenge-partij om je rating en nauwkeurigheid op te bouwen.", "ru": "Сыграйте партию Challenge, чтобы набрать рейтинг и точность.", "ja": "チャレンジ対局でレーティングと正確性を積み上げよう。", "zh": "进行一局挑战赛来积累你的评分与准确率。"],
        "profile_elo_unknown": ["de": "Unbekannt", "en": "Unknown", "es": "Desconocido", "fr": "Inconnu", "it": "Sconosciuto", "pt": "Desconhecido", "nl": "Onbekend", "ru": "Неизвестно", "ja": "不明", "zh": "未知"],
        "your_profile": ["de": "Dein Profil", "en": "Your Profile", "es": "Tu perfil", "fr": "Votre profil", "it": "Il tuo profilo", "pt": "O teu perfil", "nl": "Je profiel", "ru": "Ваш профиль", "ja": "あなたのプロフィール", "zh": "你的个人资料"],
        "chesscom_rating": ["de": "Chess.com-Wertung", "en": "Chess.com Rating", "es": "Rating de Chess.com", "fr": "Classement Chess.com", "it": "Rating Chess.com", "pt": "Rating de Chess.com", "nl": "Chess.com-rating", "ru": "Рейтинг Chess.com", "ja": "Chess.comレーティング", "zh": "Chess.com 评分"],

        // Challenge Mode
        "challenge_mode": ["de": "Challenge", "en": "Challenge", "es": "Challenge", "fr": "Challenge", "it": "Challenge", "pt": "Challenge", "nl": "Challenge", "ru": "Challenge", "ja": "チャレンジ", "zh": "挑战"],
        "challenge_mode_desc": ["de": "Spiel ohne Hilfen – keine Bewertungsleiste, kein Elo, keine Zug-Analyse. Baut deine echte Wertung & Genauigkeit auf.", "en": "Play with no assistance – no eval bar, no Elo, no move analysis. Builds your real rating & accuracy.", "es": "Juega sin ayudas: sin barra de evaluación, sin Elo, sin análisis. Construye tu rating y precisión reales.", "fr": "Jouez sans aide : pas de barre d'évaluation, pas d'Elo, pas d'analyse. Construit votre vrai classement et votre précision.", "it": "Gioca senza aiuti: niente barra di valutazione, niente Elo, niente analisi. Costruisce il tuo vero rating e precisione.", "pt": "Joga sem ajudas – sem barra de avaliação, sem Elo, sem análise. Constrói o teu rating e precisão reais.", "nl": "Speel zonder hulp – geen evaluatiebalk, geen Elo, geen zetanalyse. Bouwt je echte rating & nauwkeurigheid op.", "ru": "Играйте без помощи — без шкалы оценки, без Elo, без анализа. Формирует ваш настоящий рейтинг и точность.", "ja": "補助なしで対局 — 評価バー・Elo・着手解析なし。本当の実力と正確性を積み上げます。", "zh": "无任何辅助对弈——无评估条、无 Elo、无着法分析。积累你真实的评分与准确率。"],
        "challenge_assist_locked": ["de": "Im Challenge-Modus sind alle Hilfen deaktiviert.", "en": "All assistance is disabled in Challenge mode.", "es": "Todas las ayudas están desactivadas en el modo Challenge.", "fr": "Toutes les aides sont désactivées en mode Challenge.", "it": "Tutti gli aiuti sono disattivati nella modalità Challenge.", "pt": "Todas as ajudas estão desativadas no modo Challenge.", "nl": "Alle hulp is uitgeschakeld in de Challenge-modus.", "ru": "В режиме Challenge все подсказки отключены.", "ja": "チャレンジモードではすべての補助が無効です。", "zh": "挑战模式下所有辅助均已禁用。"],
        "normal_game": ["de": "Normal", "en": "Normal", "es": "Normal", "fr": "Normal", "it": "Normale", "pt": "Normal", "nl": "Normaal", "ru": "Обычный", "ja": "通常", "zh": "普通"],
    ]
}
