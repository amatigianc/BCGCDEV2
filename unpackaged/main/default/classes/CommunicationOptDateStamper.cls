public with sharing class CommunicationOptDateStamper extends DomainLogicHandler {
    Map<String, String> fieldMap = new Map<String, String>{
        'Communication_Opt_In__c' => 'Communication_Opt_In_Date__c',
        'Communication_Opt_Out__c' => 'Communication_Opt_Out_Date__c',
        'Phone_Opt_In__c' => 'Phone_Opt_In_Date__c',
        'Phone_Opt_Out__c' => 'Phone_Opt_Out_Date__c'
    };

    public override void check(SObject newObj) {
        for (String optField : fieldMap.keySet()) {
            String dateField = fieldMap.get(optField);
            if (isQualified(newObj, optField)) {
                newObj.put(dateField, Date.today());
            }
        }
    }

    public override void check(SObject newObj, SObject oldObj) {
        for (String optField : fieldMap.keySet()) {
            if (isQualified(newObj, oldObj, optField)) {
                String dateField = fieldMap.get(optField);
                Object dateValue = (Boolean) newObj.get(optField)
                    ? Date.today()
                    : null;
                newObj.put(dateField, dateValue);
            }
        }
    }

    Boolean isQualified(SObject newObj, String field) {
        return (Boolean) newObj.get(field);
    }

    Boolean isQualified(SObject newObj, SObject oldObj, String field) {
        Schema.SObjectType objectType = newObj.getSObjectType();
        Map<String, SObjectField> fieldMap = objectType.getDescribe()
            .fields.getMap();
        Schema.SobjectField optField = fieldMap.get(field);
        return TriggerUtility.isChanged(newObj, oldObj, optField);
    }
}