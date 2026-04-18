import { buildForecast } from '../model/CaffeineEngine'
import {
  CaffeineForecast,
  CaffeineForecastPoint,
  CaffeineMetabolismProfile,
  DrinkLogEntry,
  SleepReadinessState,
  UserPreferences
} from '../model/Types'
import { MetricPill, PagePalette, SectionTitle, BrandBadge } from './Common'

@Component
export struct HomePage {
  logs: DrinkLogEntry[] = []
  preferences: UserPreferences = {
    sleepHour: 23,
    sleepMinute: 30,
    metabolismProfile: CaffeineMetabolismProfile.Standard,
    iCloudPlanEnabled: false,
    watchPlanEnabled: false
  }
  onOpenLog: () => void = () => {}

  private tintFor(stage: SleepReadinessState): string {
    if (stage === SleepReadinessState.SleepFriendly) {
      return PagePalette.accent
    }
    if (stage === SleepReadinessState.Watch) {
      return PagePalette.orange
    }
    return PagePalette.warning
  }

  private forecast(): CaffeineForecast {
    return buildForecast(this.logs, this.preferences)
  }

  private recentEntries(): DrinkLogEntry[] {
    return this.logs.slice(0, 3)
  }

  private isSleepPoint(point: CaffeineForecastPoint): boolean {
    return point.id.startsWith('sleep-')
  }

  private timelineBarHeight(point: CaffeineForecastPoint): number {
    const currentEstimate = Math.max(this.forecast().currentEstimateMG, 1)
    return Math.max(point.remainingCaffeineMG / currentEstimate * 150, 18)
  }

  private timelinePointLabel(point: CaffeineForecastPoint): string {
    if (this.isSleepPoint(point)) {
      return this.forecast().sleepAtText
    }
    return `${new Date(point.atISO).getHours()}`
  }

  private recordedTimeText(entry: DrinkLogEntry): string {
    return entry.consumedAtISO.substring(11, 16)
  }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Column({ space: 6 }) {
          Text('今天')
            .fontSize(38)
            .fontWeight(FontWeight.Bold)
            .fontColor(PagePalette.ink)
          Text('只看当前体内咖啡因和今晚入睡。')
            .fontSize(14)
            .fontColor(PagePalette.muted)
        }
        .alignItems(HorizontalAlign.Start)

        Column({ space: 18 }) {
          Row({ space: 14 }) {
            Column({ space: 12 }) {
              Text(stageLabel(this.forecast().sleepReadiness))
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.tintFor(this.forecast().sleepReadiness))
                .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .backgroundColor(PagePalette.accentSoft)
                .borderRadius(999)

              Row() {
                Text(`${Math.round(this.forecast().currentEstimateMG)}`)
                  .fontSize(54)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(PagePalette.ink)
                Text('mg')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.tintFor(this.forecast().sleepReadiness))
                  .margin({ top: 26, left: 6 })
              }

              Text('当前体内咖啡因')
                .fontSize(12)
                .fontColor(PagePalette.muted)

              Text(`${this.forecast().sleepAtText} 入睡时约 ${Math.round(this.forecast().projectedSleepMG)}mg`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(PagePalette.ink)

              if (this.forecast().recommendedSleepTimeText) {
                Text(`更稳时间大约 ${this.forecast().recommendedSleepTimeText}`)
                  .fontSize(12)
                  .fontColor(this.tintFor(this.forecast().sleepReadiness))
              }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Text('☕')
              .fontSize(34)
              .width(84)
              .height(84)
              .textAlign(TextAlign.Center)
              .backgroundColor(PagePalette.accentSoft)
              .borderRadius(42)
              .margin({ top: 8 })
          }

          Row({ space: 10 }) {
            MetricPill({ title: '入睡', value: this.forecast().sleepAtText, tint: PagePalette.ink })
            MetricPill({
              title: '预计残留',
              value: `${Math.round(this.forecast().projectedSleepMG)}mg`,
              tint: this.tintFor(this.forecast().sleepReadiness)
            })
          }
        }
        .padding(20)
        .backgroundColor(PagePalette.surface)
        .borderRadius(32)

        Column({ space: 14 }) {
          SectionTitle({ title: '从现在到入睡', subtitle: '看体内咖啡因会怎样往下走。' })
          Row({ space: 10 }) {
            ForEach(this.forecast().timeline, (point: CaffeineForecastPoint) => {
              Column({ space: 8 }) {
                Column()
                  .width(30)
                  .height(this.timelineBarHeight(point))
                  .backgroundColor(this.isSleepPoint(point) ? this.tintFor(point.stage) : PagePalette.orange)
                  .borderRadius(15)
                Text(this.timelinePointLabel(point))
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(PagePalette.muted)
                Text(`${Math.round(point.remainingCaffeineMG)}mg`)
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.isSleepPoint(point) ? this.tintFor(point.stage) : PagePalette.ink)
              }
              .justifyContent(FlexAlign.End)
              .height(220)
            }, (point: CaffeineForecastPoint) => point.id)
          }
          .alignItems(VerticalAlign.Bottom)
        }
        .padding(20)
        .backgroundColor(PagePalette.surface)
        .borderRadius(30)

        if (this.recentEntries().length > 0) {
          Column({ space: 12 }) {
            SectionTitle({ title: '今天喝过', subtitle: `${this.recentEntries().length} 杯最近记录` })
            ForEach(this.recentEntries(), (entry: DrinkLogEntry) => {
              Row({ space: 12 }) {
                BrandBadge({ brand: entry.brand, tint: PagePalette.accent })
                Column({ space: 4 }) {
                  Text(entry.drinkName)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(PagePalette.ink)
                  Text(`${entry.brand} · ${Math.round(entry.metrics.caffeineMG)}mg`)
                    .fontSize(12)
                    .fontColor(PagePalette.muted)
                }
                .layoutWeight(1)
                Text(this.recordedTimeText(entry))
                  .fontSize(12)
                  .fontColor(PagePalette.muted)
              }
              .padding(14)
              .backgroundColor(PagePalette.secondarySurface)
              .borderRadius(22)
            }, (entry: DrinkLogEntry) => entry.id)
          }
          .padding(18)
          .backgroundColor(PagePalette.surface)
          .borderRadius(28)
        }

        Button('记一杯')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .width('100%')
          .height(56)
          .backgroundColor(PagePalette.accent)
          .borderRadius(28)
          .onClick(() => this.onOpenLog())
      }
      .padding({ left: 16, right: 16, top: 20, bottom: 112 })
      .alignItems(HorizontalAlign.Start)
    }
    .scrollBar(BarState.Off)
    .backgroundColor(PagePalette.background)
    .width('100%')
    .height('100%')
  }
}

function stageLabel(stage: SleepReadinessState): string {
  if (stage === SleepReadinessState.SleepFriendly) {
    return '今晚还稳'
  }
  if (stage === SleepReadinessState.Watch) {
    return '今晚收一点'
  }
  return '今晚先别再加'
}
