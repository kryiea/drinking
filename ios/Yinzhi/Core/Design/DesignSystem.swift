import SwiftUI
import UIKit

enum AppTheme {
    static let backgroundTop = dynamicColor(
        light: UIColor(red: 0.96, green: 0.99, blue: 0.97, alpha: 1),
        dark: UIColor(red: 0.06, green: 0.08, blue: 0.09, alpha: 1)
    )
    static let backgroundBottom = dynamicColor(
        light: UIColor(red: 0.88, green: 0.95, blue: 0.92, alpha: 1),
        dark: UIColor(red: 0.08, green: 0.12, blue: 0.12, alpha: 1)
    )
    static let accent = dynamicColor(
        light: UIColor(red: 0.08, green: 0.50, blue: 0.38, alpha: 1),
        dark: UIColor(red: 0.29, green: 0.74, blue: 0.61, alpha: 1)
    )
    static let accentSoft = dynamicColor(
        light: UIColor(red: 0.59, green: 0.82, blue: 0.72, alpha: 1),
        dark: UIColor(red: 0.18, green: 0.36, blue: 0.31, alpha: 1)
    )
    static let cardTint = dynamicColor(
        light: UIColor.white.withAlphaComponent(0.12),
        dark: UIColor.white.withAlphaComponent(0.11)
    )
    static let ink = dynamicColor(
        light: UIColor(red: 0.10, green: 0.17, blue: 0.15, alpha: 1),
        dark: UIColor(red: 0.94, green: 0.97, blue: 0.95, alpha: 1)
    )
    static let elevatedSurface = dynamicColor(
        light: UIColor.white.withAlphaComponent(0.88),
        dark: UIColor(red: 0.12, green: 0.16, blue: 0.17, alpha: 0.95)
    )
    static let panelSurface = dynamicColor(
        light: UIColor.white.withAlphaComponent(0.78),
        dark: UIColor(red: 0.13, green: 0.18, blue: 0.19, alpha: 0.92)
    )
    static let glassStroke = dynamicColor(
        light: UIColor.white.withAlphaComponent(0.35),
        dark: UIColor.white.withAlphaComponent(0.16)
    )
    static let outline = dynamicColor(
        light: UIColor.white.withAlphaComponent(0.70),
        dark: UIColor.white.withAlphaComponent(0.18)
    )
    static let softFill = dynamicColor(
        light: UIColor.black.withAlphaComponent(0.05),
        dark: UIColor.white.withAlphaComponent(0.10)
    )
    static let ambientCloud = dynamicColor(
        light: UIColor.white.withAlphaComponent(0.48),
        dark: UIColor.white.withAlphaComponent(0.06)
    )
    static let chartSurface = dynamicColor(
        light: UIColor.white.withAlphaComponent(0.30),
        dark: UIColor.white.withAlphaComponent(0.10)
    )
    static let chartRule = dynamicColor(
        light: UIColor.white.withAlphaComponent(0.45),
        dark: UIColor.white.withAlphaComponent(0.18)
    )
    static let shadow = dynamicColor(
        light: UIColor.black.withAlphaComponent(0.08),
        dark: UIColor.black.withAlphaComponent(0.32)
    )

    static let pageBackground = LinearGradient(
        colors: [backgroundTop, backgroundBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
        Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark ? dark : light
            }
        )
    }
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
                        .stroke(AppTheme.glassStroke, lineWidth: 1)
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
