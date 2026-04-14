import Observation
import SwiftUI

struct ProfileView: View {
    @Bindable var environment: AppEnvironment

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionCard(title: environment.connectionTitle, subtitle: "前后端分离 + 本地缓存的当前状态") {
                    profileMetric(title: "后端地址", value: environment.backendDisplayText)
                    profileMetric(title: "待同步记录", value: "\(environment.pendingSyncCount)")
                    if let lastSyncedAt = environment.session?.sync.lastSyncedAt {
                        profileMetric(
                            title: "最近同步",
                            value: lastSyncedAt.formatted(date: .omitted, time: .shortened)
                        )
                    }
                    if let statusMessage = environment.statusMessage {
                        Text(statusMessage)
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    if let errorMessage = environment.errorMessage {
                        Text(errorMessage)
                            .font(.system(.footnote, design: .rounded, weight: .semibold))
                            .foregroundStyle(.orange)
                    }
                }

                SectionCard(title: environment.profile.displayName, subtitle: "账号、目标与隐私设置") {
                    HStack {
                        profileMetric(title: "年龄", value: "\(environment.profile.age)")
                        profileMetric(title: "睡眠时间", value: environment.profile.sleepHourText)
                        profileMetric(title: "咖啡因敏感", value: environment.profile.caffeineSensitive ? "是" : "否")
                    }
                }

                SectionCard(title: "今日目标", subtitle: "这些阈值会驱动首页与建议引擎") {
                    profileMetric(title: "咖啡因上限", value: "\(Int(environment.dashboard.goals.caffeineLimitMG))mg")
                    profileMetric(title: "糖分上限", value: "\(Int(environment.dashboard.goals.sugarLimitG))g")
                    profileMetric(title: "补水目标", value: "\(Int(environment.dashboard.goals.hydrationGoalML))ml")
                }

                SectionCard(title: "数据与隐私", subtitle: "服务端为真源，本地缓存负责离线体验") {
                    Label("Apple 登录接后端会话", systemImage: "person.badge.key")
                    Label("SwiftData 离线缓存已接入，失败时会落本地待补同步", systemImage: "externaldrive.badge.icloud")
                    Label("HealthKit 权限将在正式工程中按最小范围申请", systemImage: "heart.text.square")
                }

                VStack(spacing: 12) {
                    if environment.session == nil, environment.canUseRemoteAPI {
                        Button("开发模式直连后端") {
                            Task {
                                await environment.signInWithDevelopmentToken()
                            }
                        }
                        .buttonStyle(SecondaryGlassButtonStyle())
                    }

                    if environment.pendingSyncCount > 0, environment.session != nil {
                        Button("立即补同步离线记录") {
                            Task {
                                await environment.syncPendingLogs()
                            }
                        }
                        .buttonStyle(SecondaryGlassButtonStyle())
                    }

                    Button("请求导出本周记录") {
                        Task {
                            await environment.requestWeeklyExport()
                        }
                    }
                    .buttonStyle(PrimaryCTAStyle())

                    if environment.session != nil {
                        Button("退出当前登录") {
                            Task {
                                await environment.signOut()
                            }
                        }
                        .buttonStyle(SecondaryGlassButtonStyle())
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("我的")
    }

    private func profileMetric(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(.subheadline, design: .rounded))
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)
        }
    }
}
