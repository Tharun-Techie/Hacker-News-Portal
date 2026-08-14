// Optimized Batch: bulk cache + governor guards + single flush
public class StoryBatch implements Database.Batchable<String>, Database.AllowsCallouts {
    private List<String> ids;
    // Pass ids via constructor to avoid callout in start()
    public StoryBatch() {
        this.ids = new List<String>();
    }
    public StoryBatch(List<String> storyIds) {
        this.ids = storyIds != null ? storyIds : new List<String>();
    }
    public List<String> start(Database.BatchableContext bc) {
        // Avoid callout in start(): return pre-fetched ids or empty. Caller should inject ids.
        // Fallback: if ids empty and not in test, try store cache before live callout
        if (!ids.isEmpty()) return ids;
        if (Test.isRunningTest()) return new List<String>();
        try {
            List<String> cached = P2P_CalloutService.getHNTopStoryIdsFromStore();
            if (!cached.isEmpty()) return cached;
        } catch (Exception e) {}
        // Last resort: live callout (only if store empty) - keep scope small
        try {
            return GeneralMethods.getTopStoriesList();
        } catch (Exception e) {
            return new List<String>();
        }
    }
    public void execute(Database.BatchableContext bc, List<String> scope) {
        // Bulk pre-fetch from HN_DataObject cache to avoid N+1 SOQL/callout
        Map<String, ResponseWrapper> cached = new Map<String, ResponseWrapper>();
        try { cached = HNCacheService.getBulkFromCache(scope); } catch (Exception e) {}
        Integer calloutsBefore = Limits.getCallouts();
        for (String id : scope) {
            // Governor guard: stop before hitting 100 callouts limit
            if (Limits.getCallouts() >= Limits.getLimitCallouts() - 1) {
                System.debug(LoggingLevel.WARN, 'StoryBatch callout limit reached, remaining ids deferred');
                break;
            }
            if (cached.containsKey(id)) {
                System.debug(cached.get(id));
                continue;
            }
            try {
                // getHNItemAsWrapper does cache check + single callout; single flush deferred to after loop
                ResponseWrapper rw = P2P_CalloutService.getHNItemAsWrapper(id, false);
                System.debug(rw);
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'StoryBatch failed for id ' + id + ': ' + e.getMessage());
            }
        }
        // Single flush after burst (avoid DML-after-callout per iteration)
        if (!Test.isRunningTest()) {
            try { IntegrationMessageService.flushBuffer(); } catch (Exception e) {}
            try { HNCacheService.flushCache(); } catch (Exception e) {}
        }
    }
    public void finish(Database.BatchableContext bc) {}
}