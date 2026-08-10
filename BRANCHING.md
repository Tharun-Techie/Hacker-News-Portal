# Branching Strategy (Simplified – Single Dev, No PR)

## Model
- `main` = production (single prod branch)
- `dev`  = integration / development – active branch, direct commits allowed
- `feature/*` = short-lived from `dev` – e.g. `feature/
- `hotfix/*` = from `main` – merged to both `main` + `dev` if needed
- No pull requests required (single dev workflow)

## Rules
1. Direct commits/merges to `dev` allowed – no PR, no approval gate
2. Keep history linear – rebase `feature/*` on `dev` before merge, 
3. Merge commit (`--no-ff`) only for `dev` -> `main` promotions + semver tags `vX.Y.Z`

## Flow
```
feature/* --squash--> dev --merge-commit--> main --tag--> release
hotfix/* from main --> main + dev (if needed)
```

## Example
- `feature/cleanup` -> `dev` (squash)
- `feature/p2p-callout` -> `dev` (squash)
- `dev` -> `main` (merge commit, tag `v0.2.0`)
