# 质量验证矩阵

## 必跑项
- `pytest backend/tests`
- `swift test`
- `xcodebuild -project ios/Yinzhi.xcodeproj -scheme Yinzhi -destination 'platform=iOS Simulator,id=<simulator-id>' build`
- 文档索引检查: `docs/README.md`、`openspec/README.md`、`agent.md` 是否同步更新，OpenSpec 变更是否齐全
- README 截图检查: `README.md` 中的页面与关键功能截图是否与当前 App 状态一致

## 环境受限项
- iOS UI 测试与截图回归
- HealthKit、Sign in with Apple、真实后台同步联调

## 核心断言
- 视图层不得直接使用 `URLSession`
- 后端 API 必须保持 `/v1` 前缀和 typed response shape，但当前只承担辅助系统职责
- 旧系统 fallback 必须存在，不能将 Liquid Glass 写成唯一显示路径
- Support 平台在未配置 LLM 密钥时也必须返回可用 fallback，不能让开发联调被配置空值阻断
- 品牌、冲泡方式与记录模型字段必须在 API、持久化和客户端模型中保持一致
- 本地缓存链路必须保留品牌与冲泡方式，不能在离线记录后退化成“未标记品牌”
- 后端故障、未配置或弱网状态不得阻断“记一杯 -> 看当前咖啡因 -> 看入睡残留”主链路
- 添加饮品后的全局反馈层必须浮在 tab bar 之上，并且包含记录结果、睡眠影响和同步状态三类信息
- 首页、记录页、分析页、我的页的滚动内容都不能让关键 CTA 或关键解释长期被 tab chrome 截断
- 图片识别链路必须本地完成 OCR，并在无法匹配目录时给出可继续搜索的关键词回退
- 记录页首屏必须优先呈现快速操作，而不是让用户先读解释性长文案
- 记录页品牌筛选必须优先靠小 logo 识别，而不是重新退化成重文字 tab
- 新阶段实施时，用户侧首页和记录页不得继续出现 AI 推荐主叙事
- onboarding 不得再把 AI 推荐或开放式建议作为核心卖点
- 我的页不得让未来路线型文案压过已可用的个人设置和数据动作
- 咖啡因曲线、入睡时间标记和睡前残留值必须来自可测试的确定性模型
- 语音输入必须经过结构化确认步骤，不能直接把自由文本写成最终记录
- iCloud 同步与本地数据访问必须通过明确抽象隔离，避免把 CloudKit 逻辑散落到页面层
- 同步快照 round-trip 不能丢失品牌、冲煮方式、个人设置或个人饮品模板字段
- 浅色 / 深色模式下的关键阈值标记、主要 CTA 和记录入口不能出现不可读的低对比状态
