# Spec: Record Selector And Calculator Experience

## Requirements

### Requirement: Log Must Behave Like A Selector
The log screen MUST prioritize choosing and recording a drink over reading feature descriptions.

#### Scenario: First screen scan
- **WHEN** the user opens Log
- **THEN** the top of the page MUST show a direct search entry, a brand rail, and lightweight quick actions
- **AND** the primary browsing surface MUST be lightweight rows rather than large explanatory cards

### Requirement: Brand Filtering Must Be Fast To Scan
The log screen MUST expose brand filtering in a compact circular rail.

#### Scenario: Brand-first browsing
- **WHEN** the user wants to switch among coffee brands
- **THEN** the page MUST provide a compact circular brand rail with `全部` first
- **AND** the selected brand MUST visibly narrow the lower list content

### Requirement: Calculator Must Present A Tool-Like Surface
The caffeine calculator MUST present the brew method, parameter cards, and estimated result in a single tool-focused flow.

#### Scenario: Calculator first viewport
- **WHEN** the user opens the caffeine calculator
- **THEN** the first viewport MUST show the active brew method, a compact parameter card grid, and the estimated caffeine result
- **AND** the page MUST provide direct actions to reuse the result without requiring backend connectivity
