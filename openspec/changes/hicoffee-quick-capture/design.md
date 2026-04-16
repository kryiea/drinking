# Design: HiCoffee-Inspired Quick Capture

## UX Direction
- 首页和记录页都遵循“先动作，后解释”的信息排序。
- 参考 HiCoffee，把高频入口放在更靠前的卡片和系统级快捷交互位置；首版先落在 app 内部，不提前扩展到 widget / watch。
- 记录页顶部改为 Quick Actions Deck，固定承载 `拍照识别`、`相册识别`、`最近一杯`、`AI 选杯 / Brew Lab` 这类低决策成本入口。

## Quick Capture Flow
- 用户在记录页点击图片识别入口后，可以从相机或相册输入图片。
- 客户端使用 on-device OCR 提取文字，不把原始图片上传给后端。
- OCR 文本通过本地匹配器和现有品牌化饮品目录进行模糊匹配，输出最多 3 个候选饮品。
- 若无法匹配，则回退到“带关键词的搜索建议”，避免用户落到死路。

## Technical Notes
- 首版识别实现采用 `Vision` 文本识别；实时取景式 `VisionKit DataScanner` 暂不作为首版主链路，避免引入更多设备能力差异。
- 真机支持相机拍摄；模拟器不强依赖相机，保留相册识别与测试输入路径。
- 匹配器优先使用 `brand / name / category / tags / heroFlavor / brew method` 进行加权匹配，保证结果可解释、可测试。

## Validation
- 增加 OCR 文本匹配单测，覆盖品牌命中、手冲关键词命中和无结果回退。
- 保持现有 Swift smoke tests 与 iOS simulator smoke tests 通过。
