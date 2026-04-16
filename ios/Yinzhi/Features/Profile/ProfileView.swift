import Observation
import SwiftUI

struct ProfileView: View {
    @Bindable var environment: AppEnvironment

    var body: some View {
        List {
            Section("节奏") {
                NavigationLink {
                    SleepTimeSettingsView(environment: environment)
                } label: {
                    SettingsRow(
                        title: "入睡时间",
                        detail: environment.preferences.sleepHourText
                    )
                }

                NavigationLink {
                    MetabolismSettingsView(environment: environment)
                } label: {
                    SettingsRow(
                        title: "代谢速度",
                        detail: environment.preferences.metabolismProfile.label
                    )
                }
            }

            Section("数据") {
                NavigationLink {
                    SyncAndDataSettingsView(environment: environment)
                } label: {
                    SettingsRow(
                        title: "同步与数据",
                        detail: environment.syncStrategyLabel
                    )
                }

                NavigationLink {
                    MyDrinksSettingsView(environment: environment)
                } label: {
                    SettingsRow(
                        title: "我的饮品",
                        detail: "\(environment.userDrinkTemplates.count) 个"
                    )
                }
            }

            if environment.canUseRemoteAPI {
                Section("开发") {
                    NavigationLink {
                        DeveloperConnectionSettingsView(environment: environment)
                    } label: {
                        SettingsRow(
                            title: "开发连接",
                            detail: environment.connectionShortLabel
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("我的")
    }
}

private struct SettingsRow: View {
    let title: String
    let detail: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
            Spacer()
            Text(detail)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}

private struct SleepTimeSettingsView: View {
    @Bindable var environment: AppEnvironment

    var body: some View {
        List {
            DatePicker(
                "目标入睡时间",
                selection: Binding(
                    get: { environment.sleepScheduleDate },
                    set: { environment.updateSleepSchedule($0) }
                ),
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("入睡时间")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MetabolismSettingsView: View {
    @Bindable var environment: AppEnvironment

    var body: some View {
        List {
            Section {
                Picker(
                    "咖啡因代谢",
                    selection: Binding(
                        get: { environment.preferences.metabolismProfile },
                        set: { environment.updateMetabolismProfile($0) }
                    )
                ) {
                    ForEach(CaffeineMetabolismProfile.allCases) { item in
                        Text(item.label).tag(item)
                    }
                }
                .pickerStyle(.inline)
            } footer: {
                Text(environment.preferences.metabolismProfile.caption)
            }
        }
        .navigationTitle("代谢速度")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SyncAndDataSettingsView: View {
    @Bindable var environment: AppEnvironment

    var body: some View {
        List {
            Section {
                Toggle(
                    "iCloud 同步",
                    isOn: Binding(
                        get: { environment.preferences.iCloudPlanEnabled },
                        set: { environment.updateICloudPlanEnabled($0) }
                    )
                )

                LabeledContent("状态", value: environment.syncStrategyLabel)
                LabeledContent("待同步", value: "\(environment.pendingSyncCount) 条")
            } header: {
                Text("同步")
            } footer: {
                Text(environment.syncStrategyCaption)
            }

            Section("数据") {
                Button("导出本周记录") {
                    Task {
                        await environment.requestWeeklyExport()
                    }
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
        }
        .navigationTitle("同步与数据")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MyDrinksSettingsView: View {
    @Bindable var environment: AppEnvironment

    var body: some View {
        List {
            if environment.userDrinkTemplates.isEmpty {
                Text("还没有自定义饮品。")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(environment.userDrinkTemplates) { template in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(template.brand) · \(template.name)")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                        Text(template.detailLine)
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("我的饮品")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DeveloperConnectionSettingsView: View {
    @Bindable var environment: AppEnvironment

    var body: some View {
        List {
            Section {
                LabeledContent("连接状态", value: environment.connectionShortLabel)
                Text(environment.connectionSupportingText)
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .foregroundStyle(environment.connectionTint)
            }

            Section("操作") {
                if environment.session == nil {
                    Button(environment.errorMessage?.contains("过期") == true ? "重新连接开发后端" : "连接开发后端") {
                        Task {
                            await environment.signInWithDevelopmentToken()
                        }
                    }
                } else {
                    Button("补同步离线记录") {
                        Task {
                            await environment.syncPendingLogs()
                        }
                    }

                    Button("退出当前连接", role: .destructive) {
                        Task {
                            await environment.signOut()
                        }
                    }
                }
            }
        }
        .navigationTitle("开发连接")
        .navigationBarTitleDisplayMode(.inline)
    }
}
