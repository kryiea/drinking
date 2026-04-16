# Design: Record Selector And Calculator Refresh

## Scope
- `ios/Yinzhi/Features/Log/LogView.swift`
- `ios/Yinzhi/Core/Models/` 中的本地估算辅助类型
- `ios/YinzhiTests/`
- `docs/product/v1-scope.md`
- `agent.md`

## Record Page Direction

### Information Architecture
- 顶部先出现轻量标题与搜索框。
- 搜索框下面固定为品牌圆标带，而不是宽文字 chips。
- 快速入口降为轻量动作行：
  - 语音
  - 拍照
  - 相册
  - 计算器
  - 最近复用
- 主体内容固定为轻量列表 section，而不是大块卡片堆叠。

### List Density
- `最近` 与 `我的饮品` 使用更薄的 row。
- row 固定只保留：
  - 饮品图标 / 品牌标记
  - 名称
  - 品牌 / 咖啡因 / 杯型或容量
  - 右侧日期或加号动作
- 次要说明如风味、冲煮说明不作为默认主文案出现。

### Brand Rail
- 品牌入口使用圆形 monogram / brand mark，优先满足识别效率。
- `全部` 保留在首位。
- 若缺少真实品牌 logo，允许使用稳定的品牌首字 / 首字符替代。

## Calculator Direction

### Structure
- 计算器页顶部先展示当前冲煮方式。
- 中间使用单一主视觉承载冲煮方式，不直接把参数塞满首屏。
- 参数采用 2 列卡片网格，每张卡只承载一类信息。
- 结果区域单独放大，不与参数混排。
- 底部固定双 CTA：
  - 复制咖啡因
  - 存成我的饮品

### Estimation Model
- 估算使用本地确定性模型，不依赖后端。
- 输入至少包含：
  - 冲煮方式
  - 咖啡粉克数
  - 烘焙档位
  - 研磨档位
  - 水量 / 出液量
- 输出为估算咖啡因 mg，并保留简单参数摘要。

## Validation
- `swift test`
- `xcodebuild -project ios/Yinzhi.xcodeproj -scheme Yinzhi -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
- 如果可行，补 iOS 单测运行
- 人工检查：
  - 记录页首屏能在不读长文案的前提下完成选杯路径
  - 品牌圆标带与轻量 row 已替代当前大块功能卡
  - 计算器首屏同时展示冲煮方式、参数卡和估算结果
