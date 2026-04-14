import Observation
import SwiftUI

struct HomeView: View {
    @Bindable var environment: AppEnvironment

    private let grid = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroPanel
                metricsGrid
                recommendationRail
                recentSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("今日节奏")
        .toolbarTitleDisplayMode(.large)
    }

    private var heroPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("晚上之前，把节奏握在手里")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                    Text("你好，\(environment.profile.displayName)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Text(heroSummary)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 12)
                VStack(alignment: .trailing, spacing: 8) {
                    FocusBadge(
                        title: focusLabel,
                        detail: "\(environment.dashboard.todayEntries.count) 杯"
                    )
                    FocusBadge(
                        title: environment.pendingSyncCount > 0 ? "待同步" : "已连接",
                        detail: environment.pendingSyncCount > 0 ? "\(environment.pendingSyncCount) 条" : "服务端"
                    )
                }
            }

            statusRow

            if let topCard = environment.dashboard.recommendations.first {
                HStack(spacing: 12) {
                    AccentStatement(
                        title: topCard.title,
                        message: topCard.explanation.action,
                        tint: accentForSeverity(topCard.severity)
                    )
                    RhythmDial(
                        value: min(progressRatio, 1),
                        caption: progressCaption
                    )
                }
            }
        }
        .adaptiveGlassCard(tint: AppTheme.cardTint.opacity(0.18), cornerRadius: 34, interactive: true, padding: 22)
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: grid, spacing: 12) {
            MetricTile(
                title: "咖啡因",
                value: "\(Int(environment.dashboard.aggregate.caffeineMG))mg",
                caption: ratioText(environment.dashboard.aggregate.caffeineMG, environment.dashboard.goals.caffeineLimitMG),
                tint: Color(red: 0.50, green: 0.35, blue: 0.25)
            )
            MetricTile(
                title: "糖分",
                value: "\(Int(environment.dashboard.aggregate.sugarG))g",
                caption: ratioText(environment.dashboard.aggregate.sugarG, environment.dashboard.goals.sugarLimitG),
                tint: Color(red: 0.90, green: 0.53, blue: 0.18)
            )
            MetricTile(
                title: "补水",
                value: "\(Int(environment.dashboard.aggregate.hydrationML))ml",
                caption: ratioText(environment.dashboard.aggregate.hydrationML, environment.dashboard.goals.hydrationGoalML),
                tint: AppTheme.accent
            )
            MetricTile(
                title: "建议",
                value: "\(environment.dashboard.recommendations.count) 条",
                caption: focusLabel,
                tint: AppTheme.accentSoft
            )
        }
    }

    private var recommendationRail: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("建议卡片")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Text("解释优先")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                groupGlassElements {
                    HStack(spacing: 14) {
                        ForEach(environment.dashboard.recommendations) { card in
                            RecommendationCapsule(card: card)
                                .frame(width: 280)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var recentSection: some View {
        SectionCard(title: "最近记录", subtitle: "品牌、类型和今天的最后几次输入") {
            VStack(spacing: 12) {
                ForEach(environment.dashboard.todayEntries.prefix(4)) { entry in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(AppTheme.accentSoft.opacity(0.32))
                            .frame(width: 42, height: 42)
                            .overlay(
                                Image(systemName: entry.preparationMethod?.systemImage ?? "cup.and.saucer")
                                    .foregroundStyle(AppTheme.accent)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(entry.drinkName)
                                    .font(.system(.headline, design: .rounded, weight: .semibold))
                                    .foregroundStyle(AppTheme.ink)
                                if let brand = entry.brand {
                                    Text(brand)
                                        .font(.system(.caption2, design: .rounded, weight: .bold))
                                        .foregroundStyle(AppTheme.accent)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(AppTheme.accentSoft.opacity(0.22), in: Capsule())
                                }
                            }
                            Text("\(entry.category) · \(entry.servingLabel)")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(entry.consumedAt.formatted(date: .omitted, time: .shortened))
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundStyle(AppTheme.ink)
                            if entry.isPendingSync {
                                Text("待同步")
                                    .font(.system(.caption2, design: .rounded, weight: .bold))
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                    }
                }
            }
        }
    }

    private var statusRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            groupGlassElements {
                HStack(spacing: 10) {
                    StatusChip(
                        label: environment.connectionTitle,
                        systemImage: environment.session == nil ? "wifi.slash" : "server.rack"
                    )

                    if environment.pendingSyncCount > 0 {
                        StatusChip(
                            label: "待同步 \(environment.pendingSyncCount)",
                            systemImage: "arrow.triangle.2.circlepath",
                            tint: AppTheme.accentSoft.opacity(0.28)
                        )
                    }

                    StatusChip(
                        label: environment.session == nil ? "预览数据" : "真源已连",
                        systemImage: environment.session == nil ? "eye" : "checkmark.seal"
                    )
                }
            }
        }
    }

    private var heroSummary: String {
        environment.dashboard.recommendations.first?.summary ?? "继续用少量、高频、可解释的记录方式观察今天。"
    }

    private var focusLabel: String {
        let sugarRatio = environment.dashboard.aggregate.sugarG / max(environment.dashboard.goals.sugarLimitG, 1)
        let caffeineRatio = environment.dashboard.aggregate.caffeineMG / max(environment.dashboard.goals.caffeineLimitMG, 1)
        let hydrationRatio = environment.dashboard.aggregate.hydrationML / max(environment.dashboard.goals.hydrationGoalML, 1)

        if sugarRatio >= 1 || caffeineRatio >= 1 {
            return "需要干预"
        }
        if sugarRatio >= 0.8 || caffeineRatio >= 0.8 {
            return "接近阈值"
        }
        if hydrationRatio >= 0.85 {
            return "补水不错"
        }
        return "状态稳定"
    }

    private var progressRatio: Double {
        max(
            environment.dashboard.aggregate.sugarG / max(environment.dashboard.goals.sugarLimitG, 1),
            environment.dashboard.aggregate.caffeineMG / max(environment.dashboard.goals.caffeineLimitMG, 1)
        )
    }

    private var progressCaption: String {
        progressRatio >= 1 ? "高风险" : progressRatio >= 0.8 ? "预警" : "平稳"
    }

    private func accentForSeverity(_ severity: String) -> Color {
        switch severity {
        case "critical":
            return Color(red: 0.84, green: 0.30, blue: 0.24)
        case "warning":
            return Color(red: 0.90, green: 0.53, blue: 0.18)
        default:
            return AppTheme.accent
        }
    }

    private func ratioText(_ value: Double, _ target: Double) -> String {
        "\(Int(value)) / \(Int(target))"
    }

    @ViewBuilder
    private func groupGlassElements<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 12) {
                content()
            }
        } else {
            content()
        }
    }
}

private struct MetricTile: View {
    let title: String
    let value: String
    let caption: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
            Text(caption)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, minHeight: 124, alignment: .leading)
        .adaptiveGlassCard(tint: tint.opacity(0.10), cornerRadius: 28)
    }
}

private struct RecommendationCapsule: View {
    let card: RecommendationCard

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(card.title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Text(card.severity.uppercased())
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            Text(card.summary)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(card.explanation.thresholdComparison)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.accent)
            Text(card.explanation.action)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .adaptiveGlassCard(cornerRadius: 28, interactive: true)
    }
}

private struct AccentStatement: View {
    let title: String
    let message: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)
            Text(message)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct FocusBadge: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(title)
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
            Text(detail)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct RhythmDial: View {
    let value: Double
    let caption: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.55), lineWidth: 10)
            Circle()
                .trim(from: 0, to: value)
                .stroke(
                    AngularGradient(
                        colors: [AppTheme.accent, AppTheme.accentSoft, Color.orange],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                Text("\(Int(value * 100))")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Text(caption)
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 104, height: 104)
    }
}
