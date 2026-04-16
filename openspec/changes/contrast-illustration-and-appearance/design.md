# Design: Contrast Illustration And Appearance

## Scope
- `ios/Yinzhi/Core/Design/DesignSystem.swift`
- `ios/Yinzhi/Features/Home/HomeView.swift`
- `ios/Yinzhi/Features/Log/LogView.swift`
- `ios/Yinzhi/Features/Profile/ProfileView.swift` if theme text colors need follow-through
- `docs/product/v1-scope.md`
- `agent.md`

## Contrast Strategy
- 不再在浅色半透明卡片上直接使用接近白色的数值文字。
- 关键数值统一使用高对比前景色；强调色用于状态或点缀，而不是承担可读性本身。
- 图表内部和图表外部脚注维持清晰分层，避免视觉重叠和低对比双重叠加。

## Illustration Strategy
- 计算器插图使用更清晰的几何轮廓而不是偏抽象的块面。
- 手冲图示至少同时包含：细嘴壶、滤杯 / 滤纸、下壶 / 杯体，以提高识别率。
- 意式和胶囊图示保留现有方向，但要提升结构边界和深浅层次。

## Appearance Strategy
- 设计系统基础色改为动态色值，跟随系统浅色 / 深色模式。
- 页面背景、墨色、玻璃 fallback 描边和主要卡片 tint 都必须使用动态色。
- 不新增单独的主题设置页；当前阶段默认跟随系统。

## Validation
- `swift test`
- `xcodebuild -project ios/Yinzhi.xcodeproj -scheme Yinzhi -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
- 模拟器人工验证：
  - 浅色模式首页关键文字清晰
  - 深色模式首页和计算器层级正常
  - 手冲图示能与意式/胶囊明显区分
