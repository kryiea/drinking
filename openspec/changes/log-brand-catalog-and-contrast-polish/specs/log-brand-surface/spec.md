# Log Brand Surface Spec

## Requirements

### Requirement: Home Sleep Threshold Contrast
首页时间图 MUST 让睡眠线与其标签在浅色和深色模式下都清晰可见。

#### Scenario: Light mode threshold remains legible
- **GIVEN** 用户在浅色模式下查看首页时间图
- **WHEN** 睡眠线和“睡眠线”标签出现
- **THEN** 线条与标签都应与背景形成稳定对比

### Requirement: Brand-first Selector Rail
记录页 MUST 使用品牌小 logo 风格的 rail 作为主筛选入口。

#### Scenario: All chip stays icon-only
- **GIVEN** 用户在记录页查看品牌 rail
- **WHEN** 看到“全部”筛选项
- **THEN** 它应只以图形表达，不显示额外的“全部”文字

### Requirement: Compact Drink Rows
记录页 MUST 使用更紧凑的 row，并优先展示 logo、饮品名与核心指标。

#### Scenario: Brand is recognizable without brand text
- **GIVEN** 用户浏览记录页饮品列表
- **WHEN** 同时出现不同品牌的饮品
- **THEN** 用户应主要通过左侧品牌 logo 区分品牌

### Requirement: Preset Mainstream Brands
系统 MUST 预置中国高频咖啡 / 奶茶品牌和代表饮品，用于开箱可记录体验。

#### Scenario: Mainstream seed catalog is available
- **GIVEN** 用户首次进入记录页
- **WHEN** 选择咖啡或奶茶目录
- **THEN** 可以看到瑞幸、星巴克、库迪、喜茶、霸王茶姬、一点点中的代表饮品
