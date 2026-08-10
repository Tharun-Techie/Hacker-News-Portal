public with sharing class P2P_HttpResponseWrapper {
    public Integer statusCode;
    public String status;
    public String body;
    public Map<String, String> headers;
    public Boolean isSuccess;
    public String errorMessage;
    // Raw HttpResponse for advanced use (transient, not serialized)
    public transient HttpResponse rawResponse;

    public P2P_HttpResponseWrapper() {
        this.headers = new Map<String, String>();
        this.isSuccess = false;
    }

    public P2P_HttpResponseWrapper(HttpResponse res) {
        this();
        if (res != null) {
            this.statusCode = res.getStatusCode();
            this.status = res.getStatus();
            this.body = res.getBody();
            this.isSuccess = (statusCode >= 200 && statusCode < 300);
            this.rawResponse = res;
            // Capture headers
            if (res.getHeaderKeys() != null) {
                for (String k : res.getHeaderKeys()) {
                    this.headers.put(k, res.getHeader(k));
                }
            }
            if (!isSuccess) {
                this.errorMessage = 'Error: ' + statusCode + ' ' + status;
            }
        } else {
            this.errorMessage = 'Null HttpResponse';
        }
    }

    // Helpers to deserialize body
    public Object deserializeAs(Type apexType) {
        if (String.isBlank(body) || apexType == null) return null;
        return JSON.deserialize(body, apexType);
    }

    public Object deserializeAsSanitized(Type apexType) {
        if (String.isBlank(body)) return null;
        String sanitized = P2P_ResponseProcessor.sanitizeHNJson(body);
        return JSON.deserialize(sanitized, apexType);
    }

    public List<String> getBodyAsStringList() {
        if (String.isBlank(body)) return new List<String>();
        return (List<String>) JSON.deserialize(body, List<String>.class);
    }

    public List<Integer> getBodyAsIntegerList() {
        if (String.isBlank(body)) return new List<Integer>();
        return (List<Integer>) JSON.deserialize(body, List<Integer>.class);
    }
}
