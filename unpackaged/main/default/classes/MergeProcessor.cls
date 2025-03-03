public with sharing class MergeProcessor {
    private static List<String> fields = new List<String>();

    public static Boolean processMerge(
        SObject primary,
        List<SObject> secondaries
    ) {
        try {
            List<Database.MergeResult> results = Database.merge(
                primary,
                secondaries,
                false
            );
            for (Database.MergeResult result : results) {
                if (!result.isSuccess()) {
                    List<Database.Error> errors = result.getErrors();
                    List<String> errorMessages = new List<String>();
                    for (Database.Error error : errors) {
                        errorMessages.add(error.getMessage());
                    }
                    throw new MergeException(
                        'Errors = ' + String.join(errorMessages, ',\n')
                    );
                }
            }
        } catch (Exception e) {
            System.debug('Exception = ' + e.getMessage());
            System.debug('Stack = ' + e.getStackTraceString());
            return false;
        }

        return true;
    }

    public static List<String> getQueryFields(SObjectType sobjType) {
        if (fields.isEmpty()) {
            Map<String, SObjectField> sobjFields = sobjType.getDescribe()
                .fields.getMap();
            for (String field : sobjFields.keySet()) {
                if (isFieldMergeable(sobjFields.get(field))) {
                    fields.add(field);
                }
            }
        }
        return fields;
    }

    public static String getSelectStarQuery(SObjectType sobjType) {
        String query = 'SELECT Id, ';

        List<String> fields = getQueryFields(sobjType);

        query +=
            String.join(fields, ', ') +
            ' FROM ' +
            sobjType.getDescribe().getName();

        return query;
    }

    private static Boolean isFieldMergeable(SObjectField field) {
        return field.getDescribe().isCreateable() &&
            !field.getDescribe().isDeprecatedAndHidden() &&
            ((field.getDescribe().isCustom() &&
            !field.getDescribe().isCalculated()) ||
            (!field.getDescribe().isCustom() &&
            !field.getDescribe().isDefaultedOnCreate() &&
            field.getDescribe().isUpdateable()));
    }

    class MergeException extends Exception {
    }
}