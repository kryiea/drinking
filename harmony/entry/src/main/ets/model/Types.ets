export enum AppTab {
  Home = '首页',
  Log = '记录',
  Insights = '分析',
  Profile = '我的'
}

export enum DirectoryScope {
  Coffee = 'coffee',
  MilkTea = 'milk-tea',
  Mine = 'mine'
}

export enum BrewMethod {
  HandBrew = 'hand-brew',
  EspressoMachine = 'espresso-machine',
  MilkTea = 'milk-tea',
  ReadyToDrink = 'ready-to-drink'
}

export enum CalculatorBrewMethod {
  Espresso = 'espresso',
  PourOver = 'pour-over',
  Capsule = 'capsule'
}

export enum RoastLevel {
  Light = 'light',
  Medium = 'medium',
  Dark = 'dark'
}

export enum GrindLevel {
  Fine = 'fine',
  Standard = 'standard',
  Medium = 'medium',
  Coarse = 'coarse'
}

export enum CaffeineMetabolismProfile {
  Quick = 'quick',
  Standard = 'standard',
  Sensitive = 'sensitive'
}

export enum SleepReadinessState {
  SleepFriendly = 'sleep-friendly',
  Watch = 'watch',
  LikelyDisruptive = 'likely-disruptive'
}

export interface IngredientMetrics {
  caffeineMG: number
  sugarG: number
  caloriesKcal: number
  hydrationML: number
  volumeML: number
}

export interface DrinkServingOption {
  id: string
  name: string
  volumeML: number
  multiplier: number
}

export interface BrewRecipeSummary {
  method: BrewMethod
  title: string
  ratioText: string
  coffeeG: number
  waterML: number
  outputML: number
  milkML: number
  concentrateML: number
  brewSeconds: number
  temperatureC: number
  grindText: string
  tastingNote: string
}

export interface DrinkDefinition {
  id: string
  name: string
  category: string
  brand: string
  brandCollection: string
  tags: string[]
  heroFlavor: string
  preparationMethods: BrewMethod[]
  brewRecipe?: BrewRecipeSummary
  metrics: IngredientMetrics
  servingOptions: DrinkServingOption[]
}

export interface DrinkLogEntry {
  id: string
  drinkDefinitionID?: string
  drinkName: string
  category: string
  brand: string
  preparationMethod?: BrewMethod
  consumedAtISO: string
  servingLabel: string
  metrics: IngredientMetrics
  source: string
}

export interface UserDrinkTemplate {
  id: string
  brand: string
  name: string
  category: string
  caffeineMG: number
  sugarG: number
  volumeML: number
  preparationMethod?: BrewMethod
}

export interface UserPreferences {
  sleepHour: number
  sleepMinute: number
  metabolismProfile: CaffeineMetabolismProfile
  iCloudPlanEnabled: boolean
  watchPlanEnabled: boolean
}

export interface CaffeineForecastPoint {
  id: string
  atISO: string
  remainingCaffeineMG: number
  stage: SleepReadinessState
}

export interface CaffeineForecast {
  currentEstimateMG: number
  projectedSleepMG: number
  safeSleepThresholdMG: number
  recommendedSleepTimeText?: string
  sleepReadiness: SleepReadinessState
  sleepAtText: string
  timeline: CaffeineForecastPoint[]
}

export interface CalculatorInput {
  method: CalculatorBrewMethod
  beansGrams: number
  waterML: number
  roastLevel: RoastLevel
  grindLevel: GrindLevel
}
