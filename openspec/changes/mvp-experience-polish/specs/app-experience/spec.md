# Spec: App Experience Polish

## Requirements

### Requirement: Onboarding Must Match Coffee-First Positioning
The app MUST present onboarding copy and action hierarchy that matches the current product direction of fast beverage logging and caffeine-impact understanding.

#### Scenario: Onboarding headline and supporting items
- **WHEN** the user opens onboarding
- **THEN** the primary value proposition MUST focus on low-friction logging and understanding tonight's impact
- **AND** onboarding MUST NOT present AI recommendations as a primary user benefit

### Requirement: Home Must Be Glanceable
The home page MUST allow the user to identify current caffeine state and the next logging action without reading long paragraphs.

#### Scenario: Home above-the-fold scan
- **WHEN** the user lands on Home
- **THEN** the screen MUST show current caffeine state, projected sleep impact, and a clear next action within the first viewport
- **AND** secondary explanatory copy MUST remain short enough to avoid dominating the hero surface

### Requirement: Profile Must Prioritize Real Settings
The profile page MUST prioritize user parameters and data actions over roadmap or development-planning language.

#### Scenario: Profile information hierarchy
- **WHEN** the user opens Profile
- **THEN** personal rhythm settings and sync/data status MUST appear before developer-only controls
- **AND** planning language for future surfaces such as Watch MUST NOT be presented as if it were an active primary setting
