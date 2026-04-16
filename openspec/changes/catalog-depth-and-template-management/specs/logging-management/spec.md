# Spec: Logging Management

## Requirements

### Requirement: Catalog Must Cover More Mainstream High-Frequency Drinks
The app MUST ship with a deeper coffee-first and milk-tea-first starter catalog so the logging screen is useful without immediate manual customization.

#### Scenario: Starter catalog breadth
- **WHEN** the user opens the default catalog
- **THEN** the coffee and milk tea sections MUST include multiple mainstream brands beyond the initial minimal demo set

### Requirement: User Drink Templates Must Be Manageable
The app MUST allow users to manage personal drink templates after creation.

#### Scenario: Edit personal drink template
- **WHEN** the user edits one of their personal drink templates
- **THEN** the template MUST update in the personal drinks section without creating a duplicate

#### Scenario: Delete personal drink template
- **WHEN** the user deletes one of their personal drink templates
- **THEN** the template MUST disappear from the personal drinks section
