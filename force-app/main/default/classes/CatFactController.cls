public with sharing class CatFactController {

    @AuraEnabled(cacheable=false)
    public static String getCatFact() {

        // Initalining a http request
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        //adding api parameter
        req.setEndpoint('https://catfact.ninja/fact');
        //setting set request
        req.setMethod('GET');
        //getting response
        HttpResponse res = http.send(req);
        // checking 200 response = true
        if (res.getStatusCode() == 200) {
            return res.getBody();
        } else {
            
            throw new AuraHandledException('Failed to fetch cat fact');
        }
    }
}