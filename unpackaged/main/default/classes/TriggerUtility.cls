public with sharing class TriggerUtility {
    public static Boolean isChanged(
        SObject newObj,
        SObject oldObj,
        SObjectField field
    ) {
        return isChanged(newObj, oldObj, new List<SObjectField>{ field });
    }

    public static Boolean isChanged(
        SObject newObj,
        SObject oldObj,
        String field
    ) {
        return newObj.get(field) != oldObj.get(field);
    }

    public static Boolean isChanged(
        SObject newObj,
        SObject oldObj,
        List<SObjectField> fields
    ) {
        for (SObjectField field : fields) {
            if (newObj.get(field) != oldObj.get(field)) {
                return true;
            }
        }

        return false;
    }

    public static Boolean isChanged(
        SObject newObj,
        SObject oldObj,
        Set<SObjectField> fields
    ) {
        return isChanged(newObj, oldObj, new List<SObjectField>(fields));
    }

    public static List<SObjectField> getChangedFields(
        SObject newObj,
        SObject oldObj,
        List<SObjectField> fields
    ) {
        List<SObjectField> changedFields = new List<SObjectField>();
        for (SObjectField field : fields) {
            if (newObj.get(field) != oldObj.get(field)) {
                changedFields.add(field);
            }
        }
        return changedFields;
    }

    public static Set<SObjectField> getChangedFields(
        SObject newObj,
        SObject oldObj,
        Set<SObjectField> fields
    ) {
        return new Set<SObjectField>(
            getChangedFields(newObj, oldObj, new List<SObjectField>(fields))
        );
    }

    public static Boolean hasValues(SObject sobj, List<SObjectField> fields) {
        for (SObjectField field : fields) {
            if (sobj.get(field) == null) {
                return false;
            }
        }

        return true;
    }
}