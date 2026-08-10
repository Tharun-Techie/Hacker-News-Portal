public with sharing class ApexExecutorController {
    
    @AuraEnabled
    public static String executeSnippet(String apexCode) {
        String baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
        String endpoint = baseUrl + '/services/data/v60.0/tooling/executeAnonymous/?anonymousBody=' + EncodingUtil.urlEncode(apexCode, 'UTF-8');
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            return res.getBody();
        } else {
            throw new AuraHandledException('Execution Error: ' + res.getBody());
        }
    }
}