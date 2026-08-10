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
        Integer ps = pageSize != null ? Math.min(Math.max(pageSize, 1), 30) : 12;
        Integer off = offset != null ? Math.max(offset, 0) : 0;

        List<String> allIds;
        try {
            allIds = P2P_CalloutService.getHNTopStoryIds(false);
        } catch (Exception e) {
            throw new AuraHandledException('Failed to fetch top story IDs: ' + e.getMessage());
        }

        if (allIds == null || allIds.isEmpty() || off >= allIds.size()) {
            return new List<StoryTile>();
        }

        Integer endIdx = Math.min(off + ps, allIds.size());
        List<String> pageIds = new List<String>();
        for (Integer i = off; i < endIdx; i++) {
            pageIds.add(allIds[i]);
        }

        List<StoryTile> tiles = new List<StoryTile>();
        for (String id : pageIds) {
            try {
                ResponseWrapper rw = P2P_CalloutService.getHNItemAsWrapper(id, false);
                if (rw == null) continue;
                StoryTile t = new StoryTile();
                t.itemId = rw.ItemId;
                t.title = String.isNotBlank(rw.title) ? rw.title : '(No title) #' + rw.ItemId;
                t.url = rw.url;
                t.hasUrl = String.isNotBlank(rw.url);
                t.score = rw.score;
                t.postedBy = rw.postedBy;
                t.unixTime = rw.UnixTime;
                t.itemType = rw.Itemtype;
                t.descendants = rw.descendants;
                t.kids = rw.kids;
                t.kidsCount = rw.kids != null ? rw.kids.size() : 0;
                if (String.isNotBlank(rw.UnixTime)) {
                    try {
                        Long epochMs = Long.valueOf(rw.UnixTime) * 1000L;
                        DateTime dt = DateTime.newInstance(epochMs);
                        t.formattedTime = dt.format('yyyy-MM-dd HH:mm');
                    } catch (Exception ex) {
                        t.formattedTime = rw.UnixTime;
                    }
                }
                tiles.add(t);
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'TopStories tile fetch failed for id ' + id + ': ' + e.getMessage());
            }
        }
        // Buffered persistence - see BestStoriesController
        return tiles;
    }

    @AuraEnabled(cacheable=false)
    public static Integer getTopStoriesCount() {
        try {
            List<String> ids = P2P_CalloutService.getHNTopStoryIds(false);
            return ids != null ? ids.size() : 0;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to get count: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static ResponseWrapper getStoryById(String itemId) {
        if (String.isBlank(itemId)) throw new AuraHandledException('itemId required');
        return P2P_CalloutService.getHNItemAsWrapper(itemId, false);
    }

    @AuraEnabled(cacheable=false)
    public static List<StoryTile> getTopStoriesTilesFromStore(Integer pageSize, Integer offset) {
        List<String> allIds = P2P_CalloutService.getHNTopStoryIdsFromStore();
        Integer ps = pageSize != null ? Math.min(Math.max(pageSize, 1), 30) : 12;
        Integer off = offset != null ? Math.max(offset, 0) : 0;
        if (allIds == null || allIds.isEmpty() || off >= allIds.size()) return new List<StoryTile>();
        Integer endIdx = Math.min(off + ps, allIds.size());
        List<StoryTile> tiles = new List<StoryTile>();
        for (Integer i = off; i < endIdx; i++) {
            String id = allIds[i];
            try {
                ResponseWrapper rw = P2P_CalloutService.getHNItemFromStore(id);
                StoryTile t = new StoryTile();
                t.itemId = rw.ItemId; t.title = String.isNotBlank(rw.title) ? rw.title : '(No title) #' + rw.ItemId;
                t.url = rw.url; t.hasUrl = String.isNotBlank(rw.url); t.score = rw.score; t.postedBy = rw.postedBy;
                t.unixTime = rw.UnixTime; t.itemType = rw.Itemtype; t.descendants = rw.descendants; t.kids = rw.kids; t.kidsCount = rw.kids != null ? rw.kids.size() : 0;
                if (String.isNotBlank(rw.UnixTime)) {
                    try { Long epochMs = Long.valueOf(rw.UnixTime) * 1000L; DateTime dt = DateTime.newInstance(epochMs); t.formattedTime = dt.format('yyyy-MM-dd HH:mm'); } catch(Exception ex) { t.formattedTime = rw.UnixTime; }
                }
                tiles.add(t);
            } catch(Exception e) { System.debug(LoggingLevel.WARN, 'TopStories store fetch failed '+id+': '+e.getMessage()); }
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
        try { return P2P_CalloutService.getHNTopStoryIdsFromStore().size(); } catch(Exception e) { throw new AuraHandledException('No stored count: '+e.getMessage()); }
    }
}
