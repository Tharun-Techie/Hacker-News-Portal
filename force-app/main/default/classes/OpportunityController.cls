public with sharing class OpportunityController {

    @AuraEnabled
    public static Id createOpportunity(
        String oppName,
        Date closeDate,
        String stageName,
        Decimal amount
    ) {
        Opportunity opp = new Opportunity(
            Name = oppName,
            CloseDate = closeDate,
            StageName = stageName,
            Amount = amount
        );
        insert opp;
        return opp.Id;
    }

    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getCarBookingOpportunities() {
        return [
            SELECT Id, Name, StageName, Amount, CloseDate
            FROM Opportunity
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
    }
}