import AuthenticationServices
import Observation
import SwiftUI

struct OnboardingView: View {
    @Bindable var environment: AppEnvironment

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 20)

                Text("饮知")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text("随手记下每一杯，马上知道今晚节奏。")
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.ink.opacity(0.84))

                if let statusMessage = environment.statusMessage {
                    StatusChip(label: statusMessage, systemImage: "network")
                }

                VStack(spacing: 14) {
                    onboardingItem(icon: "plus.viewfinder", title: "快速记一杯", detail: "语音、拍照、最近一杯和品牌目录都能直接记。")
                    onboardingItem(icon: "moon.stars.fill", title: "看今晚影响", detail: "首页和曲线页会直接告诉你当前值和睡前残留。")
                    onboardingItem(icon: "icloud.fill", title: "先从本地开始", detail: "没连后端也能先记，后续再接上同步和导出。")
                }

                VStack(spacing: 12) {
                    if environment.canUseAppleSignIn {
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName]
                        } onCompletion: { result in
                            Task {
                                await handleAppleSignIn(result)
                            }
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 54)
                        .clipShape(Capsule())
                    }

                    if environment.canUseRemoteAPI {
                        Button("开发模式直连后端") {
                            Task {
                                await environment.signInWithDevelopmentToken()
                            }
                        }
                        .buttonStyle(SecondaryGlassButtonStyle())
                    }

                    Button(environment.canUseRemoteAPI ? "先开始离线记录" : "开始记录我的节奏") {
                        environment.continueWithPreviewMode()
                    }
                    .buttonStyle(PrimaryCTAStyle())
                }

                if environment.isAuthenticating {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("正在建立会话并同步今天的记录…")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage = environment.errorMessage {
                    Text(errorMessage)
                        .font(.system(.footnote, design: .rounded, weight: .semibold))
                        .foregroundStyle(.orange)
                }

                Spacer(minLength: 12)
            }
            .padding(24)
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case let .success(authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8) else {
                environment.errorMessage = "没有拿到可用的 Apple 身份令牌，请稍后再试。"
                return
            }

            await environment.signInWithApple(identityToken: identityToken)

        case let .failure(error):
            environment.errorMessage = "Apple 登录未完成：\(error.localizedDescription)"
        }
    }

    private func onboardingItem(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Text(detail)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .adaptiveGlassCard(cornerRadius: 24, interactive: false)
    }
}
