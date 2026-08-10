# Validation + Deployment Feature

For each `feature/*` maintain separate `manifest/package-<feature>.xml` and run **validate then deploy** as feature.

## Flow (single-dev, no PR)
1. Create `feature/<name>` from `dev`
2. Add Apex/LWC + `manifest/package-<name>.xml` (explicit members, version 66.0)
3. Commit `feat(<name>): ...` + `chore(manifest): add package`
4. **Validate**: `sf project deploy start -o devOrg -x manifest/package-<name>.xml --dry-run --ignore-warnings --wait 10` (or `sf project deploy validate -o devOrg -x manifest/package-<name>.xml`)
   - Must be `11/11` or `5/5` succeeded, 0 failures (StoryBatch fixed to `List<String>`)
5. **Deploy**: `sf project deploy start -o devOrg -x manifest/package-<name>.xml --ignore-warnings`
6. Push `feature/*` → squash merge to `dev` → `git push origin dev` → `git checkout main && git merge --no-ff dev` → `git push origin main`

## Example Manifests
- `manifest/package-best-stories-tiles.xml` – BestStoriesController + bestStoriesTiles + P2P deps
- `manifest/package-top-stories-tiles.xml` – TopStoriesController + topStoriesTiles + P2P deps
- `manifest/package-p2p-callout.xml` – P2P_* 5 classes
- `manifest/package-cleanup.xml` – cleanup project components

## Validation & Deploy Logs
- best-stories: dry-run `11/11` + deploy `0AfdL00000f0ruLSAQ` succeeded
- top-stories: dry-run `11/11` + deploy `0AfdL00000f0stdSAA` succeeded
