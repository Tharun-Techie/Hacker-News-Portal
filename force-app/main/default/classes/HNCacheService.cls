public with sharing class HNCacheService {

    // Pending buffer for HN_DataObject cache - avoids uncommitted work pending between callouts
    private static Map<String, HN_DataObject__c> pendingByItemId = new Map<String, HN_DataObject__c>();

    /**
     * Try to get cached ResponseWrapper for itemId from HN_DataObject__c (or pending buffer).
     * Returns null if not cached.
     */
    public static ResponseWrapper getFromCache(String itemId) {
        if (String.isBlank(itemId)) return null;
        // Check pending first (not yet flushed)
        if (pendingByItemId.containsKey(itemId)) {
            return P2P_ResponseProcessor.fromHNDataObject(pendingByItemId.get(itemId));
        }
        try {
            Decimal idNum = Decimal.valueOf(itemId);
            List<HN_DataObject__c> objs = [SELECT Id, Name, Username__c, Descendants__c, ItemId__c, Kids__c, Score__c, Time__c, Text__c, Url__c, ItemType__c FROM HN_DataObject__c WHERE ItemId__c = :idNum LIMIT 1];
            if (!objs.isEmpty()) {
                return P2P_ResponseProcessor.fromHNDataObject(objs[0]);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'HNCacheService getFromCache failed for ' + itemId + ': ' + e.getMessage());
        }
        return null;
    }

    /**
     * Bulk get cached wrappers for list of ids - single SOQL.
     */
    public static Map<String, ResponseWrapper> getBulkFromCache(List<String> itemIds) {
        Map<String, ResponseWrapper> result = new Map<String, ResponseWrapper>();
        if (itemIds == null || itemIds.isEmpty()) return result;
        Set<Decimal> idNums = new Set<Decimal>();
        for (String id : itemIds) {
            try {
                Decimal n = Decimal.valueOf(id);
                idNums.add(n);
            } catch (Exception e) {}
            // Also check pending
            if (pendingByItemId.containsKey(id)) {
                result.put(id, P2P_ResponseProcessor.fromHNDataObject(pendingByItemId.get(id)));
            }
        }
        if (idNums.isEmpty()) return result;
        try {
            List<HN_DataObject__c> objs = [SELECT Username__c, Descendants__c, ItemId__c, Kids__c, Score__c, Time__c, Text__c, Url__c, ItemType__c FROM HN_DataObject__c WHERE ItemId__c IN :idNums];
            for (HN_DataObject__c o : objs) {
                String strId = String.valueOf(o.ItemId__c);
                if (!result.containsKey(strId)) {
                    // Normalize to string without decimal places
                    String normalized = strId.contains('.') ? strId.substringBefore('.') : strId;
                    if (!result.containsKey(normalized)) {
                        result.put(normalized, P2P_ResponseProcessor.fromHNDataObject(o));
                    }
                    result.put(strId, P2P_ResponseProcessor.fromHNDataObject(o));
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'HNCacheService bulk get failed: ' + e.getMessage());
        }
        return result;
    }

    /**
     * Put ResponseWrapper into pending cache buffer (dedup by ItemId). Call flushCache() after burst.
     */
    public static void putToCache(ResponseWrapper rw) {
        if (rw == null || String.isBlank(rw.ItemId)) return;
        try {
            HN_DataObject__c obj = P2P_ResponseProcessor.toHNDataObject(rw);
            if (obj == null || obj.ItemId__c == null) return;
            pendingByItemId.put(rw.ItemId, obj);
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'HNCacheService putToCache failed: ' + e.getMessage());
        }
    }

    /**
     * Flush pending HN_DataObject cache to DB (insert or update). Call after all callouts.
     * Handles unique ItemId__c by querying existing and splitting insert/update.
     */
    public static Integer flushCache() {
        if (pendingByItemId.isEmpty()) return 0;
        Map<String, HN_DataObject__c> toFlush = new Map<String, HN_DataObject__c>(pendingByItemId);
        pendingByItemId.clear();
        try {
            // Find existing by ItemId
            Set<Decimal> ids = new Set<Decimal>();
            for (HN_DataObject__c o : toFlush.values()) ids.add(o.ItemId__c);
            Map<Decimal, HN_DataObject__c> existingByItemId = new Map<Decimal, HN_DataObject__c>();
            for (HN_DataObject__c ex : [SELECT Id, ItemId__c FROM HN_DataObject__c WHERE ItemId__c IN :ids]) {
                existingByItemId.put(ex.ItemId__c, ex);
            }
            List<HN_DataObject__c> toInsert = new List<HN_DataObject__c>();
            List<HN_DataObject__c> toUpdate = new List<HN_DataObject__c>();
            for (HN_DataObject__c obj : toFlush.values()) {
                HN_DataObject__c existing = existingByItemId.get(obj.ItemId__c);
                if (existing != null) {
                    obj.Id = existing.Id;
                    toUpdate.add(obj);
                } else {
                    toInsert.add(obj);
                }
            }
            Integer count = 0;
            if (!toInsert.isEmpty()) {
                Database.SaveResult[] sr = Database.insert(toInsert, false);
                for (Database.SaveResult r : sr) if (r.isSuccess()) count++;
                else System.debug(LoggingLevel.WARN, 'HNCache insert failed: ' + r.getErrors()[0].getMessage());
            }
            if (!toUpdate.isEmpty()) {
                Database.SaveResult[] sr = Database.update(toUpdate, false);
                for (Database.SaveResult r : sr) if (r.isSuccess()) count++;
                else System.debug(LoggingLevel.WARN, 'HNCache update failed: ' + r.getErrors()[0].getMessage());
            }
            return count;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'HNCacheService flushCache failed: ' + e.getMessage() + ' ' + e.getStackTraceString());
            // Re-buffer for retry
            for (HN_DataObject__c o : toFlush.values()) {
                String sid = String.valueOf(o.ItemId__c);
                pendingByItemId.put(sid, o);
            }
            return 0;
        }
    }

    public static Integer pendingCount() { return pendingByItemId.size(); }
    @TestVisible private static void clearCache() { pendingByItemId.clear(); }

    /**
     * Helper for P2P_CalloutService to get with cache fallback.
     */
    public static ResponseWrapper getWithCacheFallback(String itemId, Boolean useNC) {
        ResponseWrapper cached = getFromCache(itemId);
        if (cached != null) return cached;
        // Not cached - will be cached by caller after live fetch
        return null;
    }
}
