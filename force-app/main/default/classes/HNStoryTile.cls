public with sharing class HNStoryTile {
    @AuraEnabled public String itemId;
    @AuraEnabled public String title;
    @AuraEnabled public String url;
    @AuraEnabled public String score;
    @AuraEnabled public String postedBy;
    @AuraEnabled public String unixTime;
    @AuraEnabled public String formattedTime;
    @AuraEnabled public String itemType;
    @AuraEnabled public String descendants;
    @AuraEnabled public List<String> kids;
    @AuraEnabled public Integer kidsCount;
    @AuraEnabled public Boolean hasUrl;
}
