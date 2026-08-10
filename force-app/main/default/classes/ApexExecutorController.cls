public with sharing class ApexExecutorController {
    
    @AuraEnabled
    public static String executeSnippet(String apexCode) {
        String baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
        String endpoint = baseUrl + '/services/data/v60.0/tooling/executeAnonymous/?anonymousBody=' + EncodingUtil.urlEncode(apexCode, 'UTF-8');
        
        P2P_HttpRequestWrapper w = P2P_HttpRequestWrapper.forGet(endpoint);
        w.withHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        w.withHeader('Content-Type', 'application/json');
        P2P_HttpResponseWrapper res = P2P_CalloutService.execute(w);
        if (!Test.isRunningTest()) { try { IntegrationMessageService.flushBuffer(); } catch(Exception e) {} }
        
        if (res.statusCode == 200) {
            return res.body;
        } else {
            throw new AuraHandledException('Execution Error: ' + res.body);
        }
    }
}
