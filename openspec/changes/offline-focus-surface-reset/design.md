# Design: Offline Focus Surface Reset

## Scope
- `ios/Yinzhi/Features/Home/HomeView.swift`
- `ios/Yinzhi/Features/Log/LogView.swift`
- `ios/Yinzhi/Features/Insights/InsightsView.swift`
- `ios/Yinzhi/Features/Profile/ProfileView.swift`
- 可能补充少量共用视图

## Design Principles
- 离线优先：即使不连接后端，也能完成核心查看与记录。
- 少字优先：用层级、色彩、数字和结构代替大段说明。
- 一级页只做“判断 / 记录 / 查看 / 进入设置”，复杂操作进入二级页面。

## Home
- 保留单一 hero，用于展示：
  - 当前体内咖啡因
  - 入睡时预计残留
  - 一个主按钮：`记一杯`
- 移除首页上的其它结构性统计和解释性模块。
- 配色更大胆，减少白色大面板堆叠感。

## Log
- 顶部为记录入口：
  - 主按钮：`记一杯`
  - 次级入口：语音、拍照、相册、咖啡因计算器
- 中下部为品牌目录：
  - 一级切换：`咖啡` / `奶茶` / `我的`
  - 品牌 chips
  - 饮品统一使用横条 row
- Brew Lab 继续保留，但作为从 row 进入的次级动作。

## Insights
- 移除糖分、补水和结构条等次要统计。
- 用更直观的“时间轨道 + 关键点 + 摄入事件”表达今日咖啡因变化。
- 页面只保留：
  - 当前值
  - 入睡点
  - 时间轨道视图
  - 当日摄入事件

## Profile
- 改成标准 `List` 结构。
- 一级只展示几个入口：
  - 睡眠时间
  - 代谢速度
  - 同步与数据
  - 我的饮品
  - 开发连接（仅可用时）
- 每项进入二级页面后再做具体设置或动作。

## Validation
- `swift test`
- `xcodebuild -project ios/Yinzhi.xcodeproj -scheme Yinzhi -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
- 人工检查：
  - 首页首屏不再出现与核心无关的统计块
  - 记录页默认目录为横条 row
  - 分析页主视图能一眼看出当前点、入睡点和趋势
  - 我的页为多级列表结构
