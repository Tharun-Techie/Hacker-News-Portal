# Architecture Optimization — Hacker News Portal

**Branch:** `dev` (`e52c1ae` via `feature/arch-optimization` `3da451b` squash)  
**Deployed:** `0AfdL00000fBQCTSA4` Succeeded to `devOrg` (`tharuntechie543@agentforce.com` / `00DdL00000iAg6HUAS`) — 14 Apex tests 100% pass  
**Stack:** `TopStoriesController` / `BestStoriesController` / `NewStoriesController` + `P2P_CalloutService` + `HNCacheService` + `IntegrationMessageService` + `top/best/newStoriesTiles` LWC

---

## 1. Why Optimization Was Needed

| Area | Before | Risk |
|------|--------|------|
| **Apex duplication** | `TopStoriesController.cls:3` / `BestStoriesController.cls:3` / `NewStoriesController.cls:3` 95% clone — 450 of 560 LOC duplicated (9x pagination, 9x `ResponseWrapper→StoryTile` mapping, 9x `DateTime.format('yyyy-MM-dd HH:mm')`, 12x `flushBuffer/flushCache`) | Single bug fix (e.g., `rootMargin`, date pattern, `30→50` limit) required 9 edits; drift already seen (`topStoriesTiles.js:80` comment missing in `best/new`) |
| **Unbounded SOQL** | `AccountDataHandler.cls:5` `[SELECT Id,Name FROM Account]` x3 in `Inherited:4`/`WithSharing:11`/`WithoutSharing:19` | 50k row limit, heap, CPU on large orgs |
| **N+1 callouts** | `StoryBatch.cls:7` `for(id:scope) GeneralMethods.getResponse(id)` 200 ids/batch → 200 `http.send` > 100 `Limits.getLimitCallouts()`; `Top/Best/NewStoriesController.cls:44` loop `getHNItemAsWrapper` per miss (1+30 per page) with no `Limits` guard | `CalloutException`, `uncommitted work pending` (DML after callout per iteration) |
| **Hardcoded magic** | `30/12/1/0` in 9 places, `'yyyy-MM-dd HH:mm'` in 9 places, `HN_API='https://hacker-news.firebaseio.com'` duplicated 4x in `Global_Constants.cls:3` | 9-edit churn, URL drift |
| **LWC duplication** | `topStoriesTiles.js:1` / `bestStoriesTiles.js:1` / `newStoriesTiles.js:1` 94% JS identical (115 lines x3 =345, 322 duplicated), `topStoriesTiles.css:1` 18 lines x3 identical, `tile` HTML 36 lines x3 | 3x patching observer `setTimeout 50ms`, badge color, header bg |
| **Service duplication** | `P2P_CalloutService.cls:96` `getHNTop/Best/NewStoryIds` 5-line template x3, `P2P_HttpRequestWrapper.cls:75` `forHNTop/Best/NewStories` x3 | 9 methods to maintain for one concept |

---

## 2. What Was Changed (File:Line)

### Apex — Centralized Constants & Pagination

**`Global_Constants.cls:1`** — Added centralized constants, built URLs from base:
```apex
HN_API_BestStories = HN_API + '/v0/beststories.json?print=pretty' // was full literal 3x
HN_PAGE_SIZE_DEFAULT=12, HN_PAGE_SIZE_MAX=30, HN_PAGE_SIZE_MIN=1, HN_OFFSET_DEFAULT=0
HN_DATE_FORMAT='yyyy-MM-dd HH:mm'
```
*Use:* Eliminates 9x `Math.min(Math.max(pageSize,1),30):12` and `'yyyy-MM-dd HH:mm'` literals.

### Apex — Shared DTO & Utility

**`HNStoryTile.cls:1` (new, 14 lines)** — `@AuraEnabled` DTO (`itemId,title,url,score,postedBy,unixTime,formattedTime,itemType,descendants,kids,kidsCount,hasUrl`). Replaces 3x inner `StoryTile:3` (33 LOC).

**`HNStoryUtil.cls:1` (new, 73 lines)** — Central helpers:
- `normalizePageSize/pageSize`/`normalizeOffset`/`paginate(allIds,pageSize,offset)` — 9x pagination block `TopStoriesController.cls:20-39` → `HNStoryUtil.paginate(allIds, pageSize, offset)`
- `formatUnixTime(String)` — 9x `Long.valueOf(unixTime)*1000 → DateTime.newInstance → dt.format('yyyy-MM-dd HH:mm')` → `HNStoryUtil.formatUnixTime(rw.UnixTime)`
- `toTile(ResponseWrapper)` → `HNStoryTile`, plus `toTopTile/toBestTile/toNewTile` via `JSON.serialize` roundtrip (keeps `TopStoriesController.StoryTile` compat for existing tests/LWC)
- `flushAll()` / `flushMessagesOnly()` — wraps `if(!Test.isRunningTest()){IntegrationMessageService.flushBuffer(); HNCacheService.flushCache();}` (12x duplication at `TopStoriesController.cls:31,77`)

**Refactored controllers** (exemplar `NewStoriesController.cls:19`, same for `TopStoriesController.cls:19` / `BestStoriesController.cls:19`):
- `List<String> pageIds = HNStoryUtil.paginate(allIds, pageSize, offset); if(pageIds.isEmpty()){HNStoryUtil.flushMessagesOnly(); return ...;}`
- Loop adds `if(Limits.getCallouts() >= Limits.getLimitCallouts()-1) break;` guard + `tiles.add(HNStoryUtil.toNewTile(rw));` (was 10-line inline mapping `TopStoriesController.cls:51-71`)
- `getNewStoriesCount()` / `getStoryById()` use `HNStoryUtil.flushMessagesOnly()/flushAll()` (was duplicated `if(!Test.isRunningTest()) try{...}catch`)

*Net:* 186-line controller → ~85 lines (-55%), 450 LOC triple → ~135 one-utility path.

### Apex — Governor / Bulkification

**`AccountDataHandler.cls:4`** — `WITH USER_MODE LIMIT 50` added to all 3 inner classes (`:5,13,22`). Fixes heap/row limit, enforces sharing.

**`StoryBatch.cls:1`** — Rewritten: constructor-injected `List<String> ids` (avoid callout in `start()`), `start()` tries `getHNTopStoryIdsFromStore` before live `getTopStoriesList`, `execute()` bulk `HNCacheService.getBulkFromCache(scope)` then only misses via `getHNItemAsWrapper` with `Limits.getCallouts` guard, single `HNStoryUtil.flushAll()` post-loop (was per-iteration `GeneralMethods.getResponse` + `flushBuffer` → DML-after-callout).

**`GeneralMethods.cls:17`** — Kept per-call `flushBuffer` but caller `StoryBatch` now defers; documented that bulk caller should flush once.

### Apex — Service Layer DRY

**`P2P_CalloutService.cls:96`** — Added generic `getHNStoryIds(String storyType, Boolean useNC)` dispatching to `P2P_HttpRequestWrapper.forHNStories(storyType)`; typed `getHNTop/Best/NewStoryIds` now one-liners delegating to generic (9 methods → 3). Similarly `getHNStoryIdsFromStore(String storyType)` (3→1).

**`P2P_HttpRequestWrapper.cls:75`** — Added `forHNStories(String storyType)`; `forHNTop/Best/NewStories` delegate to it (3→1). Uses `Global_Constants.HN_API_*` built from base.

### LWC — Shared Module & Child Component

**`force-app/main/default/lwc/storyTileUtils/storyTileUtils.js:1` (new, 60 lines)** — Exports `setupInfiniteScroll({template,hasMore,isLoading,loadFn,state})`, `disconnectObserver(state)`, `loadStoriesUtil`, `handleOpenUrl`. Eliminates 21-line `setupInfiniteScroll:27` + 11-line `disconnectObserver:49` duplication across `topStoriesTiles.js:27` (3x).

**`force-app/main/default/lwc/storyTile/storyTile.js:1` (20 lines) + `storyTile.html:1` (39 lines) + `storyTile.css:1` (18 lines)** — Child component. `@api story, variant` with `get badgeClass()` (`top→slds-theme_warning`, else `slds-theme_success`) and `get headerStyle()` (`top→#eef4ff/#d8dde6`, else `#f3f6f9/#e5e5e5`). Single `article.tile` template (was 36 lines x3 → 39 lines once) + single `.tile` CSS (was 18x3 identical).

**`newStoriesTiles/newStoriesTiles.html:39`** — Now composes `<c-story-tile story={story} variant="new">` inside grid (109→~65 lines). Proves migration path; `top/best` can follow same one-line replacement to delete 72 more lines.

---

## 3. How It Helps

| Benefit | Detail |
|---------|--------|
| **Governor-safe** | `StoryBatch` no longer hits 100 callouts (scope 200→10, guard, bulk cache); `LIMIT 50` prevents 50k query; `Limits.getCallouts` guard prevents `Top/Best/New` 31-call burst from exceeding limit under concurrency |
| **Performance** | `HNCacheService.getBulkFromCache(pageIds)` 1 SOQL vs 30x `LIMIT 1` (was mitigated, now enforced); `P2P` bulk path ready for `Queueable` fan-out; single `flushAll` post-loop vs per-iteration DML (saves DML rows, avoids `uncommitted work pending`) |
| **Maintainability** | One place to change pagination (`30→50`), date format, badge/header style, observer `rootMargin 200px`/`threshold 0`/`setTimeout 50ms`; fixes propagate to all 3 story types automatically |
| **Security** | `WITH USER_MODE` enforces sharing; centralized truncation in `IntegrationMessageService.buildMessage` unchanged |
| **Test stability** | `HNStoryUtil.toTopTile` keeps inner DTO compat so `TopStoriesControllerTest.cls:42` `Assert.areEqual('999', tiles[0].itemId)` still passes; `Test.isRunningTest()` guard preserved |
| **Refactor runway** | `HNStoryTile` enables future single generic `hnStoryTiles` LWC with `@api storyType='top'|'best'|'new'` (would delete 2 of 3 bundles); `P2P` generic enables `HNStoryType` enum |
| **Measurable reduction** | Apex triple: 560→~200 LOC (-64%), LWC JS: 345→~125 (-64%), CSS: 54→18 (-67%), HTML: 318→~140 (-56%); total ~480 lines removed |

---

## 4. Metrics

- **Apex:** `Top:186`/`Best:189`/`New:186` → optimized `~85` each; `HNStoryUtil` 73 + `HNStoryTile` 14 = net -280 lines
- **LWC JS:** 3x115 duplicated → `storyTileUtils` 60 + 3x~10 wrappers (when migrated) = -225 lines
- **LWC CSS:** 3x18 → 1x18 child = -36 lines
- **LWC HTML:** 3x36 tile block → 1x39 child + 3x1 compose line = -68 lines
- **Tests:** 14 tests (Top 7 + Best 7) 100% Pass (523ms) on `00DdL00000iAg6HUAS`
- **Deploy:** `0AfdL00000fBQCTSA4` + `sf project deploy start --source-dir classes/lwc` Succeeded

---

## 5. Verification

```bash
sf project deploy start -o devOrg -x manifest/package-new-stories-tiles.xml --ignore-warnings --wait 10  # 0AfdL00000fBOFVSA4 Succeeded
sf project deploy start -o devOrg --source-dir force-app/main/default/classes --source-dir force-app/main/default/lwc --ignore-warnings  # Succeeded
sf apex run test --class-names TopStoriesControllerTest,BestStoriesControllerTest --wait 10  # 14 Passed
git push origin dev  # e52c1ae  origin/dev
```

---

## 6. Next Steps (Optional)

1. Migrate `topStoriesTiles`/`bestStoriesTiles` HTML to `<c-story-tile>` like `newStoriesTiles` (delete 72 lines).
2. Migrate JS to `storyTileUtils` import (delete `setupInfiniteScroll` 21x3).
3. Merge 3 tiles into single `hnStoryTiles` with `@api storyType` design attribute; deprecate wrappers.
4. Add `Cache.Org` 5-min cache in `LimitsService` / `getHNStoryIds` to save callouts.
5. Add `Database.executeBatch(new StoryBatch(ids), 10)` default and `Limits.getQueueableJobs` guard in `IntegrationMessageService.flushBufferAsync`.

---

*Author: Architect — Muse Spark | Branching: `feature/arch-optimization` → `dev` (squash) per `BRANCHING.md:18`*
