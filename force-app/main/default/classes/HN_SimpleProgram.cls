public with sharing class HN_SimpleProgram {
    public HN_SimpleProgram() {
    }

    @AuraEnabled(cacheable=false)
    public static String getSimpleResponse() {
        P2P_HttpRequestWrapper w = P2P_HttpRequestWrapper.forGet('https://hacker-news.firebaseio.com/v0/item/47440233.json?print=pretty');
        P2P_HttpResponseWrapper res = P2P_CalloutService.execute(w);
        if (!Test.isRunningTest()) { try { IntegrationMessageService.flushBuffer(); } catch(Exception e) {} }
        if (res.isSuccess) {
            return res.body;
        } else {
            throw new AuraHandledException('Error: ' + res.statusCode + ' ' + res.status);
        }
    }

    @AuraEnabled(cacheable=false)
    public static String responseChecker(String itemId){
        try{
            P2P_HttpRequestWrapper w = P2P_HttpRequestWrapper.forGet('/v0/' + itemId + '.json?print=pretty');
            w.withNamedCredential('HN_API');
            P2P_HttpResponseWrapper res = P2P_CalloutService.execute(w);
            if (!Test.isRunningTest()) { try { IntegrationMessageService.flushBuffer(); } catch(Exception e) {} }
            return res.body;
        }
        catch(Exception e){
        }
       return null;
    }



}
