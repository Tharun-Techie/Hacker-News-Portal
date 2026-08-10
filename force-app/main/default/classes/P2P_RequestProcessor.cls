public with sharing class P2P_RequestProcessor {

    public class P2P_RequestException extends Exception {}

    /**
     * Build HttpRequest from wrapper. Handles NamedCredential, queryParams, headers, timeout, method validation.
     */
    public static HttpRequest build(P2P_HttpRequestWrapper wrapper) {
        if (wrapper == null) {
            throw new P2P_RequestException('Request wrapper is null');
        }
        if (String.isBlank(wrapper.endpoint) && String.isBlank(wrapper.namedCredential)) {
            throw new P2P_RequestException('Endpoint or NamedCredential must be provided');
        }

        HttpRequest req = new HttpRequest();
        String finalEndpoint = resolveEndpoint(wrapper);
        req.setEndpoint(finalEndpoint);
        req.setMethod(validateMethod(wrapper.method));

        // Headers
        if (wrapper.headers != null) {
            for (String k : wrapper.headers.keySet()) {
                if (String.isNotBlank(k)) {
                    req.setHeader(k, wrapper.headers.get(k));
                }
            }
        }
        // Default Content-Type for body if not set
        if (String.isNotBlank(wrapper.body) && !hasHeader(wrapper.headers, 'Content-Type')) {
            req.setHeader('Content-Type', 'application/json');
        }

        if (String.isNotBlank(wrapper.body)) {
            req.setBody(wrapper.body);
            // Also set compressed false to avoid issues with large payloads
            req.setCompressed(false);
        }

        Integer timeout = wrapper.timeoutMs != null ? wrapper.timeoutMs : 10000;
        // Salesforce max 120000
        timeout = Math.max(1, Math.min(timeout, 120000));
        req.setTimeout(timeout);

        return req;
    }

    private static String resolveEndpoint(P2P_HttpRequestWrapper w) {
        String ep = w.endpoint;
        // If namedCredential set, build callout:NC + endpoint
        if (String.isNotBlank(w.namedCredential)) {
            String nc = w.namedCredential.trim();
            // Remove callout: prefix if user already added
            if (nc.toLowerCase().startsWith('callout:')) {
                nc = nc.substringAfter(':');
            }
            String path = ep != null ? ep : '';
            // Ensure path starts with /
            if (!path.startsWith('/')) {
                path = '/' + path;
            }
            ep = 'callout:' + nc + path;
        }
        // Append queryParams if any
        if (w.queryParams != null && !w.queryParams.isEmpty()) {
            List<String> parts = new List<String>();
            for (String k : w.queryParams.keySet()) {
                parts.add(EncodingUtil.urlEncode(k, 'UTF-8') + '=' + EncodingUtil.urlEncode(w.queryParams.get(k), 'UTF-8'));
            }
            String qs = String.join(parts, '&');
            ep += (ep.contains('?') ? '&' : '?') + qs;
        }
        return ep;
    }

    private static String validateMethod(String method) {
        if (String.isBlank(method)) return 'GET';
        String m = method.toUpperCase().trim();
        Set<String> allowed = new Set<String>{'GET','POST','PUT','PATCH','DELETE','HEAD','OPTIONS'};
        if (!allowed.contains(m)) {
            throw new P2P_RequestException('Invalid HTTP method: ' + method);
        }
        return m;
    }

    private static Boolean hasHeader(Map<String,String> headers, String key) {
        if (headers == null || String.isBlank(key)) return false;
        for (String k : headers.keySet()) {
            if (k.equalsIgnoreCase(key)) return true;
        }
        return false;
    }

    // Convenience: build for HN story with sanitization header hint
    public static HttpRequest buildHNItemRequest(String itemId, Boolean useNC) {
        P2P_HttpRequestWrapper w = useNC ? P2P_HttpRequestWrapper.forHNItemViaNC(itemId) : P2P_HttpRequestWrapper.forHNItem(itemId);
        return build(w);
    }
}
