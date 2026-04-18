export class PagePalette {
  static readonly background: string = '#F3F5F4'
  static readonly surface: string = '#FFFFFF'
  static readonly secondarySurface: string = '#EEF4F0'
  static readonly ink: string = '#162424'
  static readonly muted: string = '#697472'
  static readonly accent: string = '#1A8A69'
  static readonly accentSoft: string = '#DCEFE7'
  static readonly orange: string = '#F39C62'
  static readonly divider: string = '#E4ECE7'
  static readonly warning: string = '#D05B42'
}

export function brandMonogram(brand: string): string {
  if (brand.length === 0) {
    return '饮'
  }
  if (brand === 'Blue Bottle') {
    return 'B'
  }
  if (brand === 'MANNER') {
    return 'M'
  }
  return brand.substring(0, 1)
}

@Component
export struct BrandBadge {
  brand: string = ''
  badgeSize: number = 36
  tint: string = PagePalette.accent

  build() {
    Text(brandMonogram(this.brand))
      .fontSize(this.badgeSize * 0.45)
      .fontWeight(FontWeight.Bold)
      .fontColor('#FFFFFF')
      .width(this.badgeSize)
      .height(this.badgeSize)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.tint)
      .borderRadius(this.badgeSize / 2)
  }
}

@Component
export struct MetricPill {
  title: string = ''
  value: string = ''
  tint: string = PagePalette.ink

  build() {
    Column({ space: 4 }) {
      Text(this.title)
        .fontSize(12)
        .fontColor(PagePalette.muted)
      Text(this.value)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.tint)
    }
    .alignItems(HorizontalAlign.Start)
    .padding(14)
    .backgroundColor(PagePalette.secondarySurface)
    .borderRadius(20)
    .layoutWeight(1)
  }
}

@Component
export struct SectionTitle {
  title: string = ''
  subtitle: string = ''

  build() {
    Column({ space: 4 }) {
      Text(this.title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(PagePalette.ink)
      if (this.subtitle.length > 0) {
        Text(this.subtitle)
          .fontSize(12)
          .fontColor(PagePalette.muted)
      }
    }
    .alignItems(HorizontalAlign.Start)
  }
}
