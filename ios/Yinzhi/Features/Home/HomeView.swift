import Observation
import SwiftUI

struct HomeView: View {
    @Bindable var environment: AppEnvironment

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 112)
        }
        .background(AppTheme.pageBackground.ignoresSafeArea())
        .navigationTitle("首页")
        .toolbarTitleDisplayMode(.large)
    }

    private var hero: some View {
        let forecast = environment.dashboard.caffeineForecast

        return VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("当前状态")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(heroTint)
                    Text(homeTitle)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Text("\(environment.preferences.sleepHourText) 前预计剩余 \(Int(forecast.projectedSleepMG))mg")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Circle()
                    .fill(heroTint.opacity(0.18))
                    .frame(width: 68, height: 68)
                    .overlay(
                        Image(systemName: forecast.sleepReadiness.systemImage)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(heroTint)
                    )
            }

            HStack(spacing: 12) {
                HomeMetricBlock(
                    title: "当前体内",
                    value: "\(Int(forecast.currentEstimateMG))",
                    unit: "mg",
                    tint: Color(red: 0.49, green: 0.35, blue: 0.24)
                )
                HomeMetricBlock(
                    title: "入睡时",
                    value: "\(Int(forecast.projectedSleepMG))",
                    unit: "mg",
                    tint: heroTint
                )
            }

            Button {
                environment.selectedTab = .log
            } label: {
                HStack {
                    Label("记一杯", systemImage: "plus.viewfinder")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(PrimaryCTAStyle())
        }
        .adaptiveGlassCard(
            tint: heroTint.opacity(0.12),
            cornerRadius: 36,
            interactive: true,
            padding: 24
        )
    }

    private var homeTitle: String {
        switch environment.dashboard.caffeineForecast.sleepReadiness {
        case .sleepFriendly:
            return "今晚还稳"
        case .watch:
            return "今晚收一点"
        case .likelyDisruptive:
            return "今晚先别再加了"
        }
    }

    private var heroTint: Color {
        switch environment.dashboard.caffeineForecast.sleepReadiness {
        case .sleepFriendly:
            return AppTheme.accent
        case .watch:
            return Color(red: 0.92, green: 0.62, blue: 0.16)
        case .likelyDisruptive:
            return Color(red: 0.82, green: 0.33, blue: 0.25)
        }
    }
}

private struct HomeMetricBlock: View {
    let title: String
    let value: String
    let unit: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                Text(unit)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(tint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .adaptiveGlassCard(tint: tint.opacity(0.10), cornerRadius: 26, padding: 16)
    }
}
