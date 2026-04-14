import Observation
import SwiftUI

struct HomeView: View {
    @Bindable var environment: AppEnvironment

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                metricStrip
                todaySummary
                recommendationSection
                recentSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("今日节奏")
        .toolbarTitleDisplayMode(.large)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("你好，\(environment.profile.displayName)")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)
            Text("今天已经记录 \(environment.dashboard.todayEntries.count) 杯饮品，系统正在根据你的目标持续评估风险。")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
            statusRow
        }
    }

    private var metricStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            groupGlassElements {
                HStack(spacing: 12) {
                    MetricPill(label: "咖啡因", value: "\(Int(environment.dashboard.aggregate.caffeineMG))mg")
                    MetricPill(label: "糖分", value: "\(Int(environment.dashboard.aggregate.sugarG))g")
                    MetricPill(label: "补水", value: "\(Int(environment.dashboard.aggregate.hydrationML))ml")
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var todaySummary: some View {
        SectionCard(title: "今日总览", subtitle: "把风险卡在前面，把焦虑放在后面") {
            if #available(iOS 26.0, *) {
                GlassEffectContainer(spacing: 16) {
                    summaryContent
                }
            } else {
                summaryContent
            }
        }
    }

    private var summaryContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(environment.dashboard.recommendations.first?.summary ?? "继续用小步记录，把今天的节奏看清楚。")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
            ProgressView(value: environment.dashboard.aggregate.sugarG, total: environment.dashboard.goals.sugarLimitG)
                .tint(.orange)
            HStack {
                statColumn(title: "咖啡因", value: "\(Int(environment.dashboard.aggregate.caffeineMG)) / \(Int(environment.dashboard.goals.caffeineLimitMG))mg")
                statColumn(title: "糖分", value: "\(Int(environment.dashboard.aggregate.sugarG)) / \(Int(environment.dashboard.goals.sugarLimitG))g")
            }
            HStack {
                statColumn(title: "补水", value: "\(Int(environment.dashboard.aggregate.hydrationML)) / \(Int(environment.dashboard.goals.hydrationGoalML))ml")
                statColumn(title: "建议数", value: "\(environment.dashboard.recommendations.count) 条")
            }
        }
    }

    private var recommendationSection: some View {
        SectionCard(title: "建议卡片", subtitle: "所有结论都必须讲清楚原因") {
            VStack(spacing: 12) {
                ForEach(environment.dashboard.recommendations) { card in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(card.title)
                                .font(.system(.headline, design: .rounded, weight: .bold))
                            Spacer()
                            Text(card.severity.uppercased())
                                .font(.system(.caption2, design: .rounded, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                        Text(card.summary)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(AppTheme.ink)
                        Divider()
                        Text(card.explanation.thresholdComparison)
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(AppTheme.accent)
                        Text(card.explanation.action)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .adaptiveGlassCard(cornerRadius: 24, interactive: true)
                }
            }
        }
    }

    private var recentSection: some View {
        SectionCard(title: "最近记录", subtitle: "回看今天都喝了什么") {
            VStack(spacing: 12) {
                ForEach(environment.dashboard.todayEntries) { entry in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.drinkName)
                                .font(.system(.headline, design: .rounded, weight: .semibold))
                            Text("\(entry.category) · \(entry.servingLabel)")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(entry.consumedAt.formatted(date: .omitted, time: .shortened))
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
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
                            label: "待同步 \(environment.pendingSyncCount) 条",
                            systemImage: "arrow.triangle.2.circlepath",
                            tint: AppTheme.accentSoft.opacity(0.28)
                        )
                    }

                    if let statusMessage = environment.statusMessage {
                        StatusChip(label: statusMessage, systemImage: "bolt.horizontal.circle")
                    }
                }
            }
        }
    }

    private func statColumn(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
