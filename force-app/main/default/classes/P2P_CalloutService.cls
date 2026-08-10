public with sharing class P2P_CalloutService {

    public class P2P_CalloutException extends Exception {}

    /**
     * Core P2P execute: builds request via RequestProcessor, sends, processes via ResponseProcessor.
     * Never throws on HTTP non-2xx; returns wrapper with isSuccess=false. Throws only on callout failure/timeout.
     */
    public static P2P_HttpResponseWrapper execute(P2P_HttpRequestWrapper reqWrapper) {
        HttpRequest req = P2P_RequestProcessor.build(reqWrapper);
        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            P2P_HttpResponseWrapper wrap = P2P_ResponseProcessor.process(res);
            logCallout(req, wrap);
            return wrap;
        } catch (CalloutException ce) {
            System.debug(LoggingLevel.ERROR, 'P2P CalloutException: ' + ce.getMessage());
            P2P_HttpResponseWrapper err = new P2P_HttpResponseWrapper();
            err.isSuccess = false;
            err.statusCode = 0;
            err.status = 'CalloutException';
            err.errorMessage = ce.getMessage();
            // Optional: LogUtility integration
            // System.debug(LogUtility.getCurrentClassName(ce));
            return err;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'P2P Unexpected: ' + e.getMessage() + ' ' + e.getStackTraceString());
            P2P_HttpResponseWrapper err = new P2P_HttpResponseWrapper();
            err.isSuccess = false;
            err.errorMessage = e.getMessage();
            return err;
        }
    }

    /**
     * Execute and throw if not success. Convenient for synchronous LWC Apex where AuraHandledException is expected.
     */
    public static P2P_HttpResponseWrapper executeOrThrow(P2P_HttpRequestWrapper reqWrapper) {
        P2P_HttpResponseWrapper wrap = execute(reqWrapper);
        if (!wrap.isSuccess) {
            throw new P2P_CalloutException(wrap.errorMessage + (String.isNotBlank(wrap.body) ? ' Body:' + wrap.body : ''));
        }
        return wrap;
    }

    /**
     * Execute with simple retry on timeout / 5xx (up to 2 retries).
     */
    public static P2P_HttpResponseWrapper executeWithRetry(P2P_HttpRequestWrapper reqWrapper, Integer maxRetries) {
        Integer retries = maxRetries != null ? Math.min(maxRetries, 3) : 1;
        P2P_HttpResponseWrapper last;
        for (Integer i = 0; i <= retries; i++) {
            last = execute(reqWrapper);
            if (last.isSuccess) return last;
            // Retry only on 0 (callout exception), 408, 429, 5xx
            if (last.statusCode == 0 || last.statusCode == 408 || last.statusCode == 429 || (last.statusCode >= 500 && last.statusCode < 600)) {
                if (i < retries) {
                    System.debug('P2P retry ' + (i+1) + ' for ' + reqWrapper.endpoint + ' status:' + last.statusCode);
                    continue;
                }
            }
            break;
        }
        return last;
    }

    // ---- Convenience typed methods for News Portal (HN) ----

    public static P2P_HttpResponseWrapper getHNItem(String itemId, Boolean useNamedCredential) {
        P2P_HttpRequestWrapper w = useNamedCredential ? P2P_HttpRequestWrapper.forHNItemViaNC(itemId) : P2P_HttpRequestWrapper.forHNItem(itemId);
        return execute(w);
    }

    public static ResponseWrapper getHNItemAsWrapper(String itemId, Boolean useNC) {
        P2P_HttpResponseWrapper res = getHNItem(itemId, useNC);
        if (!res.isSuccess) throw new AuraHandledException(res.errorMessage);
        return P2P_ResponseProcessor.deserializeHNItem(res.body);
    }

    public static List<String> getHNTopStoryIds(Boolean useNC) {
        P2P_HttpRequestWrapper w = P2P_HttpRequestWrapper.forHNTopStories();
        if (useNC) w.withNamedCredential('HN_API');
        P2P_HttpResponseWrapper res = executeOrThrow(w);
        return res.getBodyAsStringList();
    }

    public static List<String> getHNBestStoryIds(Boolean useNC) {
        P2P_HttpRequestWrapper w = P2P_HttpRequestWrapper.forHNBestStories();
        if (useNC) w.withNamedCredential('HN_API');
        P2P_HttpResponseWrapper res = executeOrThrow(w);
        return res.getBodyAsStringList();
    }

    public static List<String> getHNNewStoryIds(Boolean useNC) {
        P2P_HttpRequestWrapper w = P2P_HttpRequestWrapper.forHNNewStories();
        if (useNC) w.withNamedCredential('HN_API');
        P2P_HttpResponseWrapper res = executeOrThrow(w);
        return res.getBodyAsStringList();
    }

    // Generic GET helper
    public static P2P_HttpResponseWrapper doGet(String endpoint) {
        return execute(P2P_HttpRequestWrapper.forGet(endpoint));
    }

    public static P2P_HttpResponseWrapper doGetViaNC(String namedCredential, String path) {
        P2P_HttpRequestWrapper w = P2P_HttpRequestWrapper.forGet(path);
        w.withNamedCredential(namedCredential);
        return execute(w);
    }

    private static void logCallout(HttpRequest req, P2P_HttpResponseWrapper res) {
        // Lightweight debug; replace with LogUtility / Platform Event if needed
        System.debug(LoggingLevel.DEBUG, 'P2P callout ' + req.getMethod() + ' ' + req.getEndpoint() + ' => ' + res.statusCode + ' success:' + res.isSuccess);
        if (!res.isSuccess) {
            System.debug(LoggingLevel.WARN, 'P2P error body: ' + res.body);
        }
    }
}
