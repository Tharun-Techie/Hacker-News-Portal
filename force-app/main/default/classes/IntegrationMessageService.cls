public with sharing class IntegrationMessageService {

    /**
     * Create Integration_Message__c from P2P wrappers without DML. Caller decides insert.
     */
    public static Integration_Message__c buildMessage(P2P_HttpRequestWrapper reqW, P2P_HttpResponseWrapper resW, String integrationName, String operation, String referenceId) {
        Integration_Message__c msg = new Integration_Message__c();
        // Request minimum fields - ensure every hit stamps request data
        if (reqW != null) {
            // Resolve final endpoint like P2P_RequestProcessor does (named cred + query params)
            String ep = reqW.endpoint;
            if (String.isNotBlank(reqW.namedCredential)) {
                String nc = reqW.namedCredential.trim();
                if (nc.toLowerCase().startsWith('callout:')) nc = nc.substringAfter(':');
                String path = ep != null ? ep : '';
                if (!path.startsWith('/')) path = '/' + path;
                ep = 'callout:' + nc + path;
            }
            // Append queryParams for audit if any
            if (reqW.queryParams != null && !reqW.queryParams.isEmpty()) {
                List<String> parts = new List<String>();
                for (String k : reqW.queryParams.keySet()) {
                    parts.add(k + '=' + reqW.queryParams.get(k));
                }
                String qs = String.join(parts, '&');
                ep = ep + (ep.contains('?') ? '&' : '?') + qs;
            }
            if (String.isNotBlank(ep) && ep.length() > 255) ep = ep.substring(0,255);
            msg.Endpoint__c = ep;
            String m = reqW.method;
            if (String.isNotBlank(m) && m.length() > 20) m = m.substring(0,20);
            msg.Http_Method__c = String.isNotBlank(m) ? m : 'GET';
            String reqBody = reqW.body;
            if (String.isNotBlank(reqBody) && reqBody.length() > 131072) reqBody = reqBody.substring(0,131072);
            msg.Request_Body__c = reqBody;
            String nc = reqW.namedCredential;
            if (String.isNotBlank(nc) && nc.length() > 100) nc = nc.substring(0,100);
            msg.Named_Credential__c = nc;
            // Always stamp headers - even if empty, store {} so audit shows it was captured
            // Merge wrapper headers + auto Content-Type that P2P_RequestProcessor would add
            Map<String,String> hdrMap = reqW.headers != null ? new Map<String,String>(reqW.headers) : new Map<String,String>();
            if (String.isNotBlank(reqW.body) && !hasHeader(hdrMap, 'Content-Type')) {
                hdrMap.put('Content-Type', 'application/json');
            }
            try {
                String hdr = JSON.serialize(hdrMap);
                if (String.isBlank(hdr)) hdr = '{}';
                if (hdr.length() > 32768) hdr = hdr.substring(0,32768);
                msg.Request_Headers__c = hdr;
            } catch(Exception e) {
                String hdr = String.valueOf(hdrMap);
                if (String.isBlank(hdr)) hdr = '{}';
                if (hdr.length() > 32768) hdr = hdr.substring(0,32768);
                msg.Request_Headers__c = hdr;
            }
        }
        // Response minimum fields - always entered
        if (resW != null) {
            String respBody = resW.body;
            if (String.isNotBlank(respBody) && respBody.length() > 131072) respBody = respBody.substring(0,131072);
            msg.Response_Body__c = respBody;
            msg.Status_Code__c = resW.statusCode;
            String st = resW.status;
            if (String.isNotBlank(st) && st.length() > 255) st = st.substring(0,255);
            msg.Status__c = st;
            Boolean success = resW.isSuccess != null ? resW.isSuccess : false;
            msg.Is_Success__c = success;
            String err = resW.errorMessage;
            if (String.isNotBlank(err) && err.length() > 32768) err = err.substring(0,32768);
            msg.Error_Message__c = err;
            // Failure_Reason stamped if any failure (non-2xx or isSuccess false)
            if (!success) {
                String failure = err;
                if (String.isBlank(failure)) {
                    failure = (resW.status != null ? resW.status : 'Unknown') + ' (' + String.valueOf(resW.statusCode) + ')';
                    if (String.isNotBlank(resW.body)) {
                        String snippet = resW.body.length() > 1000 ? resW.body.substring(0,1000) : resW.body;
                        failure += ' Body:' + snippet;
                    }
                }
                if (String.isNotBlank(failure) && failure.length() > 32768) failure = failure.substring(0,32768);
                msg.Failure_Reason__c = failure;
            } else {
                msg.Failure_Reason__c = null;
            }
        } else {
            // No response wrapper - treat as failure
            msg.Is_Success__c = false;
            msg.Failure_Reason__c = 'No response wrapper - callout failed';
            if (msg.Status_Code__c == null) msg.Status_Code__c = 0;
        }
        // Ensure integration/operation/reference are truncated
        String intName = integrationName;
        if (String.isNotBlank(intName) && intName.length() > 100) intName = intName.substring(0,100);
        msg.Integration_Name__c = intName;
        String op = operation;
        if (String.isNotBlank(op) && op.length() > 100) op = op.substring(0,100);
        msg.Operation__c = op;
        String ref = referenceId;
        if (String.isNotBlank(ref) && ref.length() > 100) ref = ref.substring(0,100);
        msg.Reference_Id__c = ref;
        // Ensure Is_Success defaults
        if (msg.Is_Success__c == null) msg.Is_Success__c = false;
        // Ensure Failure_Reason is null on success (already)
        if (msg.Is_Success__c && String.isNotBlank(msg.Failure_Reason__c)) msg.Failure_Reason__c = null;
        return msg;
    }

    private static Boolean hasHeader(Map<String,String> headers, String key) {
        if (headers == null || String.isBlank(key)) return false;
        for (String k : headers.keySet()) {
            if (k.equalsIgnoreCase(key)) return true;
        }
        return false;
    }

    // Buffer to avoid "uncommitted work pending" when multiple callouts in same transaction (e.g., BestStories tiles loop)
    private static List<Integration_Message__c> pendingBuffer = new List<Integration_Message__c>();

    /**
     * Persist message. Buffered to avoid "uncommitted work pending" when multiple callouts
     * run in same transaction (BestStories tiles loop = 1 + N callouts). Caller must invoke flushBuffer()/flushBufferAsync() after burst, or use auto via P2P_CalloutService.
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
            // If flush failed due to uncommitted work pending, keep buffered for async retry
            if (e.getMessage() != null && e.getMessage().contains('uncommitted work pending')) {
                pendingBuffer.addAll(toInsert);
            }
            return 0;
        }
    }

    /**
     * Async flush: enqueues a Queueable to insert buffered messages in a separate transaction.
     * Safe to call after all callouts; avoids extra DML if caller already did sync flush.
     */
    public static void flushBufferAsync() {
        if (pendingBuffer.isEmpty()) return;
        List<Integration_Message__c> toInsert = new List<Integration_Message__c>(pendingBuffer);
        pendingBuffer.clear();
        try {
            System.enqueueJob(new IntegrationMessageFlushQueueable(toInsert));
        } catch(Exception e) {
            System.debug(LoggingLevel.WARN, 'flushBufferAsync enqueue failed: ' + e.getMessage() + ' falling back to sync');
            try { insert toInsert; } catch(Exception ie) { System.debug(LoggingLevel.ERROR, 'Fallback insert failed: '+ie.getMessage()); }
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
