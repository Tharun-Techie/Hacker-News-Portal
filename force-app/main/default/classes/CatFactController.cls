public with sharing class CatFactController {

    @AuraEnabled(cacheable=false)
    public static String getCatFact() {
        P2P_HttpRequestWrapper w = P2P_HttpRequestWrapper.forGet('https://catfact.ninja/fact');
        P2P_HttpResponseWrapper res = P2P_CalloutService.execute(w);
        if (!Test.isRunningTest()) { try { IntegrationMessageService.flushBuffer(); } catch(Exception e) {} }
        if (res.isSuccess) {
            return res.body;
        } else {
            throw new AuraHandledException('Failed to fetch cat fact');
        }
    }
}
