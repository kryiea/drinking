# Design: Home Glance Redesign

## Scope
- `ios/Yinzhi/Features/Home/HomeView.swift`
- `ios/Yinzhi/Core/Design/DesignSystem.swift`
- `docs/product/v1-scope.md`
- `agent.md`

## Design Principles
- 先看懂，再读懂：优先用数字、形体、层级和色彩表达状态。
- 首页不是 dashboard，而是“今晚状态页”。
- 玻璃效果只服务高价值表面：状态主卡、紧凑信息胶囊、底部主动作。
- 所有关键状态继续以本地计算结果为真源。

## Information Architecture

### Header
- 不再使用标准大标题导航栏，而是自定义顶部标题。
- 标题固定为 `今天`，下面用一行极短说明承接“当前体内 + 入睡残留”的语义。

### Hero
- 首页主卡必须成为第一视觉锚点。
- 主卡内固定包含：
  - `今晚状态` 标签
  - 当前体内咖啡因大数字
  - 入睡时间和预计残留
  - 一个图形化状态对象
  - 紧凑的睡眠相关胶囊信息
- 主卡不再放长段解释，也不再放多个并列 CTA。

### Mini Timeline
- 主卡下方使用一张紧凑时间卡表达“从现在到入睡”的下降过程。
- 图形采用易扫读的竖向 bars，并明确标出：
  - 现在
  - 入睡时间
  - 参考安全线
- 若存在 `recommendedSleepTime` 且晚于当前入睡计划，可在卡片中弱提示“更稳时间”。

### Recent Entries
- 最近记录只保留紧凑列表，不再抢 hero 权重。
- 默认最多显示 3 条，主要承担“我今天喝了什么”的回顾作用。

### Primary Action
- `记一杯` 固定为首页底部浮动主动作。
- 该按钮必须在首屏可见，并明显强于最近记录等次级信息。

## Validation
- `swift test`
- `xcodebuild -project ios/Yinzhi.xcodeproj -scheme Yinzhi -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
- 人工检查：
  - 首页首屏存在一个明确主卡，而不是多个同权重模块
  - 首页首屏的主要可读信息只围绕当前体内、入睡残留和主动作
  - `记一杯` 在首页底部保持明显主位
