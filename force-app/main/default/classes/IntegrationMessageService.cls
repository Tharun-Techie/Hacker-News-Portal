public with sharing class IntegrationMessageService {

    /**
     * Create Integration_Message__c from P2P wrappers without DML. Caller decides insert.
     */
    public static Integration_Message__c buildMessage(P2P_HttpRequestWrapper reqW, P2P_HttpResponseWrapper resW, String integrationName, String operation, String referenceId) {
        Integration_Message__c msg = new Integration_Message__c();
        if (reqW != null) {
            msg.Endpoint__c = reqW.endpoint != null ? (reqW.endpoint.length() > 255 ? reqW.endpoint.substring(0,255) : reqW.endpoint) : null;
            msg.Http_Method__c = reqW.method;
            msg.Request_Body__c = reqW.body;
            msg.Named_Credential__c = reqW.namedCredential;
            if (reqW.headers != null && !reqW.headers.isEmpty()) {
                try { msg.Request_Headers__c = JSON.serialize(reqW.headers); } catch(Exception e) { msg.Request_Headers__c = String.valueOf(reqW.headers); }
            }
            if (reqW.queryParams != null && !reqW.queryParams.isEmpty()) {
                // append query params to endpoint already handled by processor, but store for audit
            }
        }
        if (resW != null) {
            msg.Response_Body__c = resW.body;
            msg.Status_Code__c = resW.statusCode;
            msg.Status__c = resW.status;
            msg.Is_Success__c = resW.isSuccess != null ? resW.isSuccess : false;
            msg.Error_Message__c = resW.errorMessage;
        }
        msg.Integration_Name__c = integrationName;
        msg.Operation__c = operation;
        msg.Reference_Id__c = referenceId;
        return msg;
    }

    // Buffer to avoid "uncommitted work pending" when multiple callouts in same transaction (e.g., BestStories tiles loop)
    private static List<Integration_Message__c> pendingBuffer = new List<Integration_Message__c>();

    /**
     * Persist message. Buffered to avoid "uncommitted work pending" when multiple callouts
     * run in same transaction (BestStories tiles loop = 1 + N callouts). Never does immediate DML.
     * Caller must invoke flushBuffer() after burst, or the record remains buffered until next flush / end of txn.
     * Swallows exceptions to never break callout flow.
     */
    public static Id logMessage(P2P_HttpRequestWrapper reqW, P2P_HttpResponseWrapper resW, String integrationName, String operation, String referenceId) {
        try {
            Integration_Message__c msg = buildMessage(reqW, resW, integrationName, operation, referenceId);
            pendingBuffer.add(msg);
            return null;
        } catch(Exception e) {
            System.debug(LoggingLevel.WARN, 'IntegrationMessageService log failed: ' + e.getMessage() + ' ' + e.getStackTraceString());
            return null;
        }
    }

    /**
     * Flush buffered messages. Call after a burst of callouts (e.g., end of BestStories loop).
     * Safe to call even if nothing buffered.
     */
    public static Integer flushBuffer() {
        if (pendingBuffer.isEmpty()) return 0;
        List<Integration_Message__c> toInsert = new List<Integration_Message__c>(pendingBuffer);
        pendingBuffer.clear();
        try {
            insert toInsert;
            return toInsert.size();
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'IntegrationMessageService flush failed: ' + e.getMessage());
            return 0;
        }
    }

    public static Integer pendingCount() { return pendingBuffer.size(); }

    @TestVisible private static void clearBuffer() { pendingBuffer.clear(); }

    /**
     * Overload for generic P2P callout - derives operation/reference from request if not supplied.
     */
    public static Id log(P2P_HttpRequestWrapper reqW, P2P_HttpResponseWrapper resW) {
        String op = deriveOperation(reqW);
        String refId = deriveReferenceId(reqW);
        String intName = reqW != null && String.isNotBlank(reqW.namedCredential) ? reqW.namedCredential : 'HN_API';
        if (reqW != null && reqW.endpoint != null && reqW.endpoint.contains('hacker-news')) intName = 'HN_API';
        return logMessage(reqW, resW, intName, op, refId);
    }

    private static String deriveOperation(P2P_HttpRequestWrapper w) {
        if (w == null || String.isBlank(w.endpoint)) return 'UNKNOWN';
        String ep = w.endpoint.toLowerCase();
        if (ep.contains('beststories')) return 'getHNBestStoryIds';
        if (ep.contains('topstories')) return 'getHNTopStoryIds';
        if (ep.contains('newstories')) return 'getHNNewStoryIds';
        if (ep.contains('/item/')) return 'getHNItem';
        if (ep.contains('maxitem')) return 'getMaxItem';
        return w.method != null ? w.method + '_' + ep.left(50) : 'UNKNOWN';
    }

    private static String deriveReferenceId(P2P_HttpRequestWrapper w) {
        if (w == null || String.isBlank(w.endpoint)) return null;
        // try to extract /item/<id>.json
        Pattern p = Pattern.compile('/item/(\\d+)');
        Matcher m = p.matcher(w.endpoint);
        if (m.find()) return m.group(1);
        // for list endpoints return null
        return null;
    }

    // ---------- Fetch from store (no callout) ----------

    /**
     * Get latest Integration_Message for a given referenceId + operation, ordered by CreatedDate desc.
     */
    public static Integration_Message__c getLatestByReference(String referenceId, String operation) {
        if (String.isBlank(referenceId)) return null;
        // Check buffered (not yet flushed) first for immediate visibility within same transaction
        for (Integer i = pendingBuffer.size()-1; i >=0; i--) {
            Integration_Message__c b = pendingBuffer[i];
            if (b.Reference_Id__c == referenceId && (String.isBlank(operation) || b.Operation__c == operation)) return b;
        }
        try {
            List<Integration_Message__c> msgs;
            if (String.isBlank(operation)) {
                msgs = [
                    SELECT Id, Endpoint__c, Http_Method__c, Request_Body__c, Request_Headers__c,
                           Response_Body__c, Status_Code__c, Status__c, Is_Success__c, Error_Message__c,
                           Integration_Name__c, Operation__c, Reference_Id__c, Named_Credential__c, CreatedDate
                    FROM Integration_Message__c
                    WHERE Reference_Id__c = :referenceId
                    ORDER BY CreatedDate DESC LIMIT 1
                ];
            } else {
                msgs = [
                    SELECT Id, Endpoint__c, Http_Method__c, Request_Body__c, Request_Headers__c,
                           Response_Body__c, Status_Code__c, Status__c, Is_Success__c, Error_Message__c,
                           Integration_Name__c, Operation__c, Reference_Id__c, Named_Credential__c, CreatedDate
                    FROM Integration_Message__c
                    WHERE Reference_Id__c = :referenceId AND Operation__c = :operation
                    ORDER BY CreatedDate DESC LIMIT 1
                ];
            }
            return msgs.isEmpty() ? null : msgs[0];
        } catch(Exception e) {
            System.debug(LoggingLevel.WARN, 'getLatestByReference failed: ' + e.getMessage());
            return null;
        }
    }

    public static Integration_Message__c getLatestByEndpoint(String endpoint) {
        if (String.isBlank(endpoint)) return null;
        for (Integer i = pendingBuffer.size()-1; i>=0; i--) { Integration_Message__c b=pendingBuffer[i]; if (b.Endpoint__c == endpoint) return b; }
        try {
            List<Integration_Message__c> msgs = [
                SELECT Id, Endpoint__c, Response_Body__c, Reference_Id__c, Operation__c, Is_Success__c, CreatedDate
                FROM Integration_Message__c
                WHERE Endpoint__c = :endpoint
                ORDER BY CreatedDate DESC LIMIT 1
            ];
            return msgs.isEmpty() ? null : msgs[0];
        } catch(Exception e) { return null; }
    }

    public static Integration_Message__c getLatestByOperation(String operation) {
        if (String.isBlank(operation)) return null;
        for (Integer i = pendingBuffer.size()-1; i>=0; i--) { Integration_Message__c b=pendingBuffer[i]; if (b.Operation__c == operation && b.Is_Success__c) return b; }
        try {
            List<Integration_Message__c> msgs = [
                SELECT Id, Endpoint__c, Response_Body__c, Reference_Id__c, Operation__c, Is_Success__c, CreatedDate
                FROM Integration_Message__c
                WHERE Operation__c = :operation AND Is_Success__c = true
                ORDER BY CreatedDate DESC LIMIT 1
            ];
            return msgs.isEmpty() ? null : msgs[0];
        } catch(Exception e) { return null; }
    }

    /**
     * Deserialize latest stored HN item JSON to ResponseWrapper. Returns null if not found.
     */
    public static ResponseWrapper getHNItemFromStore(String itemId) {
        Integration_Message__c msg = getLatestByReference(itemId, 'getHNItem');
        if (msg == null || String.isBlank(msg.Response_Body__c)) return null;
        try {
            return P2P_ResponseProcessor.deserializeHNItem(msg.Response_Body__c);
        } catch(Exception e) {
            System.debug(LoggingLevel.WARN, 'getHNItemFromStore deserialize failed: ' + e.getMessage());
            return null;
        }
    }

    /**
     * Get latest stored list for Best/Top/New stories as List<String> from response body.
     */
    public static List<String> getHNStoryIdsFromStore(String operation) {
        Integration_Message__c msg = getLatestByOperation(operation);
        if (msg == null || String.isBlank(msg.Response_Body__c)) return new List<String>();
        try { return (List<String>) JSON.deserialize(msg.Response_Body__c, List<String>.class); } catch(Exception e) { return new List<String>(); }
    }

    /**
     * Generic fetch: returns response body string from latest message for given reference/operation.
     */
    public static String getResponseBodyFromStore(String referenceId, String operation) {
        Integration_Message__c msg = getLatestByReference(referenceId, operation);
        return msg != null ? msg.Response_Body__c : null;
    }
}
