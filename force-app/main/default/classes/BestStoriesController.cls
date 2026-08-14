public with sharing class BestStoriesController {

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
    public static List<StoryTile> getBestStoriesTiles(Integer pageSize, Integer offset) {
        List<String> allIds;
        try {
            allIds = P2P_CalloutService.getHNBestStoryIds(false);
        } catch (Exception e) {
            throw new AuraHandledException('Failed to fetch best story IDs: ' + e.getMessage());
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
                System.debug(LoggingLevel.WARN, 'BestStories callout limit guard at id ' + id);
                break;
            }
            try {
                ResponseWrapper rw = cachedMap.get(id);
                if (rw == null) {
                    rw = P2P_CalloutService.getHNItemAsWrapper(id, false);
                    if (rw == null) continue;
                }
                tiles.add(HNStoryUtil.toBestTile(rw));
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'BestStories tile fetch failed for id ' + id + ': ' + e.getMessage());
            }
        }
        HNStoryUtil.flushAll();
        return tiles;
    }

    @AuraEnabled(cacheable=false)
    public static Integer getBestStoriesCount() {
        try {
            List<String> ids = P2P_CalloutService.getHNBestStoryIds(false);
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

    // ---- Fetch from Integration_Message (no live callout) ----
    @AuraEnabled(cacheable=false)
    public static List<StoryTile> getBestStoriesTilesFromStore(Integer pageSize, Integer offset) {
        List<String> allIds = P2P_CalloutService.getHNBestStoryIdsFromStore();
        List<String> pageIds = HNStoryUtil.paginate(allIds, pageSize, offset);
        if (pageIds.isEmpty()) return new List<StoryTile>();
        List<StoryTile> tiles = new List<StoryTile>();
        for (String id : pageIds) {
            try {
                ResponseWrapper rw = P2P_CalloutService.getHNItemFromStore(id);
                tiles.add(HNStoryUtil.toBestTile(rw));
            } catch (Exception e) { System.debug(LoggingLevel.WARN, 'BestStories store fetch failed id ' + id + ': ' + e.getMessage()); }
        }
        return tiles;
    }

    @AuraEnabled(cacheable=false)
    public static ResponseWrapper getStoryByIdFromStore(String itemId) {
        if (String.isBlank(itemId)) throw new AuraHandledException('itemId required');
        return P2P_CalloutService.getHNItemFromStore(itemId);
    }

    @AuraEnabled(cacheable=false)
    public static Integer getBestStoriesCountFromStore() {
        try { return P2P_CalloutService.getHNBestStoryIdsFromStore().size(); } catch (Exception e) { throw new AuraHandledException('No stored count: ' + e.getMessage()); }
    }

    // ---- Fetch from HN_DataObject cache (no live callout) - cached records ----
    @AuraEnabled(cacheable=false)
    public static List<StoryTile> getBestStoriesTilesFromHNCache(Integer pageSize, Integer offset) {
        List<String> allIds = P2P_CalloutService.getHNBestStoryIdsFromStore();
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
                tiles.add(HNStoryUtil.toBestTile(rw));
            } catch (Exception e) { System.debug(LoggingLevel.WARN, 'BestStories HN cache fetch failed id ' + id + ': ' + e.getMessage()); }
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
    public static Integer getBestStoriesCountFromHNCache() {
        try { return P2P_CalloutService.getHNBestStoryIdsFromStore().size(); } catch (Exception e) { throw new AuraHandledException('No cached count: ' + e.getMessage()); }
    }
}
