import SwiftUI

enum AppTheme {
    static let backgroundTop = Color(red: 0.96, green: 0.99, blue: 0.97)
    static let backgroundBottom = Color(red: 0.88, green: 0.95, blue: 0.92)
    static let accent = Color(red: 0.08, green: 0.50, blue: 0.38)
    static let accentSoft = Color(red: 0.59, green: 0.82, blue: 0.72)
    static let cardTint = Color.white.opacity(0.12)
    static let ink = Color(red: 0.10, green: 0.17, blue: 0.15)

    static let pageBackground = LinearGradient(
        colors: [backgroundTop, backgroundBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct AdaptiveGlassCardModifier: ViewModifier {
    var tint: Color = AppTheme.cardTint
    var cornerRadius: CGFloat = 28
    var interactive: Bool = false
    var padding: CGFloat = 18

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .padding(padding)
                .glassEffect(.regular.tint(tint).interactive(interactive), in: .rect(cornerRadius: cornerRadius))
        } else {
            content
                .padding(padding)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
        }
    }
}

extension View {
    func adaptiveGlassCard(
        tint: Color = AppTheme.cardTint,
        cornerRadius: CGFloat = 28,
        interactive: Bool = false,
        padding: CGFloat = 18
    ) -> some View {
        modifier(AdaptiveGlassCardModifier(tint: tint, cornerRadius: cornerRadius, interactive: interactive, padding: padding))
    }
}

struct PrimaryCTAStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(AppTheme.accent.opacity(configuration.isPressed ? 0.8 : 1), in: Capsule())
            .shadow(color: AppTheme.accent.opacity(0.24), radius: 18, y: 8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SecondaryGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded, weight: .semibold))
            .foregroundStyle(AppTheme.ink)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .adaptiveGlassCard(
                tint: AppTheme.cardTint.opacity(configuration.isPressed ? 0.16 : 0.1),
                cornerRadius: 999,
                interactive: true,
                padding: 0
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    let content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            content
        }
        .adaptiveGlassCard()
    }
}

struct MetricPill: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .bold))
            Text(value)
                .font(.system(.caption, design: .rounded))
        }
        .foregroundStyle(AppTheme.ink)
        .adaptiveGlassCard(cornerRadius: 18, interactive: false, padding: 10)
    }
}

struct StatusChip: View {
    let label: String
    let systemImage: String
    var tint: Color = AppTheme.cardTint

    var body: some View {
        Label(label, systemImage: systemImage)
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundStyle(AppTheme.ink)
            .adaptiveGlassCard(tint: tint, cornerRadius: 18, interactive: false, padding: 10)
    }
}
