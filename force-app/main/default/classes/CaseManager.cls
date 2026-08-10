@RestResource(urlMapping='/case/*')
global class CaseManager {
    
    @HttpGet
    global static Case getCaseId() {
        RestRequest request = RestContext.request;
        
        String caseId = request.requestURI.substring(
            request.requestURI.lastIndexOf('/') + 1
        );
        
        Case result = [
            SELECT Subject, Status, Origin, Priority
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        
        return result;
    }
    
    
@HttpPost
global static Id createCase() {
    
    RestRequest request = RestContext.request;
    
    Case newCase = (Case) JSON.deserialize(
        request.requestBody.toString(),
        Case.class
    );
    
    insert newCase;
    return newCase.Id;
}

    @HttpDelete
global static void deleteCase() {
    
    RestRequest request = RestContext.request;
    
    String caseId = request.requestURI.substring(
        request.requestURI.lastIndexOf('/') + 1
    );
    
    Case thisCase = [
        SELECT Id 
        FROM Case 
        WHERE Id = :caseId 
        LIMIT 1
    ];
    
    delete thisCase;
}


}