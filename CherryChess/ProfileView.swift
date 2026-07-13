import SwiftUI

struct ProfileView: View {
    var isActive: Bool = true
    @ObservedObject var store = GameHistoryStore.shared
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("appTheme") private var appTheme = "cherry"
    @AppStorage("playerName") private var playerName = ""
    @AppStorage("playerChessComElo") private var playerChessComElo = 0

    @State private var scrollOffset: CGFloat = 0
    @State private var showingSettings = false

    private var isIPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    private var displayName: String {
        let trimmed = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L10n.tr("user_player") : trimmed
    }

    var body: some View {
        let _ = appLanguage
        let _ = appTheme
        let challengeGames = store.challengeGamesChronological
        ZStack(alignment: .top) {
            Theme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if isActive {
                        ScrollOffsetDetector(coordinateSpace: "profileContainer")
                    }

                    Spacer().frame(height: isIPad ? 224 : 216)

                    profileCard

                    statsRow(challengeGames: challengeGames)

                    if challengeGames.isEmpty {
                        emptyStats
                    } else {
                        // Rating trend
                        trendSection(
                            title: L10n.tr("profile_rating_trend"),
                            icon: "chart.line.uptrend.xyaxis",
                            values: challengeGames.map { Double($0.finalElo) },
                            color: Theme.accentColor,
                            format: { String(Int($0.rounded())) }
                        )

                        // Accuracy trend
                        trendSection(
                            title: L10n.tr("profile_accuracy_trend"),
                            icon: "target",
                            values: challengeGames.map { $0.accuracy },
                            color: Theme.accentColor,
                            fixedRange: 0...100,
                            format: { String(format: "%.0f%%", $0) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }

            // Collapsible Header
            VStack(spacing: 0) {
                Color.clear.frame(height: 0)
                CollapsibleHeaderView(
                    title: L10n.tr("profile"),
                    subtitle: L10n.tr("profile_subtitle"),
                    iconName: "person.crop.circle.fill",
                    scrollOffset: scrollOffset
                )
            }
            .background(
                Theme.background
                    .opacity(scrollOffset < -5 ? 1.0 : 0.0)
                    .ignoresSafeArea(edges: .top)
            )
            .animation(.easeInOut(duration: 0.15), value: scrollOffset < -5)

            // Floating settings (gear) button, top-right
            HStack {
                Spacer()
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: isIPad ? 20 : 17, weight: .bold))
                        .foregroundColor(Theme.textMain)
                        .frame(width: isIPad ? 48 : 42, height: isIPad ? 48 : 42)
                        .background(Theme.panelBackground)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Theme.line.opacity(0.08), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, isIPad ? 24 : 16)
            .padding(.top, isIPad ? 16 : 8)
        }
        .coordinateSpace(name: "profileContainer")
        .onPreferenceChange(TaggedScrollOffsetPreferenceKey.self) { values in
            if let val = values["profileContainer"] {
                self.scrollOffset = val
            }
        }
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView(onClose: { showingSettings = false })
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Profile card

    private var profileCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.accentColor.opacity(0.18))
                    .frame(width: isIPad ? 76 : 64, height: isIPad ? 76 : 64)
                Text(String(displayName.prefix(1)).uppercased())
                    .font(.system(size: isIPad ? 34 : 28, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.accentColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(displayName)
                    .font(.system(size: isIPad ? 26 : 22, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textMain)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 6) {
                    Image(systemName: "globe")
                        .font(.caption)
                    if playerChessComElo > 0 {
                        Text("Chess.com · \(playerChessComElo)")
                    } else {
                        Text("Chess.com · \(L10n.tr("profile_elo_unknown"))")
                    }
                }
                .font(.roundedSystem(.subheadline, weight: .bold))
                .foregroundColor(Theme.textSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Theme.panelBackground)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Theme.line.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Stats row

    private func statsRow(challengeGames: [SavedGame]) -> some View {
        HStack(spacing: 12) {
            statTile(
                label: L10n.tr("profile_avg_rating"),
                value: store.averageChallengeRating.map { "\($0)" } ?? "—",
                icon: "rosette",
                color: Theme.accentColor
            )
            statTile(
                label: L10n.tr("profile_avg_accuracy"),
                value: store.averageChallengeAccuracy.map { String(format: "%.0f%%", $0) } ?? "—",
                icon: "target",
                color: Theme.accentColor
            )
            statTile(
                label: L10n.tr("profile_games_played"),
                value: "\(challengeGames.count)",
                icon: "flag.checkered",
                color: Theme.accentColor
            )
        }
    }

    private func statTile(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: isIPad ? 22 : 18, weight: .bold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: isIPad ? 26 : 22, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textMain)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.roundedSystem(.caption, weight: .bold))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(minHeight: 28, alignment: .top)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Theme.panelBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.line.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Trend section

    private func trendSection(title: String, icon: String, values: [Double], color: Color, fixedRange: ClosedRange<Double>? = nil, format: @escaping (Double) -> String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.roundedSystem(.headline, weight: .bold))
                    .foregroundColor(Theme.textMain)
                Spacer()
                if let last = values.last {
                    Text(format(last))
                        .font(.roundedSystem(.subheadline, weight: .bold))
                        .foregroundColor(color)
                }
            }
            LineTrendChart(values: values, color: color, fixedRange: fixedRange, format: format)
                .frame(height: isIPad ? 180 : 150)
        }
        .padding(16)
        .background(Theme.panelBackground)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Theme.line.opacity(0.06), lineWidth: 1)
        )
    }

    private var emptyStats: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 44))
                .foregroundColor(Theme.textSecondary.opacity(0.3))
            Text(L10n.tr("profile_no_stats"))
                .font(.roundedSystem(.headline))
                .foregroundColor(Theme.textSecondary)
            Text(L10n.tr("profile_no_stats_desc"))
                .font(.roundedSystem(.subheadline))
                .foregroundColor(Theme.textSecondary.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 16)
    }
}

// MARK: - Line trend chart

/// A compact line chart plotting a chronological series of values, with an area
/// gradient fill, point markers, and min/max axis labels.
struct LineTrendChart: View {
    let values: [Double]
    let color: Color
    var fixedRange: ClosedRange<Double>? = nil
    let format: (Double) -> String

    private var yRange: (min: Double, max: Double) {
        if let f = fixedRange { return (f.lowerBound, f.upperBound) }
        guard let mn = values.min(), let mx = values.max() else { return (0, 1) }
        if mn == mx {
            let pad = max(abs(mn) * 0.1, 10)
            return (mn - pad, mx + pad)
        }
        let pad = (mx - mn) * 0.15
        return (mn - pad, mx + pad)
    }

    private func point(at i: Int, width: CGFloat, height: CGFloat, range: (min: Double, max: Double), span: Double, labelWidth: CGFloat, chartW: CGFloat) -> CGPoint {
        let n = max(1, values.count - 1)
        let x = labelWidth + (values.count == 1 ? chartW / 2 : chartW * CGFloat(i) / CGFloat(n))
        let norm = (values[i] - range.min) / span
        let y = height - CGFloat(norm) * height
        return CGPoint(x: x, y: y)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let labelWidth: CGFloat = 40
            let chartW = max(1, w - labelWidth)
            let range = yRange
            let span = max(0.0001, range.max - range.min)

            ZStack(alignment: .topLeading) {
                // Grid lines + axis labels
                ForEach(0..<3) { idx in
                    let frac = CGFloat(idx) / 2.0
                    let y = frac * h
                    let val = range.max - Double(frac) * span
                    Path { p in
                        p.move(to: CGPoint(x: labelWidth, y: y))
                        p.addLine(to: CGPoint(x: w, y: y))
                    }
                    .stroke(Theme.line.opacity(0.06), lineWidth: 1)

                    Text(format(val))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textSecondary.opacity(0.7))
                        .frame(width: labelWidth - 4, alignment: .trailing)
                        .position(x: (labelWidth - 4) / 2, y: min(max(y, 6), h - 6))
                }

                if values.count >= 2 {
                    // Area fill
                    Path { p in
                        let startPt = point(at: 0, width: w, height: h, range: range, span: span, labelWidth: labelWidth, chartW: chartW)
                        p.move(to: CGPoint(x: startPt.x, y: h))
                        for i in values.indices {
                            p.addLine(to: point(at: i, width: w, height: h, range: range, span: span, labelWidth: labelWidth, chartW: chartW))
                        }
                        let endPt = point(at: values.count - 1, width: w, height: h, range: range, span: span, labelWidth: labelWidth, chartW: chartW)
                        p.addLine(to: CGPoint(x: endPt.x, y: h))
                        p.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.28), color.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Line
                    Path { p in
                        p.move(to: point(at: 0, width: w, height: h, range: range, span: span, labelWidth: labelWidth, chartW: chartW))
                        for i in values.indices {
                            p.addLine(to: point(at: i, width: w, height: h, range: range, span: span, labelWidth: labelWidth, chartW: chartW))
                        }
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                }

                // Points (only draw markers when the series is small enough to stay readable)
                if values.count <= 30 {
                    ForEach(values.indices, id: \.self) { i in
                        Circle()
                            .fill(Theme.background)
                            .frame(width: 7, height: 7)
                            .overlay(Circle().stroke(color, lineWidth: 2))
                            .position(point(at: i, width: w, height: h, range: range, span: span, labelWidth: labelWidth, chartW: chartW))
                    }
                } else if let li = values.indices.last {
                    Circle()
                        .fill(Theme.background)
                        .frame(width: 7, height: 7)
                        .overlay(Circle().stroke(color, lineWidth: 2))
                        .position(point(at: li, width: w, height: h, range: range, span: span, labelWidth: labelWidth, chartW: chartW))
                }
            }
        }
    }
}
