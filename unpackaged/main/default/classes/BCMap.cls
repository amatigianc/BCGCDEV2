public with sharing class BCMap {
    private Map<String, SObject> sobjectMap = new Map<String, SObject>();
    private Map<String, List<SObject>> sobjectsMap = new Map<String, List<SObject>>();
    private List<String> keyFields;

    public BCMap(List<String> keyFields) {
        this.keyFields = keyFields;
    }

    public BCMap(String keyField) {
        this.keyFields = new List<String>{ keyField };
    }

    public BCMap(List<SObject> sobjects, List<String> keyFields) {
        this.keyFields = keyFields;

        put(sobjects);
    }

    public BCMap(List<SObject> sobjects, String keyField) {
        this.keyFields = new List<String>{ keyField };

        put(sobjects);
    }

    public Boolean containsKey(String key) {
        return sobjectMap.containsKey(key) || sobjectsMap.containsKey(key);
    }

    public SObject get(String key) {
        return sobjectMap.get(key);
    }

    public List<SObject> getAll(String key) {
        return sobjectsMap.get(key);
    }

    public String getKey(SObject sobj) {
        List<String> keyValues = new List<String>();
        for (String keyField : keyFields) {
            keyValues.add(String.valueOf(sobj.get(keyField)));
        }

        return String.join(keyValues, '');
    }

    public Boolean isAllEmpty() {
        return sobjectsMap.isEmpty();
    }

    public Boolean isEmpty() {
        return sobjectMap.isEmpty();
    }

    public Boolean isNotAllEmpty() {
        return !isAllEmpty();
    }

    public Boolean isNotEmpty() {
        return !isEmpty();
    }

    public Set<String> keySet() {
        return sobjectMap.keySet();
    }

    public Set<String> keyAllSet() {
        return sobjectsMap.keySet();
    }

    public List<SObject> values() {
        return sobjectMap.values();
    }

    public List<SObject> valuesAll() {
        List<SObject> valuesList = new List<SObject>();
        for (List<SObject> sobjects : sobjectsMap.values()) {
            valuesList.addAll(sobjects);
        }
        return valuesList;
    }

    public void put(List<SObject> sobjects) {
        for (SObject sobj : sobjects) {
            put(sobj);
        }
    }

    public void put(SObject sobj) {
        String key = getKey(sobj);
        sobjectMap.put(key, sobj);
        putAll(new List<SObject>{ sobj });
    }

    public void putAll(List<SObject> sobjects) {
        for (SObject sobj : sobjects) {
            String key = getKey(sobj);
            if (!sobjectsMap.containsKey(key)) {
                sobjectsMap.put(key, new List<SObject>());
            }

            sobjectsMap.get(key).add(sobj);
        }
    }

    public SObject remove(String key) {
        return sobjectMap.remove(key);
    }

    public List<SObject> removeAll(String key) {
        return sobjectsMap.remove(key);
    }
}