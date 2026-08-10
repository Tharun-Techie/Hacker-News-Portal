public class LogDowloader {
    @future(callout=true)
    public static void fetchLogBody(String logId){

        //construct tooling api endpoint
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String endpoint = baseUrl + '/services/data/v58.0/tooling/sobjects/ApexLog/' + logId + '/Body';

        //build http request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');

        //send request
        Http http = new Http();
        HttpResponse res = http.send(req);

        if(res.getStatusCode()==200){
            String logBody = res.getBody();
            
            //process log body as needed, e.g., save to a custom object or send via email
            System.debug('download log length:' + logBody.length());

        }

        else {
            System.debug('error fetching log:'+res.getBody());
        }
    }

}