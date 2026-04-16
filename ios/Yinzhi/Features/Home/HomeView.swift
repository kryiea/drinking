import Observation
import SwiftUI

struct HomeView: View {
    @Bindable var environment: AppEnvironment

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header
                heroCard
                timelineCard

                if recentEntries.isEmpty == false {
                    recentEntriesCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 132)
        }
        .background(pageBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            floatingRecordButton
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 8)
        }
    }

    private var forecast: CaffeineForecastSummary {
        environment.dashboard.caffeineForecast
    }

    private var palette: HomePalette {
        switch forecast.sleepReadiness {
        case .sleepFriendly:
            HomePalette(
                tint: AppTheme.accent,
                glow: AppTheme.accentSoft,
                chartTint: Color(red: 0.95, green: 0.55, blue: 0.25),
                orbIcon: "moon.stars.fill",
                statusLabel: "今晚还稳"
            )
        case .watch:
            HomePalette(
                tint: Color(red: 0.91, green: 0.60, blue: 0.18),
                glow: Color(red: 0.99, green: 0.86, blue: 0.63),
                chartTint: Color(red: 0.95, green: 0.52, blue: 0.28),
                orbIcon: "moon.zzz.fill",
                statusLabel: "今晚收一点"
            )
        case .likelyDisruptive:
            HomePalette(
                tint: Color(red: 0.83, green: 0.33, blue: 0.24),
                glow: Color(red: 0.96, green: 0.75, blue: 0.66),
                chartTint: Color(red: 0.93, green: 0.44, blue: 0.27),
                orbIcon: "exclamationmark.triangle.fill",
                statusLabel: "今晚先别再加"
            )
        }
    }

    private var recentEntries: [DrinkLogEntry] {
        Array(environment.dashboard.todayEntries.prefix(3))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("今天")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Text("只看当前体内咖啡因和今晚入睡。")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    HomeBadge(label: palette.statusLabel, tint: palette.tint)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .lastTextBaseline, spacing: 6) {
                            Text("\(Int(forecast.currentEstimateMG))")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)

                            Text("mg")
                                .font(.system(.title3, design: .rounded, weight: .bold))
                                .foregroundStyle(palette.tint)
                        }

                        Text("当前体内咖啡因")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(.secondary)
                    }

                    Text("\(environment.preferences.sleepHourText) 入睡时约 \(Int(forecast.projectedSleepMG))mg")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.ink)

                    if let recoveryText {
                        Text(recoveryText)
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(palette.tint)
                    }
                }

                Spacer(minLength: 0)

                HomeStateOrb(
                    icon: palette.orbIcon,
                    tint: palette.tint,
                    glow: palette.glow,
                    fillRatio: orbFillRatio
                )
            }

            homeGlassGroup(spacing: 10) {
                HStack(spacing: 10) {
                    HomeMetricCapsule(
                        title: "入睡",
                        value: environment.preferences.sleepHourText,
                        tint: AppTheme.ink
                    )
                    HomeMetricCapsule(
                        title: "预计残留",
                        value: "\(Int(forecast.projectedSleepMG))mg",
                        tint: palette.tint
                    )
                }
            }
        }
        .adaptiveGlassCard(
            tint: palette.tint.opacity(0.10),
            cornerRadius: 36,
            interactive: true,
            padding: 22
        )
        .shadow(color: palette.tint.opacity(0.12), radius: 28, y: 16)
    }

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("从现在到入睡")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                    Text("看体内咖啡因会怎样往下走。")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                if let recommendedSleepTime = forecast.recommendedSleepTime,
                   recommendedSleepTime > forecast.sleepAt
                {
                    HomeBadge(
                        label: "更稳 \(recommendedSleepTime.formatted(date: .omitted, time: .shortened))",
                        tint: palette.tint.opacity(0.82)
                    )
                }
            }

            HomeSleepChart(
                points: chartPoints,
                safeThresholdMG: forecast.safeSleepThresholdMG,
                tint: palette.chartTint,
                highlightTint: palette.tint
            )
            .frame(height: 164)

            HStack {
                TimelineFootnote(
                    title: "现在",
                    value: "\(Int(forecast.currentEstimateMG))mg",
                    alignment: .leading
                )
                Spacer()
                TimelineFootnote(
                    title: environment.preferences.sleepHourText,
                    value: "\(Int(forecast.projectedSleepMG))mg",
                    alignment: .trailing
                )
            }
        }
        .adaptiveGlassCard(
            tint: AppTheme.cardTint,
            cornerRadius: 32,
            padding: 20
        )
    }

    private var recentEntriesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("今天喝过")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Text("\(environment.dashboard.todayEntries.count) 杯")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                ForEach(recentEntries) { entry in
                    HomeRecentEntryRow(entry: entry, tint: palette.tint)
                }
            }
        }
        .adaptiveGlassCard(
            tint: AppTheme.cardTint,
            cornerRadius: 28,
            padding: 18
        )
    }

    private var floatingRecordButton: some View {
        HStack {
            Spacer()
            Button {
                environment.selectedTab = .log
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.viewfinder")
                        .font(.system(.headline, weight: .bold))
                    Text("记一杯")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [AppTheme.accent, AppTheme.accent.opacity(0.86)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Capsule(style: .continuous)
                )
                .shadow(color: AppTheme.accent.opacity(0.24), radius: 20, y: 10)
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    private var recoveryText: String? {
        guard let recommendedSleepTime = forecast.recommendedSleepTime else {
            return nil
        }

        if recommendedSleepTime <= forecast.sleepAt {
            return "按现在的计划入睡，影响相对可控。"
        }

        return "更接近适合入睡的时间大约在 \(recommendedSleepTime.formatted(date: .omitted, time: .shortened))。"
    }

    private var orbFillRatio: CGFloat {
        let denominator = max(forecast.safeSleepThresholdMG * 4, forecast.currentEstimateMG, 1)
        return CGFloat(min(max(forecast.currentEstimateMG / denominator, 0.18), 1))
    }

    private var chartPoints: [HomeTimelinePoint] {
        let preSleepTimeline = forecast.timeline.filter { $0.at < forecast.sleepAt }
        let sampledTimeline = sampleTimeline(preSleepTimeline)

        var points = sampledTimeline.map {
            HomeTimelinePoint(
                id: $0.at.formatted(date: .omitted, time: .standard),
                at: $0.at,
                remainingMG: $0.remainingCaffeineMG,
                isSleepPoint: false
            )
        }

        let sleepID = forecast.sleepAt.formatted(date: .omitted, time: .standard)
        if points.last?.id != sleepID {
            points.append(
                HomeTimelinePoint(
                    id: sleepID,
                    at: forecast.sleepAt,
                    remainingMG: forecast.projectedSleepMG,
                    isSleepPoint: true
                )
            )
        } else if let lastIndex = points.indices.last {
            points[lastIndex] = HomeTimelinePoint(
                id: sleepID,
                at: forecast.sleepAt,
                remainingMG: forecast.projectedSleepMG,
                isSleepPoint: true
            )
        }

        return points
    }

    private func sampleTimeline(_ timeline: [CaffeineForecastPointSummary]) -> [CaffeineForecastPointSummary] {
        guard timeline.count > 5 else {
            return timeline
        }

        let step = max((timeline.count - 1) / 4, 1)
        var points = Swift.stride(from: 0, to: timeline.count, by: step).map { timeline[$0] }
        if let last = timeline.last, points.last?.id != last.id {
            points.append(last)
        }
        return points
    }

    private var pageBackground: some View {
        ZStack {
            AppTheme.pageBackground

            Circle()
                .fill(palette.glow.opacity(0.52))
                .frame(width: 280, height: 280)
                .blur(radius: 72)
                .offset(x: 150, y: -220)

            Circle()
                .fill(AppTheme.ambientCloud)
                .frame(width: 220, height: 220)
                .blur(radius: 86)
                .offset(x: -120, y: 40)
        }
    }

    @ViewBuilder
    private func homeGlassGroup<Content: View>(spacing: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content()
            }
        } else {
            content()
        }
    }
}

private struct HomePalette {
    let tint: Color
    let glow: Color
    let chartTint: Color
    let orbIcon: String
    let statusLabel: String
}

private struct HomeTimelinePoint: Identifiable {
    let id: String
    let at: Date
    let remainingMG: Double
    let isSleepPoint: Bool
}

private struct HomeBadge: View {
    let label: String
    let tint: Color

    var body: some View {
        Text(label)
            .font(.system(.caption, design: .rounded, weight: .bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

private struct HomeMetricCapsule: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .adaptiveGlassCard(
            tint: AppTheme.cardTint,
            cornerRadius: 22,
            padding: 14
        )
    }
}

private struct HomeStateOrb: View {
    let icon: String
    let tint: Color
    let glow: Color
    let fillRatio: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.elevatedSurface)
                .overlay(
                    Circle()
                        .stroke(AppTheme.glassStroke, lineWidth: 1)
                )

            Circle()
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.96), glow.opacity(0.86)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: 118, height: 118)
                .mask(alignment: .bottom) {
                    Rectangle()
                        .frame(height: max(22, 118 * fillRatio))
                }

            Circle()
                .stroke(AppTheme.glassStroke.opacity(0.92), lineWidth: 7)
                .frame(width: 118, height: 118)

            Image(systemName: icon)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(tint)
                .shadow(color: .white.opacity(0.35), radius: 6, y: 2)
        }
        .frame(width: 132, height: 132)
        .background(
            Circle()
                .fill(glow.opacity(0.34))
                .blur(radius: 16)
        )
    }
}

private struct HomeSleepChart: View {
    let points: [HomeTimelinePoint]
    let safeThresholdMG: Double
    let tint: Color
    let highlightTint: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            let maxValue = max(points.map(\.remainingMG).max() ?? 0, safeThresholdMG * 1.5, 1)
            let horizontalPadding: CGFloat = 14
            let verticalPadding: CGFloat = 14
            let axisSpacing: CGFloat = 8
            let axisLabelHeight: CGFloat = 18
            let plotHeight = max(
                geometry.size.height - (verticalPadding * 2) - axisSpacing - axisLabelHeight,
                28
            )
            let thresholdY = verticalPadding + plotHeight * (1 - safeThresholdMG / maxValue)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(AppTheme.chartSurface)

                Rectangle()
                    .fill(thresholdColor)
                    .frame(height: 1.5)
                    .overlay(alignment: .trailing) {
                        Text("睡眠线")
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundStyle(labelForeground)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(AppTheme.elevatedSurface.opacity(0.98), in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(thresholdColor.opacity(0.28), lineWidth: 1)
                            )
                            .offset(y: -14)
                    }
                    .offset(y: thresholdY)

                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                        VStack(spacing: 8) {
                            Spacer(minLength: 0)

                            RoundedRectangle(cornerRadius: 999, style: .continuous)
                                .fill(barGradient(for: point, index: index))
                                .frame(
                                    width: 18,
                                    height: max(16, plotHeight * CGFloat(point.remainingMG / maxValue))
                                )

                            Text(point.isSleepPoint ? "睡" : point.at.formatted(date: .omitted, time: .shortened))
                                .font(.system(.caption2, design: .rounded, weight: .bold))
                                .foregroundStyle(point.isSleepPoint ? highlightTint : .secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(height: axisLabelHeight)
                        }
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: plotHeight + axisSpacing + axisLabelHeight,
                            alignment: .bottom
                        )
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
            }
        }
    }

    private func barGradient(for point: HomeTimelinePoint, index: Int) -> LinearGradient {
        let baseColor = point.isSleepPoint ? highlightTint : tint
        let opacityBoost = 0.64 + (Double(index) * 0.05)

        return LinearGradient(
            colors: [
                baseColor.opacity(min(opacityBoost, 0.96)),
                baseColor.opacity(0.48),
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    private var thresholdColor: Color {
        if colorScheme == .dark {
            return highlightTint.opacity(0.76)
        }
        return highlightTint.opacity(0.62)
    }

    private var labelForeground: Color {
        if colorScheme == .dark {
            return .white.opacity(0.92)
        }
        return AppTheme.ink
    }
}

private struct TimelineFootnote: View {
    let title: String
    let value: String
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)
        }
    }
}

private struct HomeRecentEntryRow: View {
    let entry: DrinkLogEntry
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(tint.opacity(0.16))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(tint)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.drinkName)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                Text(entry.brand ?? "未标记品牌")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(Int(entry.metrics.caffeineMG))mg")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(tint)
                Text(entry.consumedAt.formatted(date: .omitted, time: .shortened))
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .adaptiveGlassCard(
            tint: AppTheme.cardTint,
            cornerRadius: 22,
            padding: 12
        )
    }
}
