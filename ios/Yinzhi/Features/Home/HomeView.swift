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
            VStack(alignment: .leading, spacing: 18) {
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
        VStack(alignment: .leading, spacing: 18) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 16) {
                    heroHeading
                    Spacer(minLength: 12)
                    heroBadges
                }

                VStack(alignment: .leading, spacing: 16) {
                    heroHeading
                    heroBadges
                }
            }

            statusRow

            HStack(alignment: .center, spacing: 12) {
                DecisionSpotlight(
                    eyebrow: "下一步动作",
                    title: topDecisionTitle,
                    message: topDecisionMessage,
                    footnote: topDecisionFootnote,
                    tint: topDecisionTint
                )
                RhythmDial(
                    value: min(progressRatio, 1),
                    caption: progressCaption
                )
            }

            groupGlassElements {
                HStack(spacing: 12) {
                    Button {
                        environment.selectedTab = .log
                    } label: {
                        Label("再记一杯", systemImage: "plus.viewfinder")
                    }
                    .buttonStyle(PrimaryCTAStyle())

                    Button {
                        environment.selectedTab = .insights
                    } label: {
                        Label("看趋势", systemImage: "chart.xyaxis.line")
                    }
                    .buttonStyle(SecondaryGlassButtonStyle())
                }
            }
        }
        .adaptiveGlassCard(tint: AppTheme.cardTint.opacity(0.18), cornerRadius: 34, interactive: true, padding: 22)
    }

    private var heroHeading: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今天先看结论，再决定下一杯")
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.accent)
            Text(focusHeadline)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
            Text(heroSummary)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var heroBadges: some View {
        VStack(alignment: .trailing, spacing: 8) {
            FocusBadge(
                title: "已记录",
                detail: "\(environment.dashboard.todayEntries.count) 杯"
            )
            FocusBadge(
                title: environment.pendingSyncCount > 0 ? "待同步" : "已连接",
                detail: environment.pendingSyncCount > 0 ? "\(environment.pendingSyncCount) 条" : "服务端"
            )
        }
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: grid, spacing: 12) {
            MetricTile(
                title: "咖啡因",
                value: "\(Int(environment.dashboard.aggregate.caffeineMG))mg",
                caption: metricCaption(environment.dashboard.aggregate.caffeineMG, environment.dashboard.goals.caffeineLimitMG),
                progress: caffeineRatio,
                tint: Color(red: 0.50, green: 0.35, blue: 0.25)
            )
            MetricTile(
                title: "糖分",
                value: "\(Int(environment.dashboard.aggregate.sugarG))g",
                caption: metricCaption(environment.dashboard.aggregate.sugarG, environment.dashboard.goals.sugarLimitG),
                progress: sugarRatio,
                tint: Color(red: 0.90, green: 0.53, blue: 0.18)
            )
            MetricTile(
                title: "补水",
                value: "\(Int(environment.dashboard.aggregate.hydrationML))ml",
                caption: hydrationCaption,
                progress: hydrationRatio,
                tint: AppTheme.accent
            )
            MetricTile(
                title: "建议",
                value: "\(environment.dashboard.recommendations.count) 条",
                caption: focusLabel,
                progress: progressRatio,
                tint: topDecisionTint
            )
        }
    }

    private var recommendationRail: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("为什么这样判断")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                    Text("把规则解释留在这里，不挤占首屏决策位")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                groupGlassElements {
                    HStack(spacing: 14) {
                        ForEach(recommendationsPreview) { card in
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
        SectionCard(title: "最近 4 杯", subtitle: "把首页留给判断，把明细留给品牌和时间线") {
            if environment.dashboard.todayEntries.isEmpty {
                Text("今天还没有真实记录，先去记录页挑一杯品牌饮品或打开 Brew Lab。")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(environment.dashboard.todayEntries.prefix(4)) { entry in
                        TimelineEntryRow(entry: entry)
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
                        label: progressCaption,
                        systemImage: progressRatio >= 1 ? "exclamationmark.triangle.fill" : "checkmark.seal"
                    )
                }
            }
        }
    }

    private var heroSummary: String {
        switch focusLabel {
        case "需要干预":
            return "现在先压住高糖和高因输入，再补一杯水，让后半天回到可控区。"
        case "接近阈值":
            return "已经靠近阈值，接下来的选择建议更轻、更少、更慢一点。"
        case "补水不错":
            return "补水节奏在线，接下来重点守住糖和咖啡因的上限。"
        default:
            return "今天整体还稳，继续用品牌化记录把变化留痕。"
        }
    }

    private var focusHeadline: String {
        switch focusLabel {
        case "需要干预":
            return "先把糖和咖啡因收一收"
        case "接近阈值":
            return "离阈值不远了，下一杯要更轻"
        case "补水不错":
            return "补水节奏不错，别让后半天失速"
        default:
            return "今天的饮品节奏还算平稳"
        }
    }

    private var topDecisionTitle: String {
        environment.dashboard.recommendations.first?.title ?? "继续保持小步记录"
    }

    private var topDecisionMessage: String {
        environment.dashboard.recommendations.first?.explanation.action ?? "接下来优先选择无糖、低因或补水型饮品。"
    }

    private var topDecisionFootnote: String {
        environment.dashboard.recommendations.first?.explanation.thresholdComparison ?? "当日累计仍在可控范围内。"
    }

    private var topDecisionTint: Color {
        accentForSeverity(environment.dashboard.recommendations.first?.severity ?? "info")
    }

    private var recommendationsPreview: [RecommendationCard] {
        let cards = environment.dashboard.recommendations
        if cards.isEmpty {
            return [
                RecommendationCard(
                    ruleID: "baseline",
                    severity: "info",
                    title: "继续稳定记录",
                    summary: "今天还没有触发明显风险，但持续记录会让后续建议更准。",
                    explanation: RecommendationExplanation(
                        ruleID: "baseline",
                        trigger: "empty-state",
                        inputs: [:],
                        thresholdComparison: "尚未出现阈值越界",
                        action: "先从一杯最常喝的品牌饮品开始记录。",
                        risk: "记录缺失会让建议保守。"
                    )
                )
            ]
        }
        return Array(cards.prefix(3))
    }

    private var sugarRatio: Double {
        environment.dashboard.aggregate.sugarG / max(environment.dashboard.goals.sugarLimitG, 1)
    }

    private var caffeineRatio: Double {
        environment.dashboard.aggregate.caffeineMG / max(environment.dashboard.goals.caffeineLimitMG, 1)
    }

    private var hydrationRatio: Double {
        environment.dashboard.aggregate.hydrationML / max(environment.dashboard.goals.hydrationGoalML, 1)
    }

    private var focusLabel: String {
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
        max(sugarRatio, caffeineRatio)
    }

    private var progressCaption: String {
        progressRatio >= 1 ? "高风险" : progressRatio >= 0.8 ? "预警中" : "平稳"
    }

    private var hydrationCaption: String {
        if hydrationRatio >= 1 {
            return "已达目标"
        }
        let remaining = max(Int(environment.dashboard.goals.hydrationGoalML - environment.dashboard.aggregate.hydrationML), 0)
        return "还差 \(remaining)ml"
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

    private func metricCaption(_ value: Double, _ target: Double) -> String {
        let ratio = value / max(target, 1)
        if ratio >= 1 {
            return "已越过上限"
        }
        let remaining = max(Int(target - value), 0)
        return "还余 \(remaining)"
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
    let progress: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(caption)
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(tint)
            }

            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.55))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.55), tint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: proxy.size.width * min(max(progress, 0.04), 1))
                }
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity, minHeight: 124, alignment: .leading)
        .adaptiveGlassCard(tint: tint.opacity(0.10), cornerRadius: 28)
    }
}

private struct RecommendationCapsule: View {
    let card: RecommendationCard

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(card.title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Text(severityLabel)
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(severityTint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(severityTint.opacity(0.12), in: Capsule())
            }

            Text(card.summary)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(card.explanation.thresholdComparison)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(severityTint)

            Text(card.explanation.action)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .adaptiveGlassCard(cornerRadius: 28, interactive: true)
    }

    private var severityLabel: String {
        switch card.severity {
        case "critical":
            return "高风险"
        case "warning":
            return "预警"
        default:
            return "稳定"
        }
    }

    private var severityTint: Color {
        switch card.severity {
        case "critical":
            return Color(red: 0.84, green: 0.30, blue: 0.24)
        case "warning":
            return Color(red: 0.90, green: 0.53, blue: 0.18)
        default:
            return AppTheme.accent
        }
    }
}

private struct DecisionSpotlight: View {
    let eyebrow: String
    let title: String
    let message: String
    let footnote: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow)
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(tint)
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)
            Text(message)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(footnote)
                .font(.system(.caption, design: .rounded))
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

private struct TimelineEntryRow: View {
    let entry: DrinkLogEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(AppTheme.accentSoft.opacity(0.32))
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: entry.preparationMethod?.systemImage ?? "cup.and.saucer")
                        .foregroundStyle(AppTheme.accent)
                )

            VStack(alignment: .leading, spacing: 5) {
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
        .padding(14)
        .background(Color.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
