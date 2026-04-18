import { CalculatorSheet } from '../components/CalculatorSheet'
import { HomePage } from '../components/HomePage'
import { InsightsPage } from '../components/InsightsPage'
import { LogPage } from '../components/LogPage'
import { PagePalette } from '../components/Common'
import { ProfilePage } from '../components/ProfilePage'
import { createLogEntry } from '../model/CaffeineEngine'
import { AppTab, DrinkDefinition, DrinkLogEntry, UserDrinkTemplate, UserPreferences } from '../model/Types'
import { bootstrapSnapshot, LocalSnapshot } from '../storage/LocalSnapshotStore'

const INITIAL_SNAPSHOT: LocalSnapshot = bootstrapSnapshot()

@Entry
@Component
struct Index {
  @State selectedTab: AppTab = AppTab.Home
  @State catalog: DrinkDefinition[] = INITIAL_SNAPSHOT.catalog
  @State logs: DrinkLogEntry[] = INITIAL_SNAPSHOT.logs
  @State templates: UserDrinkTemplate[] = INITIAL_SNAPSHOT.templates
  @State preferences: UserPreferences = INITIAL_SNAPSHOT.preferences
  @State isCalculatorVisible: boolean = false
  @State bannerMessage: string = 'HarmonyOS 端已进入正式适配。'

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        if (this.bannerMessage.length > 0) {
          Text(this.bannerMessage)
            .fontSize(12)
            .fontColor(PagePalette.accent)
            .padding({ left: 14, right: 14, top: 10, bottom: 10 })
            .backgroundColor(PagePalette.accentSoft)
            .borderRadius(18)
            .margin({ left: 16, right: 16, top: 12 })
        }

        this.currentSurface()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(PagePalette.background)

      Column({ space: 0 }) {
        if (this.isCalculatorVisible) {
          Stack({ alignContent: Alignment.Bottom }) {
            Column()
              .width('100%')
              .height('100%')
              .backgroundColor('#55000000')
              .onClick(() => {
                this.isCalculatorVisible = false
              })
            CalculatorSheet({
              onDismiss: () => {
                this.isCalculatorVisible = false
              },
              onSaveTemplate: (template: UserDrinkTemplate) => {
                this.templates = [template, ...this.templates]
                this.bannerMessage = `已保存 ${template.name}`
              },
              onRecordDrink: (drink: DrinkDefinition) => {
                this.recordDrink(drink, 'calculator')
              }
            })
          }
          .width('100%')
          .height('100%')
        }

        Row({ space: 8 }) {
          this.tabButton(AppTab.Home, '今日')
          this.tabButton(AppTab.Log, '记录')
          this.tabButton(AppTab.Insights, '图表')
          this.tabButton(AppTab.Profile, '我的')
        }
        .padding(10)
        .margin({ left: 16, right: 16, bottom: 16 })
        .backgroundColor(PagePalette.surface)
        .borderRadius(26)
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private currentSurface() {
    if (this.selectedTab === AppTab.Home) {
      HomePage({
        logs: this.logs,
        preferences: this.preferences,
        onOpenLog: () => {
          this.selectedTab = AppTab.Log
        }
      })
    } else if (this.selectedTab === AppTab.Log) {
      LogPage({
        catalog: this.catalog,
        templates: this.templates,
        logs: this.logs,
        onRecordDrink: (drink: DrinkDefinition, source?: string) => {
          this.recordDrink(drink, source ?? 'catalog')
        },
        onOpenCalculator: () => {
          this.isCalculatorVisible = true
        },
        onPlaceholderAction: (title: string) => {
          this.bannerMessage = title
        }
      })
    } else if (this.selectedTab === AppTab.Insights) {
      InsightsPage({
        logs: this.logs,
        preferences: this.preferences
      })
    } else {
      ProfilePage({
        preferences: this.preferences,
        templates: this.templates,
        logs: this.logs,
        onUpdatePreferences: (nextPreferences: UserPreferences) => {
          this.preferences = nextPreferences
          this.bannerMessage = `入睡时间已更新为 ${pad(this.preferences.sleepHour)}:${pad(this.preferences.sleepMinute)}`
        }
      })
    }
  }

  @Builder
  private tabButton(tab: AppTab, label: string) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.selectedTab === tab ? PagePalette.accent : PagePalette.muted)
    }
    .layoutWeight(1)
    .padding({ top: 10, bottom: 10 })
    .backgroundColor(this.selectedTab === tab ? PagePalette.accentSoft : PagePalette.surface)
    .borderRadius(18)
    .onClick(() => {
      this.selectedTab = tab
    })
  }

  private recordDrink(drink: DrinkDefinition, source: string) {
    const entry = createLogEntry(drink, drink.servingOptions[0], source)
    this.logs = [entry, ...this.logs].sort((lhs: DrinkLogEntry, rhs: DrinkLogEntry) => {
      return new Date(rhs.consumedAtISO).getTime() - new Date(lhs.consumedAtISO).getTime()
    })
    this.selectedTab = AppTab.Home
    this.bannerMessage = `${drink.brand} · ${drink.name} 已记录`
  }
}

function pad(value: number): string {
  return value < 10 ? `0${value}` : `${value}`
}
