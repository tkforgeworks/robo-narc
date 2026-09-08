# Traffic Fighter 3: Next Generation (TF3)

Evolution of the RoboNarc game prototype (the repo keeps that name). The original prototype lives at
`C:/code/gamedev/robo_narc` (Godot 4.6.2, GDScript) — its `GDD.md` is the
authoritative reference for the existing mechanics and tuning values. See
`README.md` here for the project introduction.

## Tracking

- **Jira project**: TF3, key **ROB** — all work items go there

## Godot Conventions

- **Composition over pure scripting** — let scene composition drive behavior
  wherever possible; scripts support, composition extends
- **Small, well-named, single-purpose scripts** — favor more classes for specific
  tasks over bundling many functions into one script

## Repo Conventions

- **CI**: `.github/workflows/ci.yml` runs the headless GUT tests and a web export
  with a compressed-size report on every push to `main` and every PR (constitution
  Principle V: this workflow is part of the org template). No branch protection rules
- **Clean commit history**: greenfield repo — only commit when something genuinely
  needs to be stored; no work-in-progress or churn commits. Spec-kit docs under
  `.specify/` and `specs/` are the exception and get brief `docs:` commits
- **Template layer docs**: `docs/template-extraction.md` lists every `[core]` file and
  how to lift the skeleton into the org starter template (constitution Principle V)
- **Spec-first workflow**: built with [github/spec-kit](https://github.com/spec-kit).
  Constitution at `.specify/memory/constitution.md`; feature artifacts under `specs/`

## Building & Testing

- **Godot**: 4.6.2 stable, GL Compatibility. Console binary on this machine:
  `C:\Program Files\Godot\Godot 4.6.2\Godot_v4.6.2-stable_win64_console.exe`
- **Tests** (GUT 9, headless):
  `godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit`
- **Web export**: `godot --headless --path . --export-release "Web" build/web/index.html`
  then serve `build/web` over localhost (wasm will not run from `file://`)
- **Layout**: `src/core/` + `scenes/core/` + `tests/core/` are the game-agnostic
  template layer; `src/game/`, `scenes/game/`, `data/game/` are TF3. Art lives
  under `assets/` per `specs/001-robonarc-game/contracts/asset-conventions.md`;
  drop-in vehicle variants go in `assets/vehicles/<style>/` with an inherited scene in
  `scenes/game/vehicles/<style>.tscn` (plate, body, and probe rectangles are authored there)
