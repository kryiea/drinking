import Observation
import SwiftUI

struct InsightsView: View {
    @Bindable var environment: AppEnvironment

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                overviewCard
                caffeineTimelineCard
                todayEventsCard
            }
            .padding(16)
            .padding(.bottom, 112)
        }
        .navigationTitle("分析")
    }

    private var overviewCard: some View {
        let forecast = environment.dashboard.caffeineForecast

        return SectionCard(title: "咖啡因视图", subtitle: "只看当前和入睡时") {
            HStack(spacing: 12) {
                InsightMetricPill(
                    title: "现在",
                    value: "\(Int(forecast.currentEstimateMG))mg",
                    tint: AppTheme.ink
                )
                InsightMetricPill(
                    title: environment.preferences.sleepHourText,
                    value: "\(Int(forecast.projectedSleepMG))mg",
                    tint: tint(for: forecast.sleepReadiness)
                )
            }
        }
    }

    private var caffeineTimelineCard: some View {
        let forecast = environment.dashboard.caffeineForecast
        let maxValue = max(forecast.currentEstimateMG, forecast.projectedSleepMG, forecast.safeSleepThresholdMG, 1)

        return SectionCard(title: "从现在到入睡", subtitle: "看下降速度和睡前位置") {
            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: 12) {
                    TimelineRailRow(
                        title: "现在",
                        subtitle: forecast.calculatedAt.formatted(date: .omitted, time: .shortened),
                        value: forecast.currentEstimateMG,
                        maxValue: maxValue,
                        tint: AppTheme.ink
                    )

                    TimelineRailRow(
                        title: "入睡",
                        subtitle: environment.preferences.sleepHourText,
                        value: forecast.projectedSleepMG,
                        maxValue: maxValue,
                        tint: tint(for: forecast.sleepReadiness)
                    )

                    TimelineRailRow(
                        title: "参考线",
                        subtitle: "更适合入睡",
                        value: forecast.safeSleepThresholdMG,
                        maxValue: maxValue,
                        tint: Color.orange
                    )
                }

                if forecast.timeline.isEmpty == false {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(sampledPoints(from: forecast.timeline)) { point in
                                TimelineDotCard(
                                    timeText: point.at.formatted(date: .omitted, time: .shortened),
                                    valueText: "\(Int(point.remainingCaffeineMG))mg",
                                    tint: point.at >= forecast.sleepAt ? tint(for: forecast.sleepReadiness) : AppTheme.accent
                                )
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    private var todayEventsCard: some View {
        SectionCard(title: "今天喝过", subtitle: "看每一杯对今晚的拖尾") {
            if environment.dashboard.todayEntries.isEmpty {
                Text("今天还没有记录。")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(environment.dashboard.todayEntries.prefix(6)) { entry in
                        InsightEventRow(
                            entry: entry,
                            projectedSleepContributionMG: projectedSleepContribution(for: entry)
                        )
                    }
                }
            }
        }
    }

    private func sampledPoints(from timeline: [CaffeineForecastPointSummary]) -> [CaffeineForecastPointSummary] {
        if timeline.count <= 6 {
            return timeline
        }
        let step = max(timeline.count / 5, 1)
        let points = Swift.stride(from: 0, to: timeline.count, by: step).map { timeline[$0] }
        if let last = timeline.last, points.last?.id != last.id {
            return points + [last]
        }
        return points
    }

    private func projectedSleepContribution(for entry: DrinkLogEntry) -> Double {
        let forecast = environment.dashboard.caffeineForecast
        let remainingHours = max(forecast.sleepAt.timeIntervalSince(entry.consumedAt) / 3600, 0)
        let halfLife = max(forecast.halfLifeHours, 0.1)
        let decay = pow(0.5, remainingHours / halfLife)
        return entry.metrics.caffeineMG * decay
    }

    private func tint(for readiness: SleepReadinessState) -> Color {
        switch readiness {
        case .sleepFriendly:
            return AppTheme.accent
        case .watch:
            return Color.orange
        case .likelyDisruptive:
            return Color(red: 0.84, green: 0.30, blue: 0.24)
        }
    }
}

private struct InsightMetricPill: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .adaptiveGlassCard(tint: tint.opacity(0.08), cornerRadius: 24, padding: 14)
    }
}

private struct TimelineRailRow: View {
    let title: String
    let subtitle: String
    let value: Double
    let maxValue: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(value))mg")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(tint)
            }

            GeometryReader { geometry in
                let width = max(geometry.size.width, 1)
                let ratio = min(max(value / maxValue, 0), 1)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.5))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [tint, tint.opacity(0.55)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(width * ratio, 16))
                }
            }
            .frame(height: 16)
        }
    }
}

private struct TimelineDotCard: View {
    let timeText: String
    let valueText: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(timeText)
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
            Text(valueText)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)
        }
        .frame(width: 82, alignment: .leading)
        .adaptiveGlassCard(tint: tint.opacity(0.08), cornerRadius: 18, padding: 12)
    }
}

private struct InsightEventRow: View {
    let entry: DrinkLogEntry
    let projectedSleepContributionMG: Double

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.brand ?? "未标记品牌")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
                Text(entry.drinkName)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                Text(entry.consumedAt.formatted(date: .omitted, time: .shortened))
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(entry.metrics.caffeineMG))mg")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Text("睡前约 \(Int(projectedSleepContributionMG))mg")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .adaptiveGlassCard(cornerRadius: 22, padding: 14)
    }
}
