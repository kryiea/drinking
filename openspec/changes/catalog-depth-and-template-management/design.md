# Design: Catalog Depth And Template Management

## Scope
- Expand catalog seeds for coffee-first daily logging
- Add user drink template management flow

## Catalog Depth
- 咖啡新增高频品牌 / 款式：
  - 库迪 `生椰米乳拿铁`
  - 幸运咖 `厚乳拿铁`
  - Seesaw `黑巧美式`
- 奶茶新增高频品牌 / 款式：
  - 茶百道 `豆乳玉麒麟`
  - 古茗 `超 A 芝士葡萄`
  - 沪上阿姨 `杨枝甘露`
- 这些 seed 需要同时更新：
  - iOS `PreviewFixtures`
  - backend `seed_drink_definitions`

## User Template Management
- 当前个人饮品仅支持新增，后续改为完整最小 CRUD：
  - 查看个人饮品列表
  - 编辑已有模板
  - 删除模板
- 管理入口放在记录页“我添加的饮品”分区中，不额外打断主导航结构。
- 新增与编辑共用一套表单，避免两份规则漂移。
- 删除动作允许直接执行，但必须给明确反馈文案。

## Validation
- `swift test`
- `xcodebuild -project ios/Yinzhi.xcodeproj -scheme Yinzhi -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
- 客户端 smoke tests 覆盖：
  - user template update
  - user template delete
