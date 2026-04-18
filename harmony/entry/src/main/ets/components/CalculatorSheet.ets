import { createDrinkFromCalculator, createTemplateFromCalculator, defaultCalculatorInput, estimateCalculatorCaffeine } from '../model/CaffeineEngine'
import { CalculatorBrewMethod, CalculatorInput, GrindLevel, RoastLevel, UserDrinkTemplate, DrinkDefinition } from '../model/Types'
import { PagePalette, SectionTitle } from './Common'

@Component
export struct CalculatorSheet {
  onDismiss: () => void = () => {}
  onSaveTemplate: (template: UserDrinkTemplate) => void = (_template: UserDrinkTemplate) => {}
  onRecordDrink: (drink: DrinkDefinition) => void = (_drink: DrinkDefinition) => {}

  @State input: CalculatorInput = defaultCalculatorInput()

  build() {
    Column({ space: 16 }) {
      Row() {
        Button('关闭')
          .fontSize(14)
          .backgroundColor(PagePalette.secondarySurface)
          .onClick(() => this.onDismiss())
        Blank()
        Text('咖啡因计算器')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(PagePalette.ink)
        Blank()
        Button('完成')
          .fontSize(14)
          .backgroundColor(PagePalette.accentSoft)
          .onClick(() => this.onDismiss())
      }

      Column({ space: 12 }) {
        SectionTitle({ title: '冲煮方式', subtitle: '先选方式，再微调参数。' })
        Row({ space: 10 }) {
          this.methodButton(CalculatorBrewMethod.Espresso, '意式')
          this.methodButton(CalculatorBrewMethod.PourOver, '手冲')
          this.methodButton(CalculatorBrewMethod.Capsule, '胶囊')
        }
      }

      Column({ space: 12 }) {
        this.sliderCard('咖啡粉', `${Math.round(this.input.beansGrams)}g`, this.input.beansGrams, 5, 30, (value: number) => {
          this.input.beansGrams = value
        })
        this.sliderCard('水量', `${Math.round(this.input.waterML)}mL`, this.input.waterML, 30, 450, (value: number) => {
          this.input.waterML = value
        })
      }

      Row({ space: 10 }) {
        this.selectionCard('烘焙', roastLabel(this.input.roastLevel), () => {
          this.input.roastLevel = nextRoast(this.input.roastLevel)
        })
        this.selectionCard('研磨', grindLabel(this.input.grindLevel), () => {
          this.input.grindLevel = nextGrind(this.input.grindLevel)
        })
      }

      Column({ space: 6 }) {
        Text('估算咖啡因含量')
          .fontSize(12)
          .fontColor(PagePalette.muted)
        Text(`${estimateCalculatorCaffeine(this.input)} mg`)
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor(PagePalette.orange)
      }
      .alignItems(HorizontalAlign.Center)
      .width('100%')
      .padding(18)
      .backgroundColor(PagePalette.secondarySurface)
      .borderRadius(24)

      Row({ space: 10 }) {
        Button('存为我的饮品')
          .layoutWeight(1)
          .backgroundColor(PagePalette.secondarySurface)
          .fontColor(PagePalette.ink)
          .onClick(() => {
            this.onSaveTemplate(createTemplateFromCalculator(this.input))
            this.onDismiss()
          })

        Button('记这一杯')
          .layoutWeight(1)
          .backgroundColor(PagePalette.accent)
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.onRecordDrink(createDrinkFromCalculator(this.input))
            this.onDismiss()
          })
      }
    }
    .padding(20)
    .width('100%')
    .backgroundColor(PagePalette.surface)
    .borderRadius({ topLeft: 28, topRight: 28 })
  }

  @Builder
  private methodButton(method: CalculatorBrewMethod, label: string) {
    Button(label)
      .layoutWeight(1)
      .fontColor(this.input.method === method ? '#FFFFFF' : PagePalette.ink)
      .backgroundColor(this.input.method === method ? PagePalette.accent : PagePalette.secondarySurface)
      .onClick(() => {
        this.input.method = method
        if (method === CalculatorBrewMethod.Espresso) {
          this.input.beansGrams = 18
          this.input.waterML = 36
          this.input.roastLevel = RoastLevel.Medium
          this.input.grindLevel = GrindLevel.Fine
        } else if (method === CalculatorBrewMethod.PourOver) {
          this.input.beansGrams = 18
          this.input.waterML = 300
          this.input.roastLevel = RoastLevel.Light
          this.input.grindLevel = GrindLevel.Medium
        } else {
          this.input.beansGrams = 6
          this.input.waterML = 40
          this.input.roastLevel = RoastLevel.Medium
          this.input.grindLevel = GrindLevel.Standard
        }
      })
  }

  @Builder
  private sliderCard(title: string, valueText: string, value: number, min: number, max: number, onChange: (value: number) => void) {
    Column({ space: 10 }) {
      Row() {
        Text(title)
          .fontSize(14)
          .fontColor(PagePalette.muted)
        Blank()
        Text(valueText)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(PagePalette.ink)
      }
      Slider({
        value: value,
        min: min,
        max: max,
        step: 1,
        style: SliderStyle.OutSet
      })
        .selectedColor(PagePalette.accent)
        .blockColor(PagePalette.orange)
        .onChange((sliderValue: number) => onChange(sliderValue))
    }
    .padding(16)
    .backgroundColor(PagePalette.secondarySurface)
    .borderRadius(22)
  }

  @Builder
  private selectionCard(title: string, valueText: string, onTap: () => void) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(14)
        .fontColor(PagePalette.muted)
      Text(valueText)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(PagePalette.ink)
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .padding(16)
    .backgroundColor(PagePalette.secondarySurface)
    .borderRadius(22)
    .onClick(() => onTap())
  }
}

function roastLabel(level: RoastLevel): string {
  if (level === RoastLevel.Light) {
    return '浅度'
  }
  if (level === RoastLevel.Dark) {
    return '深度'
  }
  return '中度'
}

function grindLabel(level: GrindLevel): string {
  if (level === GrindLevel.Fine) {
    return '细'
  }
  if (level === GrindLevel.Medium) {
    return '中'
  }
  if (level === GrindLevel.Coarse) {
    return '粗'
  }
  return '标准'
}

function nextRoast(level: RoastLevel): RoastLevel {
  if (level === RoastLevel.Light) {
    return RoastLevel.Medium
  }
  if (level === RoastLevel.Medium) {
    return RoastLevel.Dark
  }
  return RoastLevel.Light
}

function nextGrind(level: GrindLevel): GrindLevel {
  if (level === GrindLevel.Fine) {
    return GrindLevel.Standard
  }
  if (level === GrindLevel.Standard) {
    return GrindLevel.Medium
  }
  if (level === GrindLevel.Medium) {
    return GrindLevel.Coarse
  }
  return GrindLevel.Fine
}
