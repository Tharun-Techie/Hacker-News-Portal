public class LogDowloader {
    @future(callout=true)
    public static void fetchLogBody(String logId){

        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String endpoint = baseUrl + '/services/data/v58.0/tooling/sobjects/ApexLog/' + logId + '/Body';

        P2P_HttpRequestWrapper w = P2P_HttpRequestWrapper.forGet(endpoint);
        w.withHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
        w.withHeader('Content-Type', 'application/json');

        P2P_HttpResponseWrapper res = P2P_CalloutService.execute(w);
        // Future cannot do DML after callout in same transaction if we flush and then do something else? Flush after all callouts
        if (!Test.isRunningTest()) { try { IntegrationMessageService.flushBuffer(); } catch(Exception e) {} }

        if(res.statusCode==200){
            String logBody = res.body;
            System.debug('download log length:' + logBody.length());
        }
        else {
            System.debug('error fetching log:'+res.body);
        }
    }

}
