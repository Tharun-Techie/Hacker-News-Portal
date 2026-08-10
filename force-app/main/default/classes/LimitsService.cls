public class LimitsService {

    public static LimitsWrapper getLimits() {

        Http http = new Http();
        HttpRequest req = new HttpRequest();

        // ✅ Endpoint (use your org URL)
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String endpoint = baseUrl + '/services/data/v65.0/limits';

        req.setEndpoint(endpoint);
        req.setMethod('GET');

        // ✅ Session authentication
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');

        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {

            String jsonString = res.getBody();
            System.debug('Response: ' + jsonString);

            // ✅ Parse into wrapper
            LimitsWrapper wrapper = LimitsWrapper.parse(jsonString);

            return wrapper;

        } else {
            System.debug('Error: ' + res.getStatus() + ' Body: ' + res.getBody());
            return null;
        }
    }
}