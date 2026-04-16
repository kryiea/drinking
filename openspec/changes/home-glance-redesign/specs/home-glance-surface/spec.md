# Spec: Home Glance Surface

## Requirements

### Requirement: Home Must Present A Single Dominant State Hero
The home screen MUST present one dominant hero that communicates the current caffeine state before any secondary information.

#### Scenario: First viewport hierarchy
- **WHEN** the user opens Home
- **THEN** the first viewport MUST show one visually dominant hero
- **AND** the hero MUST contain the current caffeine estimate, the planned sleep-time residue, and tonight's state label
- **AND** secondary modules such as recent records MUST appear with lower visual weight than the hero

### Requirement: Home Must Show A Compact Sleep Timeline
The home screen MUST include a compact visualization from now to the planned sleep time.

#### Scenario: Compact sleep view
- **WHEN** the user views Home
- **THEN** the page MUST show a compact time-based caffeine decay view
- **AND** the view MUST identify both the current point and the planned sleep point
- **AND** the planned safe-sleep threshold MUST remain visually distinguishable from the main bars

### Requirement: Home Must Keep Logging As The Primary Action
The home screen MUST keep beverage logging as the most prominent action.

#### Scenario: Primary action emphasis
- **WHEN** the user opens Home
- **THEN** a primary `记一杯` action MUST remain visible in the first viewport
- **AND** that action MUST have stronger visual emphasis than recent entries or other secondary content
