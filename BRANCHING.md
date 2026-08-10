# Branching Strategy

## Model (Simplified GitFlow for SFDX)
- `main` = production (single prod branch, GitHub standard) – protected, no direct commits
- `dev`  = integration / pre-prod – protected, no direct commits
- `feature/*` = short-lived from `dev` – e.g. `feature/p2p-callout`, `feature/cleanup`
- `hotfix/*` = from `main` – merged to both `main` + `dev` – e.g. `hotfix/urgent-fix`
- `release/*` optional for sprint hardening

## Rules
1. No direct commits to `main`/`dev` – all via PR
2. PR required + status checks pass + 1 approval (see `.github/workflows/ci.yml`)
3. Squash merge for `feature/*` -> `dev` to keep linear history
4. Merge commit (`--no-ff`) only for `dev` -> `main` promotions + semver tags `vX.Y.Z`
5. Delete branch after merge (`gh pr merge --delete-branch`)
6. Conventional commits enforced via `commitlint` (`commitlint.config.js`) + husky `commit-msg`
7. Keep history linear – rebase feature on `dev` before PR if needed

## Flow
```
feature/* --PR squash--> dev --PR merge-commit--> main --tag--> release
hotfix/* from main --> main + dev
```

## Example (see /tmp/opencode/gitflow-demo)
- `feature/cleanup` -> `dev` (squash)
- `feature/p2p-callout` -> `dev` (squash)
- `dev` -> `main` (merge commit, tag `v0.2.0`)
- `hotfix/urgent-fix` from `main` -> `main` (tag `v0.2.1`) + `dev`
