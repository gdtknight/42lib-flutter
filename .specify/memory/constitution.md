<!--
SYNC IMPACT REPORT
==================
Version: 1.6.0 → 1.7.0 (Issue/PR/Commit Synchronization)
Modified Principles: None
Added Sections:
  - XIV. Issue, Pull Request, and Commit Message Synchronization (NEW)
Removed Sections: None
Templates Status:
  ✅ plan-template.md - Constitution Check updated with synchronization validation
  ✅ spec-template.md - No changes required (scope unchanged)
  ✅ tasks-template.md - Constitution compliance updated with new principle
  ✅ README.md - Updated to include Principle XIV in summary (14th principle added to list)
Follow-up TODOs: None
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

### III. Issue-Driven Commits & Metadata
Every commit message MUST reference related GitHub Issue number, and every issue
MUST have proper metadata configured:
- Commit format: `[#ISSUE_NO] Brief description` or conventional commits with issue footer
- Every GitHub Issue MUST have:
  - Appropriate **specific** Labels assigned that accurately describe the issue type
    (e.g., `bug:critical`, `enhancement:feature`, `docs:api`, not generic `bug` or `feature`)
  - Associated Project board for workflow tracking
  - Assigned Milestone for release planning
  - **Development section linked to the appropriate branch** (e.g., `feature/123-user-auth`,
    `fix/456-login-crash`) matching the actual working branch
- Issues without proper metadata MUST NOT be worked on until corrected
- No commits without associated issue except project setup commits
- Label specificity rules:
  - Use hierarchical labels with categories (type:subtype format preferred)
  - Avoid ambiguous generic labels; each label should provide clear context
  - Maintain consistent label taxonomy across repository

**Rationale**: Commit-to-issue linkage provides full audit trail, connects
implementation to requirements, and powers automated project dashboards. Issue
metadata enables proper workflow management, release planning, and team coordination.
Branch assignment in Development section creates explicit traceability between issues
and code changes. Specific labels improve filtering, reporting, and automated workflows.

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

### X. Constitution Compliance Verification
Every command execution MUST include constitution compliance verification:
- Constitution compliance MUST be checked after every SpecKit command completion
- Compliance verification includes all applicable principles from this constitution
- Non-compliance MUST be documented with explicit justification or remediation plan
- Compliance status MUST be recorded in command output or related artifacts
- Automated compliance checks MUST be integrated into CI/CD pipeline where feasible
- Manual review gates MUST verify constitution adherence before PR approval

**Rationale**: Continuous compliance verification prevents governance drift, ensures
principles are consistently applied, and maintains project integrity across all
activities. Early detection of violations reduces technical debt and rework.

### XI. Pull Request Review Gate
All Pull Requests to `dev` branch MUST receive explicit approval confirmation
before proceeding with subsequent workflow steps:
- After commit completion, create PR to `dev` branch immediately
- PR MUST include:
  - Korean description with clear context
  - Linked GitHub Issues in the PR description
  - **Development section linked to source branch** matching the feature/fix branch
  - **Specific Labels** mirroring the linked issue labels (e.g., `enhancement:ui`,
    `bug:security`, `refactor:performance`)
  - Testing evidence or test plan
- Implementation work MUST STOP until PR receives review approval
- After PR approval, proceed with subsequent steps (e.g., testing, deployment)
- No direct push to `dev` or `main` branches - all changes via approved PRs
- Self-merge without approval is strictly forbidden
- PR label specificity rules:
  - Use same hierarchical label taxonomy as Issues
  - Labels MUST reflect actual changes, not just issue labels
  - Multiple labels acceptable when PR addresses multiple concerns

**Rationale**: Mandatory review gate ensures code quality, catches errors early,
facilitates knowledge sharing, and prevents unauthorized changes from propagating
downstream. Explicit approval requirement creates accountability and traceability.
Branch linking in Development section and specific labels enable automated workflows,
release note generation, and proper change tracking.

### XII. Continuous Integration & Immediate Sharing
Error detection and non-code-affecting changes MUST follow rapid sharing workflow:
- Verification process MUST be in place to detect errors after changes
- Changes that do NOT affect code behavior (docs, configs, comments) MUST be
  pushed to GitHub immediately for team visibility
- Code-affecting changes MUST pass local validation before push
- CI/CD pipeline MUST run automated checks on all pushes
- Failed CI checks MUST block PR merge until resolved
- Documentation and configuration changes enable immediate collaboration without
  waiting for full test cycles

**Rationale**: Immediate sharing of non-code changes reduces coordination overhead,
enables parallel work, and keeps team synchronized. Systematic error detection
prevents defects from propagating. Separating code-affecting vs non-code-affecting
changes optimizes team velocity while maintaining quality gates.

### XIII. Descriptive Issue and Pull Request Titles
GitHub Issue and Pull Request titles MUST comprehensively represent the complete
content and purpose:
- Issue titles MUST clearly describe the problem, feature, or task being addressed
- PR titles MUST accurately summarize all changes included in the pull request
- Titles MUST be self-explanatory without needing to read the full description
- Avoid vague titles like "Fix bug", "Update", "Changes" - be specific
- Use Korean language for clarity and consistency (per Constitution IV)
- Title format guidelines:
  - Issues: `[Type] Specific description of problem/feature`
    (e.g., `[Bug] 로그인 시 세션 만료 오류`, `[Feature] 사용자 프로필 편집 기능 추가`)
  - PRs: `Brief summary of all changes made`
    (e.g., `로그인 세션 만료 오류 수정 및 타임아웃 설정 추가`, `사용자 프로필 편집 UI 구현`)
- Titles should enable quick understanding for:
  - Team members reviewing Issues/PRs
  - Automated tools generating release notes
  - Future searches and audit trails
  - Project managers tracking progress
- Update title if scope changes during implementation

**Rationale**: Descriptive titles improve project transparency, enable efficient
review workflows, support automated documentation generation, and create searchable
history. Well-crafted titles reduce time spent understanding context, facilitate
accurate progress tracking, and improve team coordination. Clear titles are
essential for maintaining project visibility and enabling effective collaboration
across distributed teams and AI agents.

### XIV. Issue, Pull Request, and Commit Message Synchronization
GitHub Issue titles, Pull Request titles, and commit messages MUST maintain
consistency and synchronization throughout the development lifecycle:
- Issue title establishes the canonical description of work scope
- PR title MUST accurately reflect the Issue title while incorporating
  implementation-specific details when scope expands
- Commit messages MUST reference the Issue number and describe specific changes
- Synchronization requirements:
  - **Issue → PR Alignment**: PR title should extend Issue title with
    implementation details, not contradict it
    - Example: Issue "[#1] 사용자 인증 구현" → PR "[#1] 사용자 인증 구현 - JWT 토큰
      기반 로그인/로그아웃 및 세션 관리"
  - **Issue → Commits Alignment**: All commits MUST reference Issue number with
    format `[#N]` and describe incremental progress toward Issue goal
    - Example commits for Issue #1:
      - `[#1] feat: JWT 인증 미들웨어 추가`
      - `[#1] feat: 로그인 API 엔드포인트 구현`
      - `[#1] test: 인증 플로우 단위 테스트 추가`
  - **PR → Commits Consistency**: PR body MUST summarize all commit changes and
    explain how they collectively address the linked Issue
- Synchronization verification checklist:
  - [ ] Issue title clearly describes the problem/feature
  - [ ] PR title extends (not contradicts) Issue title
  - [ ] All commits reference correct Issue number
  - [ ] Commit messages describe logical increments toward Issue goal
  - [ ] PR body explains relationship between commits and Issue resolution
  - [ ] If scope changed during implementation, Issue title updated before PR merge
- Breaking synchronization (forbidden patterns):
  - PR title contradicts or is unrelated to linked Issue title
  - Commits reference wrong Issue number
  - PR includes changes unrelated to linked Issue without explanation
  - Issue title outdated but not updated before merge
- Multi-Issue PRs:
  - When PR addresses multiple related Issues, list all Issue numbers in title
    and body
  - Each commit should still reference primary Issue, with secondary Issues noted
    in commit body if applicable
  - Example: `[#15][#22] 사용자 프로필 및 설정 화면 UI 구현`

**Rationale**: Consistent synchronization across Issue/PR/Commits creates clear
audit trail, enables automated traceability, simplifies code review by maintaining
narrative coherence, and prevents confusion when multiple team members or AI agents
collaborate. Synchronized titles and messages allow anyone to understand the full
context of changes from Issue creation through merge without hunting across multiple
artifacts. This principle is critical for maintaining project transparency, enabling
effective collaboration, and supporting automated workflows like release note
generation and impact analysis.

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

**Version**: 1.7.0 | **Ratified**: 2025-12-17 | **Last Amended**: 2025-12-17
