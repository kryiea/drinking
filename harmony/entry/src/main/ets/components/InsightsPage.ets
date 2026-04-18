import { buildForecast, metabolismHalfLifeHours, nextSleepDate, remainingCaffeineAt } from '../model/CaffeineEngine'
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
export struct InsightsPage {
  logs: DrinkLogEntry[] = []
  preferences: UserPreferences = {
    sleepHour: 23,
    sleepMinute: 30,
    metabolismProfile: CaffeineMetabolismProfile.Standard,
    iCloudPlanEnabled: false,
    watchPlanEnabled: false
  }

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

  private entryTimeText(entry: DrinkLogEntry): string {
    return entry.consumedAtISO.substring(11, 16)
  }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Column({ space: 10 }) {
          SectionTitle({ title: '咖啡因视图', subtitle: '只看当前和入睡时。' })
          Row({ space: 10 }) {
            MetricPill({ title: '现在', value: `${Math.round(this.forecast().currentEstimateMG)}mg`, tint: PagePalette.ink })
            MetricPill({
              title: this.forecast().sleepAtText,
              value: `${Math.round(this.forecast().projectedSleepMG)}mg`,
              tint: this.tintFor(this.forecast().sleepReadiness)
            })
          }
        }
        .padding(18)
        .backgroundColor(PagePalette.surface)
        .borderRadius(28)

        Column({ space: 12 }) {
          SectionTitle({ title: '从现在到入睡', subtitle: '看下降速度和睡前位置。' })
          ForEach(this.forecast().timeline, (point: CaffeineForecastPoint) => {
            Row({ space: 12 }) {
              Column({ space: 4 }) {
                Text(point.id.startsWith('sleep-') ? '入睡' : point.atISO.substring(11, 16))
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(PagePalette.ink)
                Text(point.id.startsWith('sleep-') ? '目标入睡时间' : '体内剩余估算')
                  .fontSize(12)
                  .fontColor(PagePalette.muted)
              }
              .layoutWeight(1)

              Text(`${Math.round(point.remainingCaffeineMG)}mg`)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.tintFor(point.stage))
            }
            .padding(16)
            .backgroundColor(PagePalette.secondarySurface)
            .borderRadius(22)
          }, (point: CaffeineForecastPoint) => point.id)
        }
        .padding(18)
        .backgroundColor(PagePalette.surface)
        .borderRadius(28)

        Column({ space: 12 }) {
          SectionTitle({ title: '今天喝过', subtitle: '看每一杯对今晚的拖尾。' })
          ForEach(this.logs, (entry: DrinkLogEntry) => {
            Row({ space: 12 }) {
              BrandBadge({ brand: entry.brand, tint: PagePalette.accent })
              Column({ space: 4 }) {
                Text(entry.drinkName)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(PagePalette.ink)
                Text(this.entryTimeText(entry))
                  .fontSize(12)
                  .fontColor(PagePalette.muted)
              }
              .layoutWeight(1)
              Text(`睡前约 ${Math.round(this.projectedSleepContribution(entry))}mg`)
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
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
      .padding({ left: 16, right: 16, top: 20, bottom: 112 })
      .alignItems(HorizontalAlign.Start)
    }
    .scrollBar(BarState.Off)
    .backgroundColor(PagePalette.background)
    .width('100%')
    .height('100%')
  }

  private projectedSleepContribution(entry: DrinkLogEntry): number {
    const sleepDate = nextSleepDate(this.preferences)
    return remainingCaffeineAt([entry], sleepDate, metabolismHalfLifeHours(this.preferences.metabolismProfile))
  }
}
