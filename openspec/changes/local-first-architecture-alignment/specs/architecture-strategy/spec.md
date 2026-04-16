# Spec: Local-First Architecture Strategy

## Requirements

### Requirement: Core User Data Must Be Local-First
The app MUST treat user logs, personal settings, and user drink templates as local-first data within the current Apple ecosystem product scope.

#### Scenario: No backend availability
- **WHEN** the backend is unreachable or not configured
- **THEN** the user MUST still be able to record drinks, view caffeine state, and access their local settings
- **AND** the app MUST NOT require a backend round-trip for the primary logging loop

### Requirement: Backend Must Be Auxiliary
The backend MUST be documented and implemented as an auxiliary system for catalog, support/admin, optional remote tasks, and future cross-platform seams.

#### Scenario: Backend responsibilities
- **WHEN** the architecture is described in repo documentation
- **THEN** the backend MUST be positioned as supporting catalog/admin/remote-provider roles
- **AND** it MUST NOT be described as the default current truth source for user logs in the Apple-first path

### Requirement: Sync Must Stay Behind A Provider Seam
The app MUST keep Apple ecosystem sync behind an explicit provider seam so local-only mode remains valid.

#### Scenario: Apple ecosystem sync
- **WHEN** sync behavior is described or implemented
- **THEN** the architecture MUST reference a provider-based sync boundary
- **AND** local-only fallback MUST remain a first-class supported mode
