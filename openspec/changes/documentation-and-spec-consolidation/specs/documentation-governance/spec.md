# Spec: Documentation Governance

## Requirements

### Requirement: The Repository Must Expose A Clear Reading Order
The repository MUST provide a clear documentation reading order for current architecture, product scope, quality rules, and active changes.

#### Scenario: New collaborator onboarding
- **WHEN** a new collaborator opens the repository documentation
- **THEN** they MUST be able to find the current long-lived source-of-truth docs and the current OpenSpec change set without reading historical files first

### Requirement: Project Map Must Represent Current State
The repository MUST keep `agent.md` as a current-state project map rather than an unbounded historical log.

#### Scenario: Reading agent map
- **WHEN** a collaborator reads `agent.md`
- **THEN** they MUST see the current product direction, architecture direction, active changes, and next steps with minimal duplication

### Requirement: Historical Specs Must Not Mislead Current Scope
Historical OpenSpec files MAY remain in the repo, but the repository MUST clearly indicate when they no longer define the current product direction.

#### Scenario: Reading historical bootstrap spec
- **WHEN** a collaborator reads an early foundational spec
- **THEN** the document or surrounding navigation MUST make clear that later decisions and changes define the current product route
