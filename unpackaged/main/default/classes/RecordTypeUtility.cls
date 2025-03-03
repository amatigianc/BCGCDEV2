public with sharing class RecordTypeUtility {
    private static Map<Id, RecordTypeInfo> recordTypeInfosById = new Map<Id, RecordTypeInfo>();
    private static Map<SObjectType, Map<String, RecordTypeInfo>> recordTypeInfosByName = new Map<SObjectType, Map<String, RecordTypeInfo>>();

    public static String getName(SObject sobj) {
        setRecordTypeInfos(getSObjectType(sobj));
        return recordTypeInfosById.get((Id) sobj.get('RecordTypeId')).getName();
    }

    public static Id getId(SObjectType sobjectType, String recordTypeName) {
        setRecordTypeInfos(sobjectType);
        return recordTypeInfosByName.get(sobjectType)
            .get(recordTypeName)
            .getRecordTypeId();
    }

    private static void setRecordTypeInfos(SObjectType sobjectType) {
        if (!recordTypeInfosByName.containsKey(sobjectType)) {
            DescribeSobjectResult describeResult = sobjectType.getDescribe(
                SObjectDescribeOptions.DEFERRED
            );
            recordTypeInfosById.putAll(describeResult.getRecordTypeInfosById());
            recordTypeInfosByName.put(
                sobjectType,
                describeResult.getRecordTypeInfosByName()
            );
        }
    }

    private static SObjectType getSObjectType(SObject sobj) {
        return sobj.getSObjectType();
    }
}