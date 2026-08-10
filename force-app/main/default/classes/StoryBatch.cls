// Example Batch Execution
public class StoryBatch implements Database.Batchable<String>, Database.AllowsCallouts {
    public List<String> start(Database.BatchableContext bc) {
        return GeneralMethods.getTopStoriesList();
    }
    public void execute(Database.BatchableContext bc, List<String> scope) {
        for(String id : scope) {
            System.debug(GeneralMethods.getResponse(id));
        }
    }
    public void finish(Database.BatchableContext bc) {}
}