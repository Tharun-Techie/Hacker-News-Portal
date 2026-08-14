public with sharing class TopStoriesController {

    public class StoryTile {
        @AuraEnabled public String itemId;
        @AuraEnabled public String title;
        @AuraEnabled public String url;
        @AuraEnabled public String score;
        @AuraEnabled public String postedBy;
        @AuraEnabled public String unixTime;
        @AuraEnabled public String formattedTime;
        @AuraEnabled public String itemType;
        @AuraEnabled public String descendants;
        @AuraEnabled public List<String> kids;
        @AuraEnabled public Integer kidsCount;
        @AuraEnabled public Boolean hasUrl;
    }

    @AuraEnabled(cacheable=false)
    public static List<StoryTile> getTopStoriesTiles(Integer pageSize, Integer offset) {
        List<String> allIds;
        try {
            allIds = P2P_CalloutService.getHNTopStoryIds(false);
        } catch (Exception e) {
            throw new AuraHandledException('Failed to fetch top story IDs: ' + e.getMessage());
        }
        List<String> pageIds = HNStoryUtil.paginate(allIds, pageSize, offset);
        if (pageIds.isEmpty()) {
            HNStoryUtil.flushMessagesOnly();
            return new List<StoryTile>();
        }
        Map<String, ResponseWrapper> cachedMap = new Map<String, ResponseWrapper>();
        try { cachedMap = HNCacheService.getBulkFromCache(pageIds); } catch (Exception e) {}
        List<StoryTile> tiles = new List<StoryTile>();
        for (String id : pageIds) {
            if (Limits.getCallouts() >= Limits.getLimitCallouts() - 1) {
                System.debug(LoggingLevel.WARN, 'TopStories callout limit guard at id ' + id);
                break;
            }
            try {
                ResponseWrapper rw = cachedMap.get(id);
                if (rw == null) {
                    rw = P2P_CalloutService.getHNItemAsWrapper(id, false);
                    if (rw == null) continue;
                }
                tiles.add(HNStoryUtil.toTopTile(rw));
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'TopStories tile fetch failed for id ' + id + ': ' + e.getMessage());
            }
        }
        HNStoryUtil.flushAll();
        return tiles;
    }

    @AuraEnabled(cacheable=false)
    public static Integer getTopStoriesCount() {
        try {
            List<String> ids = P2P_CalloutService.getHNTopStoryIds(false);
            HNStoryUtil.flushMessagesOnly();
            return ids != null ? ids.size() : 0;
        } catch (Exception e) {
            HNStoryUtil.flushMessagesOnly();
            throw new AuraHandledException('Failed to get count: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static ResponseWrapper getStoryById(String itemId) {
        if (String.isBlank(itemId)) throw new AuraHandledException('itemId required');
        ResponseWrapper rw = P2P_CalloutService.getHNItemAsWrapper(itemId, false);
        HNStoryUtil.flushAll();
        return rw;
    }

    @AuraEnabled(cacheable=false)
    public static List<StoryTile> getTopStoriesTilesFromStore(Integer pageSize, Integer offset) {
        List<String> allIds = P2P_CalloutService.getHNTopStoryIdsFromStore();
        List<String> pageIds = HNStoryUtil.paginate(allIds, pageSize, offset);
        if (pageIds.isEmpty()) return new List<StoryTile>();
        List<StoryTile> tiles = new List<StoryTile>();
        for (String id : pageIds) {
            try {
                ResponseWrapper rw = P2P_CalloutService.getHNItemFromStore(id);
                tiles.add(HNStoryUtil.toTopTile(rw));
            } catch (Exception e) { System.debug(LoggingLevel.WARN, 'TopStories store fetch failed ' + id + ': ' + e.getMessage()); }
        }
        return tiles;
    }

    @AuraEnabled(cacheable=false)
    public static ResponseWrapper getStoryByIdFromStore(String itemId) {
        if (String.isBlank(itemId)) throw new AuraHandledException('itemId required');
        return P2P_CalloutService.getHNItemFromStore(itemId);
    }

    @AuraEnabled(cacheable=false)
    public static Integer getTopStoriesCountFromStore() {
        try { return P2P_CalloutService.getHNTopStoryIdsFromStore().size(); } catch (Exception e) { throw new AuraHandledException('No stored count: ' + e.getMessage()); }
    }

    // ---- Fetch from HN_DataObject cache (no live callout) ----
    @AuraEnabled(cacheable=false)
    public static List<StoryTile> getTopStoriesTilesFromHNCache(Integer pageSize, Integer offset) {
        List<String> allIds = P2P_CalloutService.getHNTopStoryIdsFromStore();
        List<String> pageIds = HNStoryUtil.paginate(allIds, pageSize, offset);
        if (pageIds.isEmpty()) return new List<StoryTile>();
        Map<String, ResponseWrapper> cached = new Map<String, ResponseWrapper>();
        try { cached = HNCacheService.getBulkFromCache(pageIds); } catch (Exception e) {}
        List<StoryTile> tiles = new List<StoryTile>();
        for (String id : pageIds) {
            try {
                ResponseWrapper rw = cached.get(id);
                if (rw == null) rw = HNCacheService.getFromCache(id);
                if (rw == null) continue;
                tiles.add(HNStoryUtil.toTopTile(rw));
            } catch (Exception e) { System.debug(LoggingLevel.WARN, 'TopStories HN cache fetch failed ' + id + ': ' + e.getMessage()); }
        }
        return tiles;
    }

    @AuraEnabled(cacheable=false)
    public static ResponseWrapper getStoryByIdFromHNCache(String itemId) {
        if (String.isBlank(itemId)) throw new AuraHandledException('itemId required');
        ResponseWrapper rw = HNCacheService.getFromCache(itemId);
        if (rw == null) throw new AuraHandledException('No cached HN_DataObject for item ' + itemId);
        return rw;
    }

    @AuraEnabled(cacheable=false)
    public static Integer getTopStoriesCountFromHNCache() {
        try { return P2P_CalloutService.getHNTopStoryIdsFromStore().size(); } catch (Exception e) { throw new AuraHandledException('No cached count: ' + e.getMessage()); }
    }
}
