import SwiftUI

/// First-launch onboarding: collects the player's name and (optionally) their
/// Chess.com rating. Shown as a full-screen cover until completed.
struct OnboardingView: View {
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("appTheme") private var appTheme = "cherry"
    @AppStorage("playerName") private var playerName = ""
    @AppStorage("playerChessComElo") private var playerChessComElo = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var name: String = ""
    @State private var eloKnown: Bool = true
    @State private var elo: Double = 800
    @FocusState private var nameFocused: Bool

    private var isIPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    private var canContinue: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        let _ = appLanguage
        let _ = appTheme
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "flag.checkered.2.crossed")
                            .font(.system(size: isIPad ? 64 : 52, weight: .medium))
                            .foregroundStyle(Theme.accentColor)

                        Text(L10n.tr("onboarding_welcome"))
                            .font(.system(size: isIPad ? 34 : 28, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textMain)
                            .multilineTextAlignment(.center)

                        Text(L10n.tr("onboarding_subtitle"))
                            .font(.roundedSystem(.subheadline))
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, isIPad ? 60 : 40)

                    // Name card
                    VStack(alignment: .leading, spacing: 12) {
                        Label(L10n.tr("onboarding_name_title"), systemImage: "person.fill")
                            .font(.roundedSystem(.headline, weight: .bold))
                            .foregroundColor(Theme.textMain)

                        TextField(L10n.tr("onboarding_name_placeholder"), text: $name)
                            .font(.roundedSystem(.body, weight: .bold))
                            .foregroundColor(.white)
                            .focused($nameFocused)
                            .submitLabel(.done)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .background(Color.black.opacity(0.20))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(nameFocused ? Theme.accentColor : Color.white.opacity(0.12), lineWidth: 1.5)
                            )
                    }
                    .padding(16)
                    .background(Theme.panelBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )

                    // Elo card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label(L10n.tr("onboarding_elo_title"), systemImage: "chart.line.uptrend.xyaxis")
                                .font(.roundedSystem(.headline, weight: .bold))
                                .foregroundColor(Theme.textMain)
                            Spacer()
                            if eloKnown {
                                Text("\(Int(elo))")
                                    .font(.roundedSystem(.headline, weight: .bold))
                                    .foregroundColor(Theme.accentColor)
                            }
                        }

                        if eloKnown {
                            Slider(value: $elo, in: 100...3000, step: 10)
                                .tint(Theme.accentColor)
                                .transition(.opacity)
                        }

                        // "I don't know" toggle
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                eloKnown.toggle()
                            }
                            HapticManager.shared.playImpact(.light)
                        }) {
                            HStack {
                                Image(systemName: eloKnown ? "circle" : "checkmark.circle.fill")
                                    .foregroundColor(eloKnown ? Theme.textSecondary : Theme.accentColor)
                                Text(L10n.tr("onboarding_elo_unknown"))
                                    .font(.roundedSystem(.subheadline, weight: .bold))
                                    .foregroundColor(eloKnown ? Theme.textSecondary : Theme.textMain)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .background(eloKnown ? Color.black.opacity(0.15) : Theme.accentColor.opacity(0.12))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(eloKnown ? Color.white.opacity(0.08) : Theme.accentColor, lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(16)
                    .background(Theme.panelBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )

                    // Continue button
                    Button(action: complete) {
                        Text(L10n.tr("onboarding_continue"))
                            .font(.roundedSystem(.headline, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canContinue ? AnyShapeStyle(Theme.primaryGradient) : AnyShapeStyle(Color.gray.opacity(0.3)))
                            .cornerRadius(16)
                            .shadow(color: canContinue ? Color.black.opacity(0.15) : .clear, radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(!canContinue)
                    .padding(.top, 4)
                }
                .padding(.horizontal, isIPad ? 80 : 20)
                .padding(.bottom, 40)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            name = playerName
        }
    }

    private func complete() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        playerName = trimmed
        playerChessComElo = eloKnown ? Int(elo) : 0
        HapticManager.shared.playNotification(.success)
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}
