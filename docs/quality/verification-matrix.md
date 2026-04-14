# 质量验证矩阵

## 必跑项
- `pytest backend/tests`
- `swift test`
- `xcodebuild -project ios/Yinzhi.xcodeproj -scheme Yinzhi -destination 'platform=iOS Simulator,id=<simulator-id>' build`
- 文档索引检查: `agent.md` 是否更新，OpenSpec 变更是否齐全

## 环境受限项
- iOS UI 测试与截图回归
- HealthKit、Sign in with Apple、真实后台同步联调

## 核心断言
- 推荐结果必须包含触发规则、输入数据、阈值判断、建议动作、风险说明
- 视图层不得直接使用 `URLSession`
- 服务端 API 必须保持 `/v1` 前缀和 typed response shape
- 旧系统 fallback 必须存在，不能将 Liquid Glass 写成唯一显示路径
- Support 平台在未配置 LLM 密钥时也必须返回可用 fallback，不能让开发联调被配置空值阻断
- 品牌、冲泡方式与记录模型字段必须在 API、持久化和客户端模型中保持一致
