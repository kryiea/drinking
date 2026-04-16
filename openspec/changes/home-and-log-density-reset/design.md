# Design: Home And Log Density Reset

## Scope
- `ios/Yinzhi/Features/Home/HomeView.swift`
- `ios/Yinzhi/Features/Log/LogView.swift`
- 可能影响通用设计组件：`ios/Yinzhi/Core/Design/DesignSystem.swift`

## Design Goals

### 首页
- 首屏只回答三个问题：
  - 我现在状态如何
  - 睡前大概还剩多少咖啡因
  - 现在最应该点哪个动作
- 从“dashboard”收口成“状态判断页”，减少 section 并降低解释性文字占比。

### 记录页
- 首屏只突出一个主路径：`记一杯`
- 快速操作遵循优先级：
  - 主 CTA：打开快速记录入口
  - 次级动作：语音、拍照、相册、最近复用
  - 下层内容：最近 / 常喝 / 我的饮品 / 品牌入口
- 完整目录留在页面下半段，默认卡片改为更紧凑、更适合连续点按的布局。

## Home Information Architecture

### Before
- 大 hero + 快速记录 + 最近两杯 + 今日分布
- 首屏中标题、状态、两个指标、三个 pill、两个按钮同时竞争注意力

### After
- `Tonight Hero`
  - 单句状态判断
  - 一行睡前残留说明
  - 两个大指标：当前估算 / 睡前残留
  - 一个主动作和一个次动作
- `Mini Timeline`
  - 最近两杯改为更短的横向时间胶囊，不再单独做大 section
- `Quick Stats Strip`
  - 今日杯数、累计摄入、待同步收缩成轻量状态条

### Home Visual Rules
- hero 承担主要玻璃层级，其他信息块降低视觉权重
- 次级说明文本控制在一行或两行内
- 用状态色而不是长句驱动风险感知

## Log Information Architecture

### Before
- 命令区使用四宫格平铺快入口，四个入口权重接近
- 品牌目录直接大面积铺开，默认卡片仍偏大
- 完整目录和“立即记录”在首屏争抢主导权

### After
- `Quick Capture Hero`
  - 单个主按钮：`记一杯`
  - 次级入口：语音、拍照、相册
  - 最近一杯作为可直接复用的强次级动作
- `Fast Lanes`
  - 最近记录条
  - 常喝快记胶囊
  - 我的饮品管理
- `Catalog Browser`
  - 品牌与冲煮方式筛选保持存在，但文案更短
  - 主流咖啡 / 主流奶茶改用更紧凑的双列小卡，而不是大行式卡片
- `Brew Lab`
  - 仍为单独展开区，但只在用户明确进入时出现

### Log Visual Rules
- 快速记录 hero 使用最强玻璃层级
- 默认 catalog card 只展示：
  - 品牌
  - 名称
  - 咖啡因数值
  - 一个 `+`
- 次级信息如冲煮方式、风味、糖分只在必要时显示，避免让每张卡片都变成说明书

## Interaction Notes
- 保留现有 next-step rail，但让它位于 quick hero 后方，成为成功后的上下文延续
- `记一杯` 主按钮展开的快速入口应优先服务单手操作和连续记录，不再要求用户先阅读多个 tile
- 若用户已有最近一杯，hero 内要显式提供“再来一杯”

## Validation
- `swift test`
- `xcodebuild -project ios/Yinzhi.xcodeproj -scheme Yinzhi -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
- 人工检查：
  - 首页首屏不滚动即可看懂状态和主动作
  - 记录页首屏可以不浏览目录就完成一次记录
  - 记录页默认目录卡片较旧版本更紧凑，扫读更快
