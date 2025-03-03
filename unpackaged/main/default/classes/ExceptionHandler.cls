public with sharing class ExceptionHandler {
    public static void process(Exception e, String source, String text) {
        debugLog(e, source);
        Log__c log = new Log__c(
            Source__c = source,
            Text__c = text,
            Stack_Trace__c = e.getStackTraceString(),
            Severity__c = 'Error'
        );
        if (System.isFuture() || System.isBatch()) {
            insert log;
            return;
        }

        process(JSON.serialize(log));
    }

    public static void process(Exception e, String source) {
        process(e, source, e.getMessage());
    }

    private static void debugLog(Exception e, String source) {
        List<String> message = new List<String>();
        message.add('Exception from ' + source);
        message.add('Message: ' + e.getMessage());
        message.add('Stack: ' + e.getStackTraceString());
    }

    @future
    private static void process(String logJson) {
        Log__c log = (Log__c) JSON.deserialize(logJson, Log__c.class);
        insert log;
    }
}