<!--
SYNC IMPACT REPORT
==================
Version: 1.1.0 → 1.2.0 (New platform and environment principles added)
Modified Principles: N/A
Added Sections:
  - VIII. Docker-Based Development Environment (new principle)
  - IX. Flutter Cross-Platform Compatibility (new principle)
Removed Sections: None
Templates Status:
  ✅ plan-template.md - Technical Context updated with Flutter/Docker requirements
  ✅ spec-template.md - Platform compatibility checks added to requirements
  ✅ tasks-template.md - Docker setup and platform validation tasks included
Follow-up TODOs: None - all platform and environment requirements specified
==================
-->

# 42lib-flutter Constitution

## Core Principles

### I. Git-Based Project Management
Every project activity MUST be tracked in Git and GitHub:
- All code, documentation, and SpecKit files managed in Git repository
- GitHub Projects used for workflow orchestration and progress visualization
- GitHub Issues used for all tasks with mandatory issue number in commit messages
- Remote repository: `git@github.com:gdtknight/42lib-flutter.git`

**Rationale**: Git-based tracking ensures full traceability, enables distributed
collaboration across multiple Copilot agents, and provides single source of truth
for project state.

### II. Branch Strategy (NON-NEGOTIABLE)
Git branch structure MUST follow defined strategy:
- `main` - Production-ready stable releases
- `dev` - Integration branch for ongoing development
- `feature/*` - New feature development branches
- `fix/*` - Bug fix branches
- `release/*` - Release preparation branches

All changes merged via Pull Requests; direct commits to `main` and `dev` forbidden.

**Rationale**: Structured branching prevents conflicts, isolates work-in-progress,
and enforces code review gates before integration.

### III. Issue-Driven Commits
Every commit message MUST reference related GitHub Issue number:
- Format: `[#ISSUE_NO] Brief description` or conventional commits with issue footer
- Enables automated tracking of work items to code changes
- No commits without associated issue except project setup commits

**Rationale**: Commit-to-issue linkage provides full audit trail, connects
implementation to requirements, and powers automated project dashboards.

### IV. Korean Documentation Standard
All user-facing documentation MUST be in Korean:
- GitHub Issue titles and descriptions in Korean
- Pull Request descriptions in Korean
- All Markdown files in `docs/` directory in Korean
- Templates (issue, PR) provided in Korean
- GitHub Wiki maintained in Korean

Code comments and internal identifiers remain in English for technical compatibility.

**Rationale**: Korean documentation ensures accessibility for primary stakeholders,
reduces translation overhead, and maintains consistency across project artifacts.

### V. Structured Documentation & Logging
Project documentation and logs MUST follow hierarchical organization:
- `docs/` - All project documentation with role-based subdirectories
- `docs/` synced to GitHub Wiki for discoverability
- `logs/` - Execution logs organized by date subdirectories (format: `YYYY-MM-DD/`)
- Log filenames: `YYYYMMDD-HHmmss-<descriptor>.log`

**Rationale**: Structured organization enables quick retrieval, prevents information
loss, and supports long-term project maintainability.

### VI. 42 Identity Design Standard
All application design and visual elements MUST reflect 42's identity:
- Color schemes MUST represent 42's brand identity as primary design element
- Visual consistency across all screens and components
- Design choices prioritize brand recognition and cohesive identity
- Color palette decisions require alignment with 42 identity guidelines

**Rationale**: Consistent visual identity strengthens brand recognition, creates
unified user experience, and differentiates the product in the market.

### VII. User-Centric UX Priority
User experience design MUST prioritize convenience and simplicity:
- User convenience is the PRIMARY consideration in all UX decisions
- Interface simplicity MUST be pursued whenever feasible
- Reduce cognitive load through clear information hierarchy
- Minimize required user actions to complete core tasks
- Complex features MUST maintain intuitive interaction patterns

**Rationale**: User-centric design reduces friction, increases adoption, and ensures
accessibility. Simple UI minimizes learning curve and support overhead.

### VIII. Docker-Based Development Environment
All development activities MUST be conducted within Docker containers:
- Development environment setup and dependencies managed exclusively via Docker
- Local machine environment MUST NOT be modified or polluted with project dependencies
- All build, test, and development tools run inside Docker containers
- Docker Compose used for orchestrating multi-container development setups
- Dockerfile and docker-compose.yml MUST be maintained in repository root

**Rationale**: Docker isolation ensures reproducible development environments across
all contributors, eliminates "works on my machine" issues, prevents dependency
conflicts with local system, and enables consistent CI/CD execution.

### IX. Flutter Cross-Platform Compatibility
Flutter application MUST support iOS, Android, and Web platforms with strict
version compatibility requirements:
- **Target Platforms**: iOS, Android, Web (all three MUST be supported)
- **iOS Compatibility**: Latest version minus 1, plus 3 previous versions (4 versions total)
- **Android Compatibility**: Latest version minus 1, plus 3 previous versions (4 versions total)
- Version compatibility MUST NOT break across supported version range
- Platform-specific code MUST be minimized and isolated
- Cross-platform behavior parity MUST be maintained wherever feasible
- CI/CD pipeline MUST validate builds for all three platforms
- Breaking changes to platform compatibility require explicit constitution amendment

**Rationale**: Wide platform version support maximizes user reach, prevents
premature obsolescence, and ensures accessibility. Cross-platform consistency
reduces maintenance burden and testing complexity.

## Git Workflow & Branching Strategy

**Branch Lifecycle**:
1. Create issue in GitHub with Korean description
2. Create branch from `dev`: `feature/<issue-no>-<description>` or `fix/<issue-no>-<description>`
3. Implement changes with commits referencing issue: `[#123] Implement feature`
4. Open PR from feature/fix branch to `dev` with Korean description
5. Code review and CI/CD validation via GitHub Actions
6. Merge to `dev` after approval
7. Periodic releases: `dev` → `release/vX.Y.Z` → `main`

**Merge Strategy**: Squash merge for feature branches, merge commit for releases.

**Tag Strategy**: All releases tagged in `main` with semantic version `vX.Y.Z`.

## Documentation & Communication Standards

**Documentation Hierarchy** (`docs/` structure):
```
docs/
├── architecture/    # System design, technical architecture
├── api/            # API documentation, contracts
├── guides/         # User guides, tutorials
├── processes/      # Development processes, workflows
└── decisions/      # Architecture Decision Records (ADRs)
```

**GitHub Wiki**: Mirror of `docs/` for enhanced discoverability and search.

**Issue Templates**: Korean templates for bug reports, feature requests, tasks.

**PR Templates**: Korean template enforcing description, related issues, testing evidence.

**Commit per Task**: Each logical task or unit of work committed separately with
descriptive message and issue reference.

## CI/CD & Quality Gates

**GitHub Actions Pipeline**:
- Automated testing on PR creation and updates
- Build verification for all target platforms
- Code quality checks (linting, formatting)
- Deployment automation for approved releases

**Quality Gates** (must pass before merge):
- All tests passing
- Code review approval from at least one team member
- CI/CD pipeline success
- Issue linked and acceptance criteria met

## Governance

This constitution supersedes all other project practices and serves as the
single source of truth for project governance.

**Amendment Process**:
1. Propose amendment via GitHub Issue with label `constitution-amendment`
2. Document rationale and impact analysis
3. Team review and discussion in issue comments
4. Approval requires consensus (blocking concerns must be resolved)
5. Update constitution with version bump and sync dependent artifacts
6. Announce amendment in project communication channels

**Versioning Policy**:
- MAJOR: Breaking changes to governance or principle removal/redefinition
- MINOR: New principles added or significant guidance expansion
- PATCH: Clarifications, wording improvements, non-semantic refinements

**Compliance Review**:
- All PRs must verify compliance with constitution principles
- SpecKit templates enforce constitution checks
- Quarterly constitution review to assess effectiveness and identify improvements

**Constitution Authority**: In case of conflict between this constitution and
other project documentation, the constitution takes precedence.

**Version**: 1.2.0 | **Ratified**: 2025-12-17 | **Last Amended**: 2025-12-17
