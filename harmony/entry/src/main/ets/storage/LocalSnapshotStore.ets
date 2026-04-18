import { starterCatalog, starterLogs, starterTemplates, defaultPreferences } from '../model/Fixtures'
import { DrinkDefinition, DrinkLogEntry, UserDrinkTemplate, UserPreferences } from '../model/Types'

export interface LocalSnapshot {
  catalog: DrinkDefinition[]
  logs: DrinkLogEntry[]
  templates: UserDrinkTemplate[]
  preferences: UserPreferences
}

export function bootstrapSnapshot(): LocalSnapshot {
  return {
    catalog: starterCatalog(),
    logs: starterLogs(),
    templates: starterTemplates(),
    preferences: defaultPreferences()
  }
}
