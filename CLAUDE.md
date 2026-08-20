# RoboNarc

Evolution of the RoboNarc game prototype. The original prototype lives at
`C:/code/gamedev/robo_narc` (Godot 4.6.2, GDScript) — its `GDD.md` is the
authoritative reference for the existing mechanics and tuning values. See
`README.md` here for the project introduction.

## Tracking

- **Jira project**: RoboNarc, key **ROB** — all work items go there

## Godot Conventions

- **Composition over pure scripting** — let scene composition drive behavior
  wherever possible; scripts support, composition extends
- **Small, well-named, single-purpose scripts** — favor more classes for specific
  tasks over bundling many functions into one script

## Repo Conventions

- **Not a standard tkforgeworks repo**: no CI/CD, no branch protection rules
- **Clean commit history**: greenfield repo — only commit when something genuinely
  needs to be stored; no work-in-progress or churn commits
- **Spec-first workflow planned**: the updated game will be built using
  [github/spec-kit](https://github.com/spec-kit). Keep the repo minimal until
  spec-kit is initialized; don't add scaffolding that would conflict with it
