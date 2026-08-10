public with sharing class P2P_ResponseProcessor {

    public class P2P_ResponseException extends Exception {}

    /**
     * Process raw HttpResponse into wrapper. Does not throw on non-2xx, instead marks isSuccess=false.
     */
    public static P2P_HttpResponseWrapper process(HttpResponse res) {
        P2P_HttpResponseWrapper wrap = new P2P_HttpResponseWrapper(res);
        return wrap;
    }

    /**
     * Process and throw if not success. Use when caller wants exception on failure.
     */
    public static P2P_HttpResponseWrapper processOrThrow(HttpResponse res) {
        P2P_HttpResponseWrapper wrap = new P2P_HttpResponseWrapper(res);
        if (!wrap.isSuccess) {
            throw new P2P_ResponseException(wrap.errorMessage + ' Body:' + wrap.body);
        }
        return wrap;
    }

    /**
     * Sanitize HN JSON keys: by->postedBy, id->ItemId, time->UnixTime, type->Itemtype
     * Uses regex with case-insensitive key match to avoid replacing values.
     */
    public static String sanitizeHNJson(String jsonBody) {
        if (String.isBlank(jsonBody)) {
            throw new P2P_ResponseException('Response is Null or Empty');
        }
        // Replace only JSON keys (quoted)
        String sanitized = jsonBody
            .replaceAll('(?i)"by"\\s*:', '"postedBy":')
            .replaceAll('(?i)"id"\\s*:', '"ItemId":')
            .replaceAll('(?i)"time"\\s*:', '"UnixTime":')
            .replaceAll('(?i)"type"\\s*:', '"Itemtype":');
        return sanitized;
    }

    /**
     * Generic JSON deserialize with sanitization option.
     */
    public static Object deserialize(String body, Type targetType, Boolean sanitizeHN) {
        if (String.isBlank(body)) return null;
        String toParse = sanitizeHN ? sanitizeHNJson(body) : body;
        return JSON.deserialize(toParse, targetType);
    }

    public static List<String> parseStringList(String body) {
        if (String.isBlank(body)) return new List<String>();
        return (List<String>) JSON.deserialize(body, List<String>.class);
    }

    public static List<Integer> parseIntegerList(String body) {
        if (String.isBlank(body)) return new List<Integer>();
        return (List<Integer>) JSON.deserialize(body, List<Integer>.class);
    }

    /**
     * Map HN ResponseWrapper to SObject - ensures required Name and ItemType for cache.
     */
    public static HN_DataObject__c toHNDataObject(ResponseWrapper story) {
        if (story == null) return null;
        HN_DataObject__c obj = new HN_DataObject__c();
        obj.Name = String.isNotBlank(story.ItemId) ? 'HN-' + story.ItemId : (String.isNotBlank(story.title) ? story.title.left(80) : 'HN-' + System.now().getTime());
        obj.Username__c = story.postedBy;
        obj.Descendants__c = story.descendants != null ? Integer.valueOf(story.descendants) : 0;
        obj.ItemId__c = story.ItemId != null ? Long.valueOf(story.ItemId) : null;
        obj.Kids__c = story.kids != null ? String.join(story.kids, ',') : null;
        obj.Score__c = story.score != null ? Integer.valueOf(story.score) : 0;
        obj.Time__c = story.UnixTime != null ? Long.valueOf(story.UnixTime) : null;
        obj.Text__c = story.title;
        obj.Url__c = story.url;
        // Required picklist ItemType - default to story if blank or invalid
        String t = String.isNotBlank(story.Itemtype) ? story.Itemtype.toLowerCase() : 'story';
        Set<String> allowed = new Set<String>{'story','job','comment','poll','pollopt'};
        obj.ItemType__c = allowed.contains(t) ? t : 'story';
        return obj;
    }

    /**
     * Reverse: HN_DataObject__c to ResponseWrapper for cache reads.
     */
    public static ResponseWrapper fromHNDataObject(HN_DataObject__c obj) {
        if (obj == null) return null;
        ResponseWrapper rw = new ResponseWrapper();
        rw.postedBy = obj.Username__c;
        rw.descendants = obj.Descendants__c != null ? String.valueOf(obj.Descendants__c) : null;
        rw.ItemId = obj.ItemId__c != null ? String.valueOf(obj.ItemId__c) : null;
        rw.kids = String.isNotBlank(obj.Kids__c) ? obj.Kids__c.split(',') : new List<String>();
        // Clean empty kids
        List<String> cleanKids = new List<String>();
        for (String k : rw.kids) if (String.isNotBlank(k)) cleanKids.add(k.trim());
        rw.kids = cleanKids;
        rw.score = obj.Score__c != null ? String.valueOf(obj.Score__c) : null;
        rw.UnixTime = obj.Time__c != null ? String.valueOf(obj.Time__c) : null;
        rw.title = obj.Text__c;
        rw.Itemtype = obj.ItemType__c;
        rw.url = obj.Url__c;
        return rw;
    }

    /**
     * Deserialize HN item JSON directly to ResponseWrapper with sanitization.
     */
    public static ResponseWrapper deserializeHNItem(String jsonBody) {
        String sanitized = sanitizeHNJson(jsonBody);
        return (ResponseWrapper) JSON.deserialize(sanitized, ResponseWrapper.class);
    }

    /**
     * Validate success and return body, else throw AuraHandledException for LWC.
     */
    public static String ensureSuccessBody(P2P_HttpResponseWrapper wrap) {
        if (wrap == null) throw new P2P_ResponseException('Null response wrapper');
        if (!wrap.isSuccess) {
            throw new AuraHandledException(wrap.errorMessage);
        }
        return wrap.body;
    }
}
