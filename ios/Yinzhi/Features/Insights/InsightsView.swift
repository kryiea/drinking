import Observation
import SwiftUI

struct InsightsView: View {
    @Bindable var environment: AppEnvironment

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionCard(title: "本日结构", subtitle: "帮助你看见今天的输入而不是只盯一条提醒") {
                    chartRow(title: "咖啡因", consumed: environment.dashboard.aggregate.caffeineMG, target: environment.dashboard.goals.caffeineLimitMG, tint: .brown)
                    chartRow(title: "糖分", consumed: environment.dashboard.aggregate.sugarG, target: environment.dashboard.goals.sugarLimitG, tint: .orange)
                    chartRow(title: "补水", consumed: environment.dashboard.aggregate.hydrationML, target: environment.dashboard.goals.hydrationGoalML, tint: AppTheme.accent)
                }

                SectionCard(title: "行为解释", subtitle: "把今天的饮品选择翻译成身体语言") {
                    Text(environment.dashboard.recommendations.first?.summary ?? "继续保持记录，系统会在你跨过阈值时及时提醒。")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Divider()
                    Text(environment.dashboard.recommendations.first?.explanation.action ?? "建议优先顺序：气泡水 > 无糖茶饮 > 低因咖啡 > 奶茶。")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                }

                if environment.dashboard.categoryBreakdown.isEmpty == false {
                    SectionCard(title: "摄入结构", subtitle: "看看今天主要喝了哪些类型") {
                        ForEach(environment.dashboard.categoryBreakdown) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.category)
                                        .font(.system(.headline, design: .rounded, weight: .semibold))
                                    Text("\(item.entriesCount) 杯")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(Int(item.hydrationML))ml")
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                    .foregroundStyle(AppTheme.ink)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("分析")
    }

    private func chartRow(title: String, consumed: Double, target: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                Spacer()
                Text("\(Int(consumed)) / \(Int(target))")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: consumed, total: max(target, 1))
                .tint(tint)
        }
    }
}
