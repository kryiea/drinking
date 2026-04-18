import { CaffeineMetabolismProfile, DrinkLogEntry, UserDrinkTemplate, UserPreferences } from '../model/Types'
import { PagePalette, SectionTitle } from './Common'

@Component
export struct ProfilePage {
  preferences: UserPreferences = {
    sleepHour: 23,
    sleepMinute: 30,
    metabolismProfile: CaffeineMetabolismProfile.Standard,
    iCloudPlanEnabled: false,
    watchPlanEnabled: false
  }
  templates: UserDrinkTemplate[] = []
  logs: DrinkLogEntry[] = []
  onUpdatePreferences: (preferences: UserPreferences) => void = (_preferences: UserPreferences) => {}

  build() {
    Scroll() {
      Column({ space: 18 }) {
        this.sleepSection()
        this.metabolismSection()
        this.syncSection()
        this.templatesSection()
        this.devSection()
      }
      .padding({ left: 16, right: 16, top: 20, bottom: 112 })
      .alignItems(HorizontalAlign.Start)
    }
    .scrollBar(BarState.Off)
    .backgroundColor(PagePalette.background)
    .width('100%')
    .height('100%')
  }

  private createPreferences(
    sleepHour: number,
    sleepMinute: number,
    metabolismProfile: CaffeineMetabolismProfile
  ): UserPreferences {
    return {
      sleepHour,
      sleepMinute,
      metabolismProfile,
      iCloudPlanEnabled: this.preferences.iCloudPlanEnabled,
      watchPlanEnabled: this.preferences.watchPlanEnabled
    }
  }

  @Builder
  private sleepSection() {
    Column({ space: 12 }) {
      SectionTitle({ title: '入睡时间', subtitle: '决定首页和分析页的睡前参考线。' })
      Row({ space: 10 }) {
        this.adjustButton('-1h', (): void => { this.applyTimeDelta(-60) })
        this.adjustButton('-30m', (): void => { this.applyTimeDelta(-30) })
        Text(`${formatValue(this.preferences.sleepHour)}:${formatValue(this.preferences.sleepMinute)}`)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(PagePalette.ink)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        this.adjustButton('+30m', (): void => { this.applyTimeDelta(30) })
        this.adjustButton('+1h', (): void => { this.applyTimeDelta(60) })
      }
    }
    .padding(18)
    .backgroundColor(PagePalette.surface)
    .borderRadius(28)
  }

  @Builder
  private metabolismSection() {
    Column({ space: 12 }) {
      SectionTitle({ title: '代谢速度', subtitle: '决定咖啡因半衰期和睡前阈值。' })
      Row({ space: 10 }) {
        this.profileOption(CaffeineMetabolismProfile.Quick, '代谢偏快')
        this.profileOption(CaffeineMetabolismProfile.Standard, '标准')
        this.profileOption(CaffeineMetabolismProfile.Sensitive, '更敏感')
      }
    }
    .padding(18)
    .backgroundColor(PagePalette.surface)
    .borderRadius(28)
  }

  @Builder
  private syncSection() {
    Column({ space: 10 }) {
      SectionTitle({ title: '同步与数据', subtitle: '当前鸿蒙端先按本地优先路线推进。' })
      Text(this.preferences.iCloudPlanEnabled ? '当前开关处于开启，但 HarmonyOS 端尚未接入正式跨端同步。' : '当前只保留本地记录、我的饮品和设置。')
        .fontSize(13)
        .fontColor(PagePalette.muted)
      Text(`今日记录 ${this.logs.length} 杯`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(PagePalette.ink)
    }
    .padding(18)
    .backgroundColor(PagePalette.surface)
    .borderRadius(28)
  }

  @Builder
  private templatesSection() {
    Column({ space: 10 }) {
      SectionTitle({ title: '我的饮品', subtitle: `${this.templates.length} 个自定义条目` })
      if (this.templates.length === 0) {
        Text('还没有自定义饮品。')
          .fontSize(13)
          .fontColor(PagePalette.muted)
      } else {
        ForEach(this.templates, (template: UserDrinkTemplate) => {
          Column({ space: 4 }) {
            Text(`${template.brand} · ${template.name}`)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(PagePalette.ink)
            Text(`${Math.round(template.caffeineMG)}mg · ${template.volumeML}mL`)
              .fontSize(12)
              .fontColor(PagePalette.muted)
          }
          .alignItems(HorizontalAlign.Start)
          .padding(14)
          .backgroundColor(PagePalette.secondarySurface)
          .borderRadius(20)
        }, (template: UserDrinkTemplate) => template.id)
      }
    }
    .padding(18)
    .backgroundColor(PagePalette.surface)
    .borderRadius(28)
  }

  @Builder
  private devSection() {
    Column({ space: 10 }) {
      SectionTitle({ title: '开发连接', subtitle: '当前鸿蒙端先跑本地数据和本地计算。' })
      Text('后端 typed API、support/admin 和未来跨生态同步仍保留，但当前主链路不依赖远程连接。')
        .fontSize(13)
        .fontColor(PagePalette.muted)
    }
    .padding(18)
    .backgroundColor(PagePalette.surface)
    .borderRadius(28)
  }

  @Builder
  private adjustButton(label: string, onTap: () => void) {
    Button(label)
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(PagePalette.ink)
      .backgroundColor(PagePalette.secondarySurface)
      .borderRadius(18)
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .onClick(() => onTap())
  }

  @Builder
  private profileOption(profile: CaffeineMetabolismProfile, label: string) {
    Button(label)
      .layoutWeight(1)
      .fontSize(13)
      .fontColor(this.preferences.metabolismProfile === profile ? '#FFFFFF' : PagePalette.ink)
      .backgroundColor(this.preferences.metabolismProfile === profile ? PagePalette.accent : PagePalette.secondarySurface)
      .borderRadius(18)
      .onClick(() => {
        this.onUpdatePreferences(this.createPreferences(this.preferences.sleepHour, this.preferences.sleepMinute, profile))
      })
  }

  private applyTimeDelta(deltaMinutes: number) {
    const total = this.preferences.sleepHour * 60 + this.preferences.sleepMinute + deltaMinutes
    const wrapped = (total + 1440) % 1440
    this.onUpdatePreferences(
      this.createPreferences(Math.floor(wrapped / 60), wrapped % 60, this.preferences.metabolismProfile)
    )
  }
}

function formatValue(value: number): string {
  return value < 10 ? `0${value}` : `${value}`
}
