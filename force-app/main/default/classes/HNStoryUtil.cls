public with sharing class HNStoryUtil {

    // Centralized pagination normalization (was duplicated 9x)
    public static Integer normalizePageSize(Integer pageSize) {
        if (pageSize == null) return Global_Constants.HN_PAGE_SIZE_DEFAULT;
        return Math.min(Math.max(pageSize, Global_Constants.HN_PAGE_SIZE_MIN), Global_Constants.HN_PAGE_SIZE_MAX);
    }
    public static Integer normalizeOffset(Integer offset) {
        return offset != null ? Math.max(offset, Global_Constants.HN_OFFSET_DEFAULT) : Global_Constants.HN_OFFSET_DEFAULT;
    }
    public static List<String> paginate(List<String> allIds, Integer pageSize, Integer offset) {
        Integer ps = normalizePageSize(pageSize);
        Integer off = normalizeOffset(offset);
        if (allIds == null || allIds.isEmpty() || off >= allIds.size()) return new List<String>();
        Integer endIdx = Math.min(off + ps, allIds.size());
        List<String> page = new List<String>();
        for (Integer i = off; i < endIdx; i++) page.add(allIds[i]);
        return page;
    }

    // Date formatting (was duplicated 9x)
    public static String formatUnixTime(String unixTime) {
        if (String.isBlank(unixTime)) return null;
        try {
            Long epochMs = Long.valueOf(unixTime) * 1000L;
            DateTime dt = DateTime.newInstance(epochMs);
            return dt.format(Global_Constants.HN_DATE_FORMAT);
        } catch (Exception e) {
            return unixTime;
        }
    }

    // Mapping ResponseWrapper -> shared HNStoryTile (centralized)
    public static HNStoryTile toTile(ResponseWrapper rw) {
        if (rw == null) return null;
        HNStoryTile t = new HNStoryTile();
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
        t.formattedTime = formatUnixTime(rw.UnixTime);
        return t;
    }

    // Legacy mapping to controller inner tiles via JSON roundtrip (keeps backward compat for Top/Best/New inner classes)
    public static TopStoriesController.StoryTile toTopTile(ResponseWrapper rw) {
        return (TopStoriesController.StoryTile) JSON.deserialize(JSON.serialize(toTile(rw)), TopStoriesController.StoryTile.class);
    }
    public static BestStoriesController.StoryTile toBestTile(ResponseWrapper rw) {
        return (BestStoriesController.StoryTile) JSON.deserialize(JSON.serialize(toTile(rw)), BestStoriesController.StoryTile.class);
    }
    public static NewStoriesController.StoryTile toNewTile(ResponseWrapper rw) {
        return (NewStoriesController.StoryTile) JSON.deserialize(JSON.serialize(toTile(rw)), NewStoriesController.StoryTile.class);
    }

    // Single flush helper (was duplicated 12x)
    public static void flushAll() {
        if (Test.isRunningTest()) return;
        try { IntegrationMessageService.flushBuffer(); } catch (Exception e) { System.debug(LoggingLevel.WARN, 'flushBuffer failed: ' + e.getMessage()); }
        try { HNCacheService.flushCache(); } catch (Exception e) { System.debug(LoggingLevel.WARN, 'HN cache flush failed: ' + e.getMessage()); }
    }
    public static void flushMessagesOnly() {
        if (Test.isRunningTest()) return;
        try { IntegrationMessageService.flushBuffer(); } catch (Exception e) {}
    }
}
