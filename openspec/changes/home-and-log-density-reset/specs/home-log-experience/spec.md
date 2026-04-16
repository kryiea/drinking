# Spec: Home And Log Experience Reset

## Requirements

### Requirement: Home Must Prioritize State Judgment Over Explanation
The home page MUST present the current caffeine state and next action with minimal explanatory text.

#### Scenario: Home first viewport
- **WHEN** the user opens Home
- **THEN** the first viewport MUST show a single dominant state hero
- **AND** the hero MUST include current estimate, projected sleep residue, and a primary action
- **AND** secondary information such as daily counts or sync state MUST appear with lower visual priority than the hero

### Requirement: Log Must Prioritize Immediate Capture
The logging page MUST make one-tap or one-sheet beverage capture more visually prominent than catalog browsing.

#### Scenario: Log primary path
- **WHEN** the user opens Log without active filters
- **THEN** the page MUST present a dominant capture entry point before the full catalog
- **AND** voice, camera, library, and recent reuse MUST remain accessible without competing equally for primary emphasis

### Requirement: Default Catalog Must Be Compact
The logging page MUST present the starter catalog in a compact format that supports quick scanning.

#### Scenario: Compact catalog browsing
- **WHEN** the user browses the default coffee or milk tea catalog
- **THEN** the visible cards MUST prioritize brand, name, caffeine amount, and add action
- **AND** secondary metadata MUST be reduced enough to keep the browsing density visibly tighter than row-style detail cards
