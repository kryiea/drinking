import {
  BrewMethod,
  CaffeineMetabolismProfile,
  DrinkDefinition,
  DrinkLogEntry,
  UserDrinkTemplate,
  UserPreferences
} from './Types'

export function defaultPreferences(): UserPreferences {
  return {
    sleepHour: 23,
    sleepMinute: 30,
    metabolismProfile: CaffeineMetabolismProfile.Standard,
    iCloudPlanEnabled: false,
    watchPlanEnabled: false
  }
}

export function starterCatalog(): DrinkDefinition[] {
  return [
    {
      id: 'americano-iced',
      name: '冰美式',
      category: '咖啡',
      brand: '瑞幸',
      brandCollection: '日常通勤',
      tags: ['低糖', '高频'],
      heroFlavor: '清爽黑咖',
      preparationMethods: [BrewMethod.EspressoMachine, BrewMethod.ReadyToDrink],
      metrics: { caffeineMG: 140, sugarG: 0, caloriesKcal: 8, hydrationML: 360, volumeML: 380 },
      servingOptions: [{ id: 'large', name: '大杯', volumeML: 380, multiplier: 1.0 }]
    },
    {
      id: 'luckin-coconut-latte',
      name: '生椰拿铁',
      category: '咖啡',
      brand: '瑞幸',
      brandCollection: '日常通勤',
      tags: ['椰乳', '奶咖'],
      heroFlavor: '生椰奶香',
      preparationMethods: [BrewMethod.EspressoMachine, BrewMethod.ReadyToDrink],
      metrics: { caffeineMG: 126, sugarG: 10, caloriesKcal: 168, hydrationML: 285, volumeML: 320 },
      servingOptions: [{ id: 'regular', name: '中杯', volumeML: 320, multiplier: 1.0 }]
    },
    {
      id: 'starbucks-flat-white',
      name: '馥芮白',
      category: '咖啡',
      brand: '星巴克',
      brandCollection: '经典意式',
      tags: ['奶咖', '高频'],
      heroFlavor: '浓缩奶香',
      preparationMethods: [BrewMethod.EspressoMachine],
      metrics: { caffeineMG: 130, sugarG: 9, caloriesKcal: 150, hydrationML: 250, volumeML: 330 },
      servingOptions: [{ id: 'tall', name: '中杯', volumeML: 330, multiplier: 1.0 }]
    },
    {
      id: 'cotti-orange-americano',
      name: '橙C美式',
      category: '咖啡',
      brand: '库迪',
      brandCollection: '日常通勤',
      tags: ['果咖', '美式'],
      heroFlavor: '橙香黑咖',
      preparationMethods: [BrewMethod.EspressoMachine, BrewMethod.ReadyToDrink],
      metrics: { caffeineMG: 136, sugarG: 6, caloriesKcal: 84, hydrationML: 320, volumeML: 420 },
      servingOptions: [{ id: 'large', name: '大杯', volumeML: 420, multiplier: 1.0 }]
    },
    {
      id: 'pour-over-yirgacheffe',
      name: '耶加雪菲手冲',
      category: '手冲咖啡',
      brand: 'Blue Bottle',
      brandCollection: '精品咖啡',
      tags: ['手冲', '单品'],
      heroFlavor: '花香柑橘',
      preparationMethods: [BrewMethod.HandBrew],
      metrics: { caffeineMG: 130, sugarG: 0, caloriesKcal: 6, hydrationML: 255, volumeML: 260 },
      servingOptions: [{ id: 'v60', name: 'V60 一杯份', volumeML: 260, multiplier: 1.0 }]
    },
    {
      id: 'bo-ya-jue-xian',
      name: '伯牙绝弦',
      category: '奶茶',
      brand: '霸王茶姬',
      brandCollection: '招牌奶茶',
      tags: ['乌龙', '奶茶'],
      heroFlavor: '茶香奶韵',
      preparationMethods: [BrewMethod.MilkTea, BrewMethod.ReadyToDrink],
      metrics: { caffeineMG: 82, sugarG: 22, caloriesKcal: 240, hydrationML: 430, volumeML: 500 },
      servingOptions: [{ id: 'less-sugar', name: '少糖', volumeML: 500, multiplier: 0.9 }]
    },
    {
      id: 'heytea-cheese-grape',
      name: '轻芝多肉葡萄',
      category: '果茶',
      brand: '喜茶',
      brandCollection: '果茶',
      tags: ['芝士', '葡萄'],
      heroFlavor: '葡萄芝香',
      preparationMethods: [BrewMethod.MilkTea, BrewMethod.ReadyToDrink],
      metrics: { caffeineMG: 30, sugarG: 24, caloriesKcal: 228, hydrationML: 415, volumeML: 500 },
      servingOptions: [{ id: 'regular', name: '标准杯', volumeML: 500, multiplier: 1.0 }]
    },
    {
      id: 'alittle-boba-milk-tea',
      name: '波霸奶茶',
      category: '奶茶',
      brand: '一点点',
      brandCollection: '经典奶茶',
      tags: ['珍珠', '奶茶'],
      heroFlavor: '红茶奶香',
      preparationMethods: [BrewMethod.MilkTea, BrewMethod.ReadyToDrink],
      metrics: { caffeineMG: 54, sugarG: 32, caloriesKcal: 298, hydrationML: 400, volumeML: 500 },
      servingOptions: [{ id: 'regular', name: '标准杯', volumeML: 500, multiplier: 1.0 }]
    }
  ]
}

export function starterTemplates(): UserDrinkTemplate[] {
  return [
    {
      id: 'user-cold-brew-home',
      brand: '我的常喝',
      name: '家里冷萃',
      category: '咖啡',
      caffeineMG: 110,
      sugarG: 0,
      volumeML: 280,
      preparationMethod: BrewMethod.ReadyToDrink
    }
  ]
}

export function starterLogs(): DrinkLogEntry[] {
  const now = Date.now()
  return [
    {
      id: 'entry-1',
      drinkDefinitionID: 'americano-iced',
      drinkName: '冰美式',
      category: '咖啡',
      brand: '瑞幸',
      preparationMethod: BrewMethod.EspressoMachine,
      consumedAtISO: new Date(now - 3 * 3600000).toISOString(),
      servingLabel: '大杯',
      metrics: { caffeineMG: 140, sugarG: 0, caloriesKcal: 8, hydrationML: 360, volumeML: 380 },
      source: 'catalog'
    },
    {
      id: 'entry-2',
      drinkDefinitionID: 'bo-ya-jue-xian',
      drinkName: '伯牙绝弦',
      category: '奶茶',
      brand: '霸王茶姬',
      preparationMethod: BrewMethod.MilkTea,
      consumedAtISO: new Date(now - 45 * 60000).toISOString(),
      servingLabel: '少糖',
      metrics: { caffeineMG: 82, sugarG: 22, caloriesKcal: 240, hydrationML: 430, volumeML: 500 },
      source: 'recent'
    }
  ]
}
