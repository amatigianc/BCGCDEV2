// Test coverage for this class is handled in PersistentIdHandlerTest
public with sharing class GuidUtility {
    private static Map<String, Schema.SObjectType> describeMap;

    public static String generateGuid() {
        Blob b = Crypto.generateAESKey(128);
        String h = EncodingUtil.convertTohex(b);
        String guid =
            h.subString(0, 8) +
            '-' +
            h.subString(8, 12) +
            '-' +
            h.subString(12, 16) +
            '-' +
            h.SubString(16, 20) +
            '-' +
            h.substring(20);

        return guid;
    }

    public static Map<String, Id> getGuidMap(List<String> guids) {
        String query = getSoslQuery(guids);
        List<List<SObject>> results = Search.query(query);

        Map<String, Id> guidMap = new Map<String, Id>();
        for (List<SObject> sobjects : results) {
            for (SObject sobj : sobjects) {
                guidMap.put((String) sobj.get('GUID__c'), sobj.Id);
            }
        }

        return guidMap;
    }

    /**
     *
     * We need to get the ids
     * from a bunch of guids like these
     *   so we spam the backslashes
     *   to convert all the dashes
     * 'cause that's how sosl retrieves.
     */
    private static String getSoslQuery(List<String> guids) {
        String guidString = String.join(guids, ' OR ');
        guidString = guidString.replaceAll('-', '\\\\$0');
        return 'FIND {' +
            guidString +
            '} ' +
            'RETURNING ' +
            String.join(getReturningObjects(), ', ');
    }

    private static List<String> getReturningObjects() {
        describeMap = Schema.getGlobalDescribe();
        List<Domain_Handler__mdt> handlers = [
            SELECT SObject_Name__c
            FROM Domain_Handler__mdt
            WHERE Handler_Class__c = 'PersistentIdHandler'
        ];

        List<String> returningObjects = new List<String>();
        for (Domain_Handler__mdt handler : handlers) {
            if (
                !returningObjects.contains(handler.SObject_Name__c) &&
                isSearchable(handler.SObject_Name__c)
            ) {
                returningObjects.add(handler.SObject_Name__c + '(Id, GUID__c)');
            }
        }
        return returningObjects;
    }

    private static Boolean isSearchable(String objectName) {
        return describeMap.get(objectName)
            .getDescribe(SObjectDescribeOptions.DEFERRED)
            .isSearchable();
    }
}