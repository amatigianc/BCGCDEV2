@isTest(isparallel=true)
public with sharing class ExceptionHandlerTest {
    @isTest
    static void testProcess() {
        DmlException e = new DmlException();
        e.setMessage('ExceptionHandlerTest as message.');

        Test.startTest();
        String expected = e.getMessage();

        ExceptionHandler.process(e, 'ExceptionHandlerTest');

        Test.stopTest();

        List<Log__c> logs = [
            SELECT Id, Text__c, Stack_Trace__c, Severity__c
            FROM Log__c
            WHERE Source__c = 'ExceptionHandlerTest'
        ];
        System.assertEquals(
            1,
            logs.size(),
            'Incorrect number of Log records created.'
        );

        System.assertEquals(
            expected,
            logs[0].Text__c,
            'Log text not correctly set.'
        );
        System.assertEquals(
            e.getStackTraceString(),
            logs[0].Stack_Trace__c,
            'Log Stack Track not correctly set.'
        );
        System.assertEquals(
            'Error',
            logs[0].Severity__c,
            'Log Severity not correctly set.'
        );
    }

    @isTest
    static void testOverloadedProcess() {
        DmlException e = new DmlException();
        e.setMessage('ExceptionHandlerTest as message.');

        Test.startTest();
        ExceptionHandler.process(
            e,
            'ExceptionHandlerTest',
            'With provided text.'
        );
        Test.stopTest();

        List<Log__c> logs = [
            SELECT Id, Text__c, Severity__c, Stack_Trace__c
            FROM Log__c
            WHERE Source__c = 'ExceptionHandlerTest'
        ];
        System.assertEquals(
            1,
            logs.size(),
            'Incorrect number of Log records created.'
        );

        String expected = 'With provided text.';
        System.assertEquals(expected, logs[0].Text__c);
        System.assertEquals(
            'Error',
            logs[0].Severity__c,
            'Severity not correctly set.'
        );
        System.assertEquals(
            e.getStackTraceString(),
            logs[0].Stack_Trace__c,
            'Stack Trace not correctly set.'
        );
    }
}