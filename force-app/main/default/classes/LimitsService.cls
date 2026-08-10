public class LimitsService {

    public static LimitsWrapper getLimits() {

        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String endpoint = baseUrl + '/services/data/v65.0/limits';

        P2P_HttpRequestWrapper w = P2P_HttpRequestWrapper.forGet(endpoint);
        w.withHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        w.withHeader('Content-Type', 'application/json');

        P2P_HttpResponseWrapper res = P2P_CalloutService.execute(w);
        if (!Test.isRunningTest()) { try { IntegrationMessageService.flushBuffer(); } catch(Exception e) {} }

        if (res.statusCode == 200) {

            String jsonString = res.body;
            System.debug('Response: ' + jsonString);

            LimitsWrapper wrapper = LimitsWrapper.parse(jsonString);

            return wrapper;

        } else {
            System.debug('Error: ' + res.status + ' Body: ' + res.body);
            return null;
        }
    }
}
