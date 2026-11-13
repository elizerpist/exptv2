---
name: flutter-feature
description: Use when implementing a concrete Flutter feature in the current Git repository after its Flutter application scaffold exists; do not use for repository setup, agent-tooling preparation, documentation-only changes, or planning-only requests.
---

# Flutter Feature Pipeline

Use this skill only for a requested, concrete Flutter feature in the current
repository. It is not a repository bootstrap or agent-tooling skill.

## Activation gate

Before starting the pipeline:

1. Confirm the current directory is inside the intended Git repository and set
   `ROOT` to `git rev-parse --show-toplevel`.
2. Read `ROOT/AGENTS.md` and follow it. `AGENTS.md` is the repository contract;
   do not look for or require a different legacy instruction filename.
3. Confirm that a Flutter scaffold exists, including `ROOT/pubspec.yaml` and a
   Flutter source directory such as `ROOT/lib/`. If the scaffold is absent,
   stop and report that this skill is not applicable yet.
4. Confirm that the user requested an actual feature. Do not activate for
   repository setup, copying or editing agent skills, documentation-only work,
   or planning without implementation approval.

Keep all paths repository-relative after `ROOT` is established. Do not embed
absolute workstation, operating-system, home-directory, or other project paths
in plans, prompts, generated files, or commands.

## Pipeline

Complete each phase before starting the next. Use the agent orchestration and
tools that are actually available in the current environment. Do not require
named agents, roles, MCP servers, or platform-specific integrations that have
not been discovered. If orchestration is unavailable, perform the phases
directly and record the same outputs.

### Phase 1 — Data and architecture

- Read the feature request and applicable repository instructions.
- Inspect the existing Flutter structure, services, repositories, domain rules,
  state owners, and reusable widgets before adding new code.
- Define the data model, repository/use-case boundaries, state ownership, and
  dependency direction needed by the feature.
- Reuse or extend existing mechanisms; do not duplicate services, state
  machines, formatters, tokens, or UI primitives.

### Phase 2 — UI and interaction design

- Define the screen or widget hierarchy for the feature using the repository's
  existing theme and visual tokens.
- Specify loading, empty, error, success, and interaction states.
- Keep rendering and intent collection in the UI; keep multi-step workflows in
  controllers/view-models and use cases or coordinators.

### Phase 3 — Implementation

- Implement the feature in the repository's established directory structure;
  do not impose a feature path that the existing project does not use.
- Keep persistence, network, import, processing, retry, and domain workflows
  outside widgets.
- Add or extend boundary, unit, widget/integration, and relevant screenshot or
  performance evidence required by `AGENTS.md` and the feature's acceptance
  criteria.

### Phase 4 — Verification

- Run focused tests and static analysis, then the relevant complete test suite.
- Re-read `AGENTS.md` and verify every acceptance condition.
- Check the diff for accidental platform paths, secrets, duplicated logic, or
  changes outside the requested feature.
- Report incomplete, blocked, or deferred acceptance items explicitly.

## Usage

Invoke this skill only with a concrete Flutter feature request, for example:

`/flutter-feature Add a weekly summary view with totals per worker`
