public with sharing class FieldStamperUtility {
    private Map<String, List<FieldStamper>> sobjectStampersMap = new Map<String, List<FieldStamper>>();
    private Map<SObjectField, FieldStamper> qualifyingFieldStampers = new Map<SObjectField, FieldStamper>();
    private Map<String, SObject> guidSObjects = new Map<String, SObject>();

    public FieldStamperUtility(
        Map<SObjectField, FieldStamper> qualifyingFieldStampers
    ) {
        this.qualifyingFieldStampers = qualifyingFieldStampers;
    }

    public Map<SObjectField, FieldStamper> getQualifyingFieldStampers() {
        return qualifyingFieldStampers;
    }

    public void qualifyRecord(SObject newObj) {
        Map<SObjectField, FieldStamper> qualifyingFieldStampers = getQualifyingFieldStampers();

        Set<SObjectField> qualifiedFields = new Set<SObjectField>();
        for(SObjectField field : qualifyingFieldStampers.keySet()) {
            FieldStamper stamper = qualifyingFieldStampers.get(field);
            if(stamper.isQualified(newObj)) {
                qualifiedFields.add(field);
            }
        }
        setFieldStampers(newObj, qualifiedFields);
    }

    public void qualifyRecord(SObject newObj, SObject oldObj) {
        Set<SObjectField> changedFields = TriggerUtility.getChangedFields(
            newObj,
            oldObj,
            getQualifyingFieldStampers().keySet()
        );
        setFieldStampers(newObj, changedFields);
    }

    public void setFieldStampers(SObject sobj, Set<SObjectField> fields) {
        String guid = (String) sobj.get('GUID__c');
        for (SObjectField field : fields) {
            if (sobj.get(field) != null) {
                if (!sobjectStampersMap.containsKey(guid)) {
                    sobjectStampersMap.put(guid, new List<FieldStamper>());
                }
                sobjectStampersMap.get(guid)
                    .add(qualifyingFieldStampers.get(field));
                guidSObjects.put(guid, sobj);
            }
        }
    }

    public void processStampers() {
        for (String guid : sobjectStampersMap.keySet()) {
            SObject sobj = guidSObjects.get(guid);
            for (FieldStamper stamper : sobjectStampersMap.get(guid)) {
                stamper.stamp(sobj);
            }
        }
    }
}