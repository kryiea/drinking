import {
  BrewMethod,
  CalculatorBrewMethod,
  CalculatorInput,
  CaffeineForecast,
  CaffeineForecastPoint,
  CaffeineMetabolismProfile,
  DrinkDefinition,
  DrinkLogEntry,
  DrinkServingOption,
  GrindLevel,
  IngredientMetrics,
  RoastLevel,
  SleepReadinessState,
  UserDrinkTemplate,
  UserPreferences
} from './Types'

export function zeroMetrics(): IngredientMetrics {
  return {
    caffeineMG: 0,
    sugarG: 0,
    caloriesKcal: 0,
    hydrationML: 0,
    volumeML: 0
  }
}

export function addMetrics(lhs: IngredientMetrics, rhs: IngredientMetrics): IngredientMetrics {
  return {
    caffeineMG: lhs.caffeineMG + rhs.caffeineMG,
    sugarG: lhs.sugarG + rhs.sugarG,
    caloriesKcal: lhs.caloriesKcal + rhs.caloriesKcal,
    hydrationML: lhs.hydrationML + rhs.hydrationML,
    volumeML: lhs.volumeML + rhs.volumeML
  }
}

export function roundNumber(value: number, places: number = 1): number {
  const divisor = Math.pow(10, places)
  return Math.round(value * divisor) / divisor
}

export function metabolismHalfLifeHours(profile: CaffeineMetabolismProfile): number {
  if (profile === CaffeineMetabolismProfile.Quick) {
    return 4.5
  }
  if (profile === CaffeineMetabolismProfile.Sensitive) {
    return 7.0
  }
  return 5.5
}

export function safeSleepThreshold(profile: CaffeineMetabolismProfile): number {
  if (profile === CaffeineMetabolismProfile.Quick) {
    return 40
  }
  if (profile === CaffeineMetabolismProfile.Sensitive) {
    return 22
  }
  return 35
}

export function formatClock(hour: number, minute: number): string {
  const hourText = hour < 10 ? `0${hour}` : `${hour}`
  const minuteText = minute < 10 ? `0${minute}` : `${minute}`
  return `${hourText}:${minuteText}`
}

export function nextSleepDate(preferences: UserPreferences, reference: Date = new Date()): Date {
  const candidate = new Date(reference.getTime())
  candidate.setHours(preferences.sleepHour, preferences.sleepMinute, 0, 0)
  if (candidate.getTime() > reference.getTime()) {
    return candidate
  }
  candidate.setDate(candidate.getDate() + 1)
  return candidate
}

export function readinessForRemaining(remaining: number, threshold: number): SleepReadinessState {
  if (remaining <= threshold) {
    return SleepReadinessState.SleepFriendly
  }
  if (remaining <= threshold * 2) {
    return SleepReadinessState.Watch
  }
  return SleepReadinessState.LikelyDisruptive
}

export function remainingCaffeineAt(entries: DrinkLogEntry[], at: Date, halfLifeHours: number): number {
  const rate = Math.log(2) / halfLifeHours
  let total = 0
  entries.forEach((entry) => {
    const consumedAt = new Date(entry.consumedAtISO)
    if (entry.metrics.caffeineMG <= 0 || consumedAt.getTime() > at.getTime()) {
      return
    }
    const elapsedHours = Math.max((at.getTime() - consumedAt.getTime()) / 3600000, 0)
    total += entry.metrics.caffeineMG * Math.exp(-rate * elapsedHours)
  })
  return roundNumber(total)
}

export function recommendedSleepTime(entries: DrinkLogEntry[], start: Date, halfLifeHours: number, threshold: number): string | undefined {
  if (remainingCaffeineAt(entries, start, halfLifeHours) <= threshold) {
    return formatClock(start.getHours(), start.getMinutes())
  }
  for (let index = 1; index <= 72; index += 1) {
    const candidate = new Date(start.getTime() + index * 30 * 60000)
    if (remainingCaffeineAt(entries, candidate, halfLifeHours) <= threshold) {
      return formatClock(candidate.getHours(), candidate.getMinutes())
    }
  }
  return undefined
}

export function buildForecast(entries: DrinkLogEntry[], preferences: UserPreferences, now: Date = new Date()): CaffeineForecast {
  const halfLife = metabolismHalfLifeHours(preferences.metabolismProfile)
  const threshold = safeSleepThreshold(preferences.metabolismProfile)
  const sleepAt = nextSleepDate(preferences, now)
  const currentEstimate = remainingCaffeineAt(entries, now, halfLife)
  const projectedSleep = remainingCaffeineAt(entries, sleepAt, halfLife)
  const timeline: CaffeineForecastPoint[] = []

  for (let step = 0; step <= 5; step += 1) {
    const pointDate = new Date(now.getTime() + step * 3 * 3600000)
    const remaining = remainingCaffeineAt(entries, pointDate, halfLife)
    timeline.push({
      id: `${pointDate.getTime()}`,
      atISO: pointDate.toISOString(),
      remainingCaffeineMG: remaining,
      stage: readinessForRemaining(remaining, threshold)
    })
  }

  const sleepPoint = remainingCaffeineAt(entries, sleepAt, halfLife)
  timeline.push({
    id: `sleep-${sleepAt.getTime()}`,
    atISO: sleepAt.toISOString(),
    remainingCaffeineMG: sleepPoint,
    stage: readinessForRemaining(sleepPoint, threshold)
  })

  return {
    currentEstimateMG: currentEstimate,
    projectedSleepMG: projectedSleep,
    safeSleepThresholdMG: threshold,
    recommendedSleepTimeText: recommendedSleepTime(entries, now, halfLife, threshold),
    sleepReadiness: readinessForRemaining(projectedSleep, threshold),
    sleepAtText: formatClock(preferences.sleepHour, preferences.sleepMinute),
    timeline
  }
}

export function totalsForEntries(entries: DrinkLogEntry[]): IngredientMetrics {
  return entries.reduce((accumulator, entry) => addMetrics(accumulator, entry.metrics), zeroMetrics())
}

export function defaultCalculatorInput(): CalculatorInput {
  return {
    method: CalculatorBrewMethod.Espresso,
    beansGrams: 18,
    waterML: 36,
    roastLevel: RoastLevel.Medium,
    grindLevel: GrindLevel.Fine
  }
}

interface CalculatorMethodDefaults {
  water: number
  extraction: number
  title: string
  serving: string
  brewMethod: BrewMethod
}

function roastFactor(level: RoastLevel): number {
  if (level === RoastLevel.Light) {
    return 1.04
  }
  if (level === RoastLevel.Dark) {
    return 0.93
  }
  return 1.0
}

function grindFactor(level: GrindLevel): number {
  if (level === GrindLevel.Fine) {
    return 1.05
  }
  if (level === GrindLevel.Medium) {
    return 0.98
  }
  if (level === GrindLevel.Coarse) {
    return 0.93
  }
  return 1.0
}

function methodDefaults(method: CalculatorBrewMethod): CalculatorMethodDefaults {
  if (method === CalculatorBrewMethod.PourOver) {
    const defaults: CalculatorMethodDefaults = {
      water: 300,
      extraction: 1.08,
      title: '手冲咖啡',
      serving: 'V60 一杯份',
      brewMethod: BrewMethod.HandBrew
    }
    return defaults
  }
  if (method === CalculatorBrewMethod.Capsule) {
    const defaults: CalculatorMethodDefaults = {
      water: 40,
      extraction: 0.82,
      title: '胶囊咖啡',
      serving: '胶囊杯',
      brewMethod: BrewMethod.ReadyToDrink
    }
    return defaults
  }
  const defaults: CalculatorMethodDefaults = {
    water: 36,
    extraction: 0.92,
    title: '意式浓缩',
    serving: '双份浓缩',
    brewMethod: BrewMethod.EspressoMachine
  }
  return defaults
}

export function estimateCalculatorCaffeine(input: CalculatorInput): number {
  const defaults = methodDefaults(input.method)
  const basePerGram = 10.8
  const waterRatio = Math.max(input.waterML / Math.max(defaults.water, 1), 0.55)
  const waterFactor = Math.min(Math.max(Math.pow(waterRatio, 0.18), 0.86), 1.16)
  const estimate =
    input.beansGrams *
    basePerGram *
    defaults.extraction *
    roastFactor(input.roastLevel) *
    grindFactor(input.grindLevel) *
    waterFactor

  return Math.round(estimate)
}

export function createLogEntry(drink: DrinkDefinition, serving?: DrinkServingOption, source: string = 'catalog'): DrinkLogEntry {
  const resolvedServing = serving ?? drink.servingOptions[0]
  return {
    id: `log-${Date.now()}-${drink.id}`,
    drinkDefinitionID: drink.id,
    drinkName: drink.name,
    category: drink.category,
    brand: drink.brand,
    preparationMethod: drink.preparationMethods.length > 0 ? drink.preparationMethods[0] : undefined,
    consumedAtISO: new Date().toISOString(),
    servingLabel: resolvedServing ? resolvedServing.name : '标准杯',
    metrics: {
      caffeineMG: drink.metrics.caffeineMG,
      sugarG: drink.metrics.sugarG,
      caloriesKcal: drink.metrics.caloriesKcal,
      hydrationML: drink.metrics.hydrationML,
      volumeML: drink.metrics.volumeML
    },
    source
  }
}

export function createDrinkFromCalculator(input: CalculatorInput): DrinkDefinition {
  const defaults = methodDefaults(input.method)
  const caffeine = estimateCalculatorCaffeine(input)
  return {
    id: `brew-${Date.now()}`,
    name: defaults.title,
    category: '咖啡',
    brand: '手动计算',
    brandCollection: '冲煮实验室',
    tags: ['计算器', defaults.title],
    heroFlavor: '自定义估算',
    preparationMethods: [defaults.brewMethod],
    metrics: {
      caffeineMG: caffeine,
      sugarG: 0,
      caloriesKcal: 5,
      hydrationML: input.waterML,
      volumeML: input.waterML
    },
    servingOptions: [
      {
        id: 'default',
        name: defaults.serving,
        volumeML: input.waterML,
        multiplier: 1.0
      }
    ]
  }
}

export function createTemplateFromCalculator(input: CalculatorInput): UserDrinkTemplate {
  const drink = createDrinkFromCalculator(input)
  return {
    id: `user-template-${Date.now()}`,
    brand: drink.brand,
    name: drink.name,
    category: drink.category,
    caffeineMG: drink.metrics.caffeineMG,
    sugarG: drink.metrics.sugarG,
    volumeML: Math.round(drink.metrics.volumeML),
    preparationMethod: drink.preparationMethods[0]
  }
}
