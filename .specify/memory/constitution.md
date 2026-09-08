<!--
Sync Impact Report
- Version change: 1.0.0 → 1.1.0 (MINOR: new principle added, workflow guidance expanded)
- Modified principles: none renamed
- Added sections:
  - Core Principles: V. Organization Template Project
  - Development Workflow: "Commits" bullet expanded with spec-kit documentation
    commit rule and commit-message attribution rule (no session links)
- Removed sections: none
- Templates: not modified by this command (plan/spec/tasks templates read the
  constitution at runtime; the "Constitution Check" gate in plan-template should
  now be exercised against principles I–V on the next /speckit-plan run)
- Follow-up TODOs: none
- Prior report (1.0.0, 2026-09-07): initial ratification with Principles I–IV,
  Platform & Technical Constraints, Development Workflow, Governance
-->

# Traffic Fighter 3: Next Generation (TF3) Constitution

## Core Principles

### I. Composition First

Scene composition drives behavior; scripts support, composition extends.

- Every gameplay behavior MUST be expressed as a composed scene of nodes before a
  script solution is considered. A script MAY exist only to coordinate the nodes it
  owns or to hold logic that has no node-level equivalent (e.g. pure math, rulebooks).
- Reusable behavior (movement, spawning, timers, input handling, audio triggers) MUST
  be packaged as child component nodes or scenes that can be dropped into any parent
  without code edits to that parent.
- Communication between scenes MUST use signals, exported node references, or
  injected dependencies. Cross-scene reach-ins via `get_node` paths into unrelated
  trees and static mutable state are prohibited.
- Autoloads (singletons) MUST be justified individually and kept to the minimum.
  Default to scene-local composition; a new autoload requires a written rationale in
  the feature plan.

Rationale: composition is how Godot is meant to be extended. It keeps features
independently testable in isolation scenes, lets new content (vehicle variants,
roadside props, situations) be added by editing scenes rather than code, and is the
stated goal of this rebuild over the prototype's script-heavy approach.

### II. Small Class-Based Scripts

Every script is small, well named, and referenceable as a class.

- Every script MUST declare a `class_name` unless there is a documented reason it
  cannot (e.g. a throwaway test harness). Other scripts MUST reference it by that
  class name, never by preloading a script path.
- Each script MUST have a single responsibility that its name states plainly. A
  script that needs "and" to describe what it does MUST be split.
- Scripts SHOULD stay under roughly 150 lines; exceeding this is a signal to review
  for a missing extraction, not a hard failure. Scripts exceeding 300 lines MUST be
  split or carry a justification in the plan's Complexity Tracking.
- Static typing MUST be used on all declarations, parameters, and return types so
  that class references are checked by the editor.
- Pure logic (projection math, violation rules, scoring) MUST live in stateless
  classes with no scene dependencies so it can be unit tested without a scene tree.

Rationale: named classes make dependencies explicit and editor-checked, which is the
practical form of SOLID in GDScript. Many small, focused classes are easier to
compose (Principle I), test, and tune than a few god-scripts, and they let the
spec-kit workflow map tasks to files one-to-one.

### III. Web Compatibility Is Sacred (NON-NEGOTIABLE)

The game MUST always be playable from a web browser on a plain static host.

- The web export MUST remain a no-threads build that runs without cross-origin
  isolation headers (no SharedArrayBuffer, no COOP/COEP requirements).
- No feature may depend on threads, native extensions/GDExtensions without a web
  build, filesystem access outside `user://`, platform-only APIs, or renderer
  features unavailable in the GL Compatibility renderer.
- Any feature primarily targeting another platform (Android, desktop, gamepad,
  shared leaderboard) MUST either work identically on web or degrade gracefully with
  the core loop fully intact. "Works on Android but breaks web" is a rejected design.
- Every feature plan MUST state its web impact explicitly in the Constitution Check.
  A feature that cannot satisfy this principle MUST be redesigned or dropped; there
  is no exception path.
- Web build size and load time are design inputs: asset import settings MUST be
  chosen with web delivery in mind.

Rationale: a browser link is the game's lowest-friction distribution channel and the
one target that reaches everyone. Losing it, even temporarily, is a regression of the
whole project, so it outranks every other platform goal.

### IV. Everything Tunable via Debug Menu

All behavior variables MUST be adjustable at runtime from the debug menu.

- Any numeric or boolean value that shapes gameplay feel (speeds, accelerations,
  durations, timers, spawn intervals and weights, readable distances, score values,
  penalty values, ramp curves, audio volumes) MUST be exposed in the debug menu with
  live effect. Hard-coded magic numbers in behavior code are a defect.
- Tunables MUST be declared in a discoverable, typed form (exported properties or a
  dedicated tuning resource) so the debug menu can enumerate them rather than
  hand-wiring each one. Adding a new tunable MUST NOT require editing the menu.
- Every tunable MUST have a documented default that matches the GDD baseline
  tuning table, and the menu MUST offer a reset-to-defaults action.
- The debug menu MUST pause gameplay when open, MUST be available in all debug
  builds on all platforms (including web), and MUST be absent or inert in release
  builds.
- A feature is not complete until its tunables appear in the debug menu.

Rationale: this game lives or dies on feel, and the escalation curve, capture window,
and spawn pacing can only be found by adjusting values while playing. A live debug
menu turns tuning from an edit-export-test loop into seconds, which is critical both
for development and for final polish.

### V. Organization Template Project

TF3 is the first game project of the TK ForgeWorks organization and MUST be
built so that its structure can be lifted into an org-level Godot starter template.

- Project structure, CI/CD configuration, testing setup, export presets, debug
  tooling, and the spec-kit workflow MUST be designed as reusable, game-agnostic
  scaffolding first and TF3-specific content second. Game-specific code and
  assets MUST be separable from the reusable skeleton by directory boundary.
- Every reusable piece (directory layout, CI pipeline, test harness, debug menu
  framework, tuning-resource pattern, export configuration, agent guidance files)
  MUST be documented well enough that a new game project can adopt it without
  reading TF3's gameplay code.
- When a design choice is equally good for TF3 either way, the option that
  generalizes better to other Godot games MUST be preferred.
- Decisions that shape the template (tooling, CI, test framework, directory
  conventions) MUST be recorded with their rationale so they can be carried to the
  org-level repository with context intact.
- Extraction of the template into an org-level repository is a planned deliverable,
  not an afterthought; features MUST NOT introduce coupling that would make that
  extraction harder.

Rationale: the organization has no Godot baseline yet. Getting CI/CD, testing, and
project structure right once here, and keeping them cleanly separable from the game,
means every future TK ForgeWorks game starts from a proven template instead of
rediscovering the same setup.

## Platform & Technical Constraints

- **Engine**: Godot 4.x, GDScript, GL Compatibility renderer. Engine upgrades MUST be
  verified against the web export before adoption.
- **Targets**: Web (primary constraint, see Principle III), Windows desktop (primary
  dev target), Android (forced landscape, gamepad support). Aspect ratio is fixed
  with no stretch; letterbox gutters host touch controls.
- **Project hygiene**: no unused engine subsystems in project settings (the
  prototype's Jolt 3D physics and D3D12 settings are explicitly excluded).
- **Assets**: live under `assets/` by category with documented naming conventions.
  Vehicle variants and roadside props MUST be discovered or registered from data,
  never hard-coded in scripts, so new art requires no code changes.
- **External services**: the shared leaderboard MUST use plain HTTP via
  `HTTPRequest` with CORS-compatible endpoints. Any service that cannot be called from
  a browser is disqualified.
- **Persistence**: local data uses `user://` only. Settings and scores MUST survive on
  web (IndexedDB-backed `user://`) without special handling.
- **Reference**: the prototype's `GDD.md` (at `C:/code/gamedev/robo_narc`) and this
  repo's `GDD.md` are the authoritative sources for mechanics and baseline tuning
  values. Constitution principles override GDD implementation notes where they
  conflict.

## Development Workflow

- **Spec-first**: every feature flows through spec-kit (`/speckit-specify` →
  `/speckit-plan` → `/speckit-tasks` → `/speckit-implement`). Implementation without a
  spec and plan is out of process.
- **Constitution Check**: every plan MUST evaluate Principles I–V explicitly. A plan
  that violates Principle III is rejected outright; violations of I, II, IV, or V
  MUST be recorded in Complexity Tracking with a justification and a simpler
  alternative considered.
- **Tracking**: all work items live in Jira project ROB. Feature branches and specs
  reference their ROB key.
- **Increments**: tasks target independently shippable increments. Prefer fewer,
  slightly larger tasks that leave the game playable over many partial ones.
- **Commits**: only commit when something genuinely needs storing; every commit MUST
  leave the project opening cleanly in the editor and exporting to web. No
  work-in-progress or churn commits.
- **Spec-kit documentation commits**: additions or amendments to `.specify/`
  documentation (constitution, specs, plans, tasks, checklists) MUST be committed
  with a brief commit message describing the change. These commits are exempt from
  the "genuinely needs storing" bar because the documents are the project's planning
  record.
- **Commit message attribution**: commit messages MUST NOT contain session links,
  conversation URLs, or any other reference to the AI session that produced the
  change. Attributing work to Claude (e.g. a `Co-Authored-By` trailer) is permitted;
  linking to where it was produced is not.
- **Verification**: before a feature is marked done, it MUST be exercised in the
  web export, its tunables MUST be visible in the debug menu, and any pure-logic
  class it introduces SHOULD have unit tests.
- **Review**: reviews check composition (was a script written where a scene would
  do?), class naming and size, web impact, and tunable exposure, in that order.

## Governance

- This constitution supersedes all other project practices, including CLAUDE.md
  conventions and GDD implementation notes, where they conflict.
- **Amendments** require: a written rationale, an updated version line, a Sync
  Impact Report at the top of this file, and a review of the plan/spec/tasks
  templates for consistency. Amendments are committed on their own.
- **Versioning** follows semantic versioning: MAJOR for removing or redefining a
  principle in a backward-incompatible way, MINOR for adding a principle or section
  or materially expanding guidance, PATCH for clarifications and wording.
- **Compliance review**: every `/speckit-plan` Constitution Check and every code
  review MUST verify adherence. Unjustified violations block the feature. Complexity
  MUST be justified against a simpler alternative before being accepted.
- Runtime development guidance for agents lives in `CLAUDE.md`; it MUST stay
  consistent with this document and be updated when principles change.

**Version**: 1.1.0 | **Ratified**: 2026-09-07 | **Last Amended**: 2026-09-07
