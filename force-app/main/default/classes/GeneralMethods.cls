public class GeneralMethods {

    public static String getStoryLink(String itemId) {
        return Global_Constants.HN_API + '/v0/item/' + itemId + '.json?print=pretty';
    }

    public static void insertRecord(String itemId) {
        ResponseWrapper story = (ResponseWrapper)JSON.deserialize(getResponse(itemId), ResponseWrapper.class);
        Database.insert(objectMaper(story),false);
    }

    public static String getResponse(String itemId) {
        P2P_HttpRequestWrapper w = P2P_HttpRequestWrapper.forHNItem(itemId);
        P2P_HttpResponseWrapper res = P2P_CalloutService.execute(w);
        // Persist Integration_Message__c - flush after single callout (safe, no further callout in this method)
        if (!Test.isRunningTest()) { try { IntegrationMessageService.flushBuffer(); } catch(Exception e) {} }
        if (res.isSuccess) {
            return sanityJSON(res.body);
        } else {
            throw new AuraHandledException('Error: ' + res.statusCode + ' ' + res.status);
        }
    }

    public static String getBestStories() {
        P2P_HttpRequestWrapper w = P2P_HttpRequestWrapper.forHNBestStories();
        P2P_HttpResponseWrapper res = P2P_CalloutService.execute(w);
        if (!Test.isRunningTest()) { try { IntegrationMessageService.flushBuffer(); } catch(Exception e) {} }
        if (res.isSuccess) {
            return res.body;
        } else {
            throw new AuraHandledException('Error: ' + res.statusCode + ' ' + res.status);
        }
    }

    public static List < String > getBestStoriesList() {
        P2P_HttpRequestWrapper w = P2P_HttpRequestWrapper.forHNBestStories();
        P2P_HttpResponseWrapper res = P2P_CalloutService.executeOrThrow(w);
        if (!Test.isRunningTest()) { try { IntegrationMessageService.flushBuffer(); } catch(Exception e) {} }
        return getListString(res.body);
    }

    public static String getTopStories() {
        P2P_HttpRequestWrapper w = P2P_HttpRequestWrapper.forHNTopStories();
        P2P_HttpResponseWrapper res = P2P_CalloutService.execute(w);
        if (!Test.isRunningTest()) { try { IntegrationMessageService.flushBuffer(); } catch(Exception e) {} }
        if (res.isSuccess) {
            return res.body;
        } else {
            throw new AuraHandledException('Error: ' + res.statusCode + ' ' + res.status);
        }
    }

    public static List < String > getTopStoriesList() {
        P2P_HttpRequestWrapper w = P2P_HttpRequestWrapper.forHNTopStories();
        P2P_HttpResponseWrapper res = P2P_CalloutService.executeOrThrow(w);
        if (!Test.isRunningTest()) { try { IntegrationMessageService.flushBuffer(); } catch(Exception e) {} }
        return getListString(res.body);
    }

    private static List < Integer > getListInteger(String response) {
        // Convert string to a List of Integers
        return (List < Integer > ) JSON.deserialize(response, List < Integer > .class);
    }

    private static List<String> getListString(String response) {
    // Convert string to a List of String
    return (List<String>) JSON.deserialize(response, List<String>.class);
    }

    private static String sanityJSON(String res){
            if(String.isBlank(res)){
                throw new AuraHandledException('Response is Null or Empty'); 
            }
                // Using quotes + colon ensures we only replace JSON keys
                  return res.replaceAll('(?i)"by"\\s*:', '"postedBy":')
                           .replaceAll('(?i)"id"\\s*:', '"ItemId":')
                           .replaceAll('(?i)"time"\\s*:', '"UnixTime":')
                           .replaceAll('(?i)"type"\\s*:', '"Itemtype":');
    }
	
    Public static HN_DataObject__c objectMaper(ResponseWrapper story){
            HN_DataObject__c obj = new HN_DataObject__c();
            obj.Username__c = story.postedBy;
           
        
            obj.Descendants__c = story.descendants != null ? Integer.valueOf(story.descendants) : 0;
            obj.ItemId__c = story.ItemId != null ? Long.valueOf(story.ItemId) : null;
            
            
            obj.Kids__c = story.kids != null ? String.join(story.kids, ',') : null;
            
            obj.Score__c = story.score != null ? Integer.valueOf(story.score) : 0;
            obj.Time__c =  story.UnixTime != null ? Long.valueOf(story.UnixTime) : null;
            obj.Text__c = story.title;
            obj.Url__c = story.url;
            
            return obj;
    }
    


}
