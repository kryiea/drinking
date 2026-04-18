import { DirectoryScope, DrinkDefinition, DrinkLogEntry, DrinkServingOption, IngredientMetrics, UserDrinkTemplate } from '../model/Types'
import { BrandBadge, PagePalette, SectionTitle, brandMonogram } from './Common'

@Component
export struct LogPage {
  catalog: DrinkDefinition[] = []
  templates: UserDrinkTemplate[] = []
  logs: DrinkLogEntry[] = []
  onRecordDrink: (drink: DrinkDefinition, source?: string) => void = (_drink: DrinkDefinition, _source?: string) => {}
  onOpenCalculator: () => void = () => {}
  onPlaceholderAction: (title: string) => void = (_title: string) => {}

  @State query: string = ''
  @State selectedBrand: string = '全部'
  @State selectedScope: DirectoryScope = DirectoryScope.Coffee

  private brands(): string[] {
    const inScope = this.selectedScope === DirectoryScope.Mine
      ? this.templates.map((item) => item.brand)
      : this.catalog
          .filter((item) => this.selectedScope === DirectoryScope.Coffee ? item.category.indexOf('咖啡') >= 0 : item.category.indexOf('奶茶') >= 0 || item.category.indexOf('果茶') >= 0)
          .map((item) => item.brand)

    return ['全部', ...Array.from(new Set(inScope))]
  }

  private recentDrinks(): DrinkDefinition[] {
    return this.logs.slice(0, 4).map((entry) => {
      const found = this.catalog.find((item) => item.id === entry.drinkDefinitionID)
      if (found) {
        return found
      }
      const metrics: IngredientMetrics = entry.metrics
      const servingOptions: DrinkServingOption[] = [
        { id: 'default', name: entry.servingLabel, volumeML: Math.round(entry.metrics.volumeML), multiplier: 1.0 }
      ]
      const generated: DrinkDefinition = {
        id: entry.id,
        name: entry.drinkName,
        category: entry.category,
        brand: entry.brand,
        brandCollection: '最近',
        tags: ['最近'],
        heroFlavor: '最近记录',
        preparationMethods: entry.preparationMethod ? [entry.preparationMethod] : [],
        metrics,
        servingOptions
      }
      return generated
    })
  }

  private featuredTemplates(): DrinkDefinition[] {
    const drinks: DrinkDefinition[] = []
    this.templates.forEach((template: UserDrinkTemplate) => {
      const metrics: IngredientMetrics = {
        caffeineMG: template.caffeineMG,
        sugarG: template.sugarG,
        caloriesKcal: 0,
        hydrationML: template.volumeML,
        volumeML: template.volumeML
      }
      const servingOptions: DrinkServingOption[] = [
        { id: 'default', name: '标准杯', volumeML: template.volumeML, multiplier: 1.0 }
      ]
      const drink: DrinkDefinition = {
        id: template.id,
        name: template.name,
        category: template.category,
        brand: template.brand,
        brandCollection: '我的饮品',
        tags: ['自定义'],
        heroFlavor: '自定义饮品',
        preparationMethods: template.preparationMethod ? [template.preparationMethod] : [],
        metrics,
        servingOptions
      }
      drinks.push(drink)
    })
    return drinks
  }

  private filteredCatalog(): DrinkDefinition[] {
    let source = this.selectedScope === DirectoryScope.Mine ? this.featuredTemplates() : this.catalog.filter((item) => {
      if (this.selectedScope === DirectoryScope.Coffee) {
        return item.category.indexOf('咖啡') >= 0
      }
      return item.category.indexOf('奶茶') >= 0 || item.category.indexOf('果茶') >= 0
    })

    if (this.selectedBrand !== '全部') {
      source = source.filter((item) => item.brand === this.selectedBrand)
    }

    if (this.query.trim().length > 0) {
      const keyword = this.query.trim().toLowerCase()
      source = source.filter((item) => {
        return item.name.toLowerCase().indexOf(keyword) >= 0 ||
          item.brand.toLowerCase().indexOf(keyword) >= 0 ||
          item.category.toLowerCase().indexOf(keyword) >= 0
      })
    }

    return source
  }

  private directoryTitle(): string {
    if (this.selectedScope === DirectoryScope.Coffee) {
      return '主流咖啡'
    }
    if (this.selectedScope === DirectoryScope.MilkTea) {
      return '主流奶茶'
    }
    return '我的饮品'
  }

  private recordMostRecentDrink(): void {
    const recent = this.recentDrinks()[0]
    if (recent) {
      this.onRecordDrink(recent, 'recent')
    }
  }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        SectionTitle({ title: '记一杯', subtitle: '搜到就记，不先读说明。' })

        TextInput({ placeholder: '搜索品牌、饮品或口味', text: $$this.query })
          .height(52)
          .padding({ left: 16, right: 16 })
          .backgroundColor(PagePalette.surface)
          .borderRadius(26)

        Flex({ wrap: FlexWrap.Wrap }) {
            this.quickAction('语音', () => this.onPlaceholderAction('语音输入待接 HarmonyOS 系统能力'))
            this.quickAction('拍照', () => this.onPlaceholderAction('拍照识别待接 HarmonyOS 系统能力'))
            this.quickAction('相册', () => this.onPlaceholderAction('相册识别待接 HarmonyOS 系统能力'))
            this.quickAction('计算器', () => this.onOpenCalculator())
            this.quickAction('最近一杯', () => this.recordMostRecentDrink())
        }

        Row({ space: 10 }) {
          this.scopeButton(DirectoryScope.Coffee, '咖啡')
          this.scopeButton(DirectoryScope.MilkTea, '奶茶')
          this.scopeButton(DirectoryScope.Mine, '我的')
        }

        if (this.selectedScope !== DirectoryScope.Mine) {
          Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.brands(), (brand: string) => {
                Column({ space: 6 }) {
                  Text(brand === '全部' ? '全' : brandMonogram(brand))
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.selectedBrand === brand ? '#FFFFFF' : PagePalette.ink)
                    .width(40)
                    .height(40)
                    .textAlign(TextAlign.Center)
                    .backgroundColor(this.selectedBrand === brand ? PagePalette.accent : PagePalette.surface)
                    .borderRadius(20)
                    .onClick(() => {
                      this.selectedBrand = brand
                    })
                    .margin({ right: 12, bottom: 12 })
                }
              }, (brand: string) => brand)
          }
        }

        if (this.query.length === 0 && this.recentDrinks().length > 0) {
          this.rowSection('最近', '最近点过的几杯放前面', this.recentDrinks())
        }

        if (this.query.length === 0 && this.featuredTemplates().length > 0) {
          this.rowSection('我的饮品', '自己常喝的几杯先放前面', this.featuredTemplates())
        }

        this.rowSection(this.directoryTitle(), '点一行就能记录', this.filteredCatalog())
      }
      .padding({ left: 16, right: 16, top: 20, bottom: 112 })
      .alignItems(HorizontalAlign.Start)
    }
    .scrollBar(BarState.Off)
    .backgroundColor(PagePalette.background)
    .width('100%')
    .height('100%')
  }

  @Builder
  private quickAction(title: string, onTap: () => void) {
    Button(title)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor(PagePalette.ink)
      .backgroundColor(PagePalette.surface)
      .borderRadius(22)
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .onClick(() => onTap())
  }

  @Builder
  private scopeButton(scope: DirectoryScope, label: string) {
    Button(label)
      .layoutWeight(1)
      .fontColor(this.selectedScope === scope ? '#FFFFFF' : PagePalette.ink)
      .backgroundColor(this.selectedScope === scope ? PagePalette.accent : PagePalette.surface)
      .borderRadius(20)
      .onClick(() => {
        this.selectedScope = scope
        this.selectedBrand = '全部'
      })
  }

  @Builder
  private rowSection(title: string, subtitle: string, drinks: DrinkDefinition[]) {
    Column({ space: 10 }) {
      SectionTitle({ title, subtitle })
      ForEach(drinks, (drink: DrinkDefinition) => {
        Row({ space: 12 }) {
          BrandBadge({ brand: drink.brand, tint: PagePalette.accent })
          Column({ space: 4 }) {
            Text(drink.name)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(PagePalette.ink)
            Text(`${Math.round(drink.metrics.caffeineMG)}mg · ${drink.servingOptions[0].name}`)
              .fontSize(12)
              .fontColor(PagePalette.muted)
          }
          .layoutWeight(1)

          Button('记')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor(PagePalette.accent)
            .borderRadius(16)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .onClick(() => this.onRecordDrink(drink, 'catalog'))
        }
        .padding(14)
        .backgroundColor(PagePalette.surface)
        .borderRadius(22)
      }, (drink: DrinkDefinition) => drink.id)
    }
    .width('100%')
  }
}
