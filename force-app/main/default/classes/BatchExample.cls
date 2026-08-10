global class BatchExample implements Database.Batchable<SObject>{


    global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator('SELECT Id FROM Account');
    }

    global void execute(Database.BatchableContext bc, List<Account> accList){
        for (Account acc : accList) {
            acc.Description = 'Updated by batch';
        }
        update accList;
    }

    global void finish(Database.BatchableContext bs){
            System.debug('Batch completed');
    }

}