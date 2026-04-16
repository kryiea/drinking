# Spec: Visual Accessibility And Appearance

## Requirements

### Requirement: Key Metrics Must Remain Readable
The app MUST present key caffeine and sleep values with sufficient foreground/background contrast in supported appearance modes.

#### Scenario: Home metric readability
- **WHEN** the user views the home hero and timeline summaries
- **THEN** critical values such as sleep time and projected caffeine MUST remain readable without relying on low-contrast white-on-glass styling

### Requirement: Brew Method Illustrations Must Be Distinguishable
The caffeine calculator MUST present brew method illustrations that are easy to tell apart at a glance.

#### Scenario: Method recognition
- **WHEN** the user switches among espresso, pour over, and capsule
- **THEN** each illustration MUST expose distinct visual landmarks for that method
- **AND** pour over MUST clearly read as a hand-brew setup rather than a generic abstract shape

### Requirement: App Must Follow System Appearance
The app MUST automatically adapt to the system light and dark appearance.

#### Scenario: System appearance change
- **WHEN** iOS is in light mode or dark mode
- **THEN** page backgrounds, card surfaces, and foreground text MUST adjust to preserve hierarchy and readability
