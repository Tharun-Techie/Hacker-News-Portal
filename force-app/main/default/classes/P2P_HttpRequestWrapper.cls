public with sharing class P2P_HttpRequestWrapper {
    // HTTP method: GET, POST, PUT, PATCH, DELETE
    public String method;
    // Full endpoint or relative path when using Named Credential
    public String endpoint;
    // Optional Named Credential API name (without callout: prefix). If set, endpoint is appended to callout:NC
    public String namedCredential;
    // Headers to send
    public Map<String, String> headers;
    // Body for POST/PUT/PATCH
    public String body;
    // Timeout in ms (1 to 120000, default 10000)
    public Integer timeoutMs;
    // Query params to append to endpoint
    public Map<String, String> queryParams;
    // Flag to use pretty print for HN API
    public Boolean prettyPrint;

    public P2P_HttpRequestWrapper() {
        this.method = 'GET';
        this.timeoutMs = 10000;
        this.headers = new Map<String, String>();
        this.queryParams = new Map<String, String>();
    }

    public P2P_HttpRequestWrapper(String endpoint, String method) {
        this();
        this.endpoint = endpoint;
        this.method = method != null ? method.toUpperCase() : 'GET';
    }

    // Builder helpers
    public P2P_HttpRequestWrapper withHeader(String key, String value) {
        if (String.isNotBlank(key) && value != null) {
            this.headers.put(key, value);
        }
        return this;
    }

    public P2P_HttpRequestWrapper withQueryParam(String key, String value) {
        if (String.isNotBlank(key) && value != null) {
            this.queryParams.put(key, value);
        }
        return this;
    }

    public P2P_HttpRequestWrapper withNamedCredential(String ncName) {
        this.namedCredential = ncName;
        return this;
    }

    public static P2P_HttpRequestWrapper forGet(String endpoint) {
        return new P2P_HttpRequestWrapper(endpoint, 'GET');
    }

    public static P2P_HttpRequestWrapper forPost(String endpoint, String jsonBody) {
        P2P_HttpRequestWrapper w = new P2P_HttpRequestWrapper(endpoint, 'POST');
        w.body = jsonBody;
        w.withHeader('Content-Type', 'application/json');
        return w;
    }

    // HN specific factory
    public static P2P_HttpRequestWrapper forHNItem(String itemId) {
        String ep = Global_Constants.HN_API + '/v0/item/' + itemId + '.json?print=pretty';
        return forGet(ep);
    }

    public static P2P_HttpRequestWrapper forHNItemViaNC(String itemId) {
        P2P_HttpRequestWrapper w = forGet('/v0/item/' + itemId + '.json?print=pretty');
        w.namedCredential = 'HN_API';
        return w;
    }

    public static P2P_HttpRequestWrapper forHNTopStories() {
        return forGet(Global_Constants.HN_API_TopStories);
    }

    public static P2P_HttpRequestWrapper forHNBestStories() {
        return forGet(Global_Constants.HN_API_BestStories);
    }

    public static P2P_HttpRequestWrapper forHNNewStories() {
        return forGet(Global_Constants.HN_API_NewStories);
    }
}
