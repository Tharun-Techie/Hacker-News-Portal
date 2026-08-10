public with sharing class IntegrationMessageFlushQueueable implements Queueable {
    private List<Integration_Message__c> messages;
    public IntegrationMessageFlushQueueable(List<Integration_Message__c> msgs) {
        this.messages = msgs != null ? msgs : new List<Integration_Message__c>();
    }
    public void execute(QueueableContext ctx) {
        if (messages.isEmpty()) return;
        // Deduplicate: if a message with same Reference_Id + Operation + Response_Body already exists (from sync flush), skip
        // Query existing recent messages (last 5 mins) to avoid duplicates from dual flush (sync + async)
        try {
            Set<String> refIds = new Set<String>();
            Set<String> ops = new Set<String>();
            for (Integration_Message__c m : messages) {
                if (String.isNotBlank(m.Reference_Id__c)) refIds.add(m.Reference_Id__c);
                if (String.isNotBlank(m.Operation__c)) ops.add(m.Operation__c);
            }
            Map<String, Integration_Message__c> existingByKey = new Map<String, Integration_Message__c>();
            if (!refIds.isEmpty() || !ops.isEmpty()) {
                List<Integration_Message__c> existing = [
                    SELECT Id, Reference_Id__c, Operation__c, Response_Body__c, CreatedDate
                    FROM Integration_Message__c
                    WHERE CreatedDate = LAST_N_DAYS:1
                    AND (Reference_Id__c IN :refIds OR Operation__c IN :ops)
                    ORDER BY CreatedDate DESC LIMIT 200
                ];
                for (Integration_Message__c e : existing) {
                    String key = (e.Reference_Id__c != null ? e.Reference_Id__c : '') + '|' + (e.Operation__c != null ? e.Operation__c : '') + '|' + (e.Response_Body__c != null ? String.valueOf(e.Response_Body__c.hashCode()) : '');
                    existingByKey.put(key, e);
                }
            }
            List<Integration_Message__c> toInsert = new List<Integration_Message__c>();
            for (Integration_Message__c m : messages) {
                String key = (m.Reference_Id__c != null ? m.Reference_Id__c : '') + '|' + (m.Operation__c != null ? m.Operation__c : '') + '|' + (m.Response_Body__c != null ? String.valueOf(m.Response_Body__c.hashCode()) : '');
                if (!existingByKey.containsKey(key)) {
                    toInsert.add(m);
                } else {
                    // Also check exact body equality to avoid hash collision false positive
                    Integration_Message__c ex = existingByKey.get(key);
                    if (ex.Response_Body__c != m.Response_Body__c) {
                        // Different body, treat as new
                        toInsert.add(m);
                    }
                }
            }
            if (!toInsert.isEmpty()) {
                insert toInsert;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'IntegrationMessageFlushQueueable failed: ' + e.getMessage() + ' ' + e.getStackTraceString());
            // Last resort: try insert without dedup
            try { insert messages; } catch (Exception ex) { System.debug(LoggingLevel.ERROR, 'Retry insert failed: '+ex.getMessage()); }
        }
    }
}
