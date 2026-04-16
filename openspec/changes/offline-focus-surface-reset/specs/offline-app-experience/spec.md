# Spec: Offline App Experience

## Requirements

### Requirement: Home Must Focus On Caffeine And Sleep Only
The home page MUST prioritize only caffeine amount, projected sleep residue, and the primary logging action.

#### Scenario: Home first viewport
- **WHEN** the user opens Home
- **THEN** the first viewport MUST show the current caffeine estimate, projected sleep residue, and a primary `记一杯` action
- **AND** the page MUST NOT give equal visual priority to unrelated daily statistics

### Requirement: Log Must Be Structured Around Capture And Brand Directory
The log page MUST place beverage capture first and the brand directory second.

#### Scenario: Default logging layout
- **WHEN** the user opens Log
- **THEN** the upper part of the page MUST present logging entry points
- **AND** the lower part of the page MUST present a brand-based directory with drink rows in horizontal row form

### Requirement: Insights Must Use A Direct Time-Based Caffeine View
The insights page MUST use a more direct time-based visualization of caffeine decay.

#### Scenario: Insights readability
- **WHEN** the user opens Insights
- **THEN** the page MUST clearly show the current point, the sleep point, and caffeine change over time
- **AND** secondary nutrition structures unrelated to caffeine and sleep MUST be removed from the primary view

### Requirement: Profile Must Be A Multi-Level Settings Surface
The profile page MUST use a list-style, multi-level settings structure.

#### Scenario: Profile hierarchy
- **WHEN** the user opens Profile
- **THEN** the top level MUST show setting entries instead of inline detailed controls
- **AND** detailed configuration MUST live on secondary pages
