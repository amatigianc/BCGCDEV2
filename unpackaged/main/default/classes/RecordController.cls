public with sharing class RecordController {
    static Map<String, Schema.SObjectType> describeMap = Schema.getGlobalDescribe();
    public static Boolean showMessage { get; set; }
    public static String redirectMessage { get; set; }

    public static PageReference validateAndRedirect() {
        String guid = System.currentPageReference().getParameters().get('id');
        guid = guid.replaceAll('-', '\\\\-');
        String sosl = 'FIND {' + guid + '} ';

        List<Domain_Handler__mdt> handlers = [
            SELECT SObject_Name__c
            FROM Domain_Handler__mdt
            WHERE Handler_Class__c = 'PersistentIdHandler'
        ];

        List<String> returningObjects = new List<String>();
        for (Domain_Handler__mdt handler : handlers) {
            if (isSearchable(handler.SObject_Name__c)) {
                returningObjects.add(handler.SObject_Name__c);
            }
        }

        sosl += ' RETURNING ' + String.join(returningObjects, ', ');
        List<List<SObject>> resultsList = search.query(sosl);

        for (List<SObject> results : resultsList) {
            if (!results.isEmpty()) {
                PageReference pageRef = new PageReference(
                    URL.getSalesforceBaseURL().toExternalForm() +
                    '/' +
                    results[0].Id
                );
                pageRef.setRedirect(true);
                return pageRef;
            }
        }

        Id recordId = (Id) guid;
        String sobjectName = recordId.getSobjectType().getDescribe().getName();
        String query =
            'SELECT Id FROM ' +
            sobjectName +
            ' WHERE Id = :recordId';

        List<SObject> results = Database.query(
            String.escapeSingleQuotes(query)
        );
        if (!results.isEmpty()) {
            PageReference pageRef = new PageReference(
                URL.getSalesforceBaseURL().toExternalForm() +
                +'/' +
                results[0].Id
            );
            pageRef.setRedirect(true);
            return pageRef;
        }

        showMessage = true;
        redirectMessage = 'The requested record could not be found.';

        return null;
    }

    static Boolean isSearchable(String objectName) {
        return describeMap.get(objectName)
            .getDescribe(SObjectDescribeOptions.DEFERRED)
            .isSearchable();
    }
}