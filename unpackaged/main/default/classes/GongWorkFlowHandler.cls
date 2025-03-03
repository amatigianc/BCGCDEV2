public with sharing class GongWorkFlowHandler extends DomainLogicHandler {
    List<String> userNames = new List<String>();
    List<SObject> qualifiedObjs = new List<SObject>();

    public override void check(SObject newObj, SObject oldObj) {
        if (isQualified(newObj, oldObj)) {
            userNames.add(
                (String) newObj.get('Gong__Current_Flow_User_Name__c')
            );
            qualifiedObjs.add(newObj);
        }
    }

    public override void processRecords() {
        if (!qualifiedObjs.isEmpty()) {
            BCMap users = new BCMap(
                [
                    SELECT Id, Name
                    FROM User
                    WHERE Name IN :userNames AND UserRole.Name = 'BDR'
                ],
                'Name'
            );

            for (SObject qualifiedObjs : qualifiedObjs) {
                if (
                    users.containsKey(
                        (String) qualifiedObjs.get(
                            'Gong__Current_Flow_User_Name__c'
                        )
                    )
                ) {
                    qualifiedObjs.put(
                        'BDR_Added_to_Gong_Workflow__c',
                        Datetime.now()
                    );
                }
                qualifiedObjs.put('Gong__Current_Flow_User_Name__c', null);
            }
        }
    }

    Boolean isQualified(SObject newObj, SObject oldObj) {
        return newObj.get('Gong__Current_Flow_User_Name__c') !=
            oldObj.get('Gong__Current_Flow_User_Name__c');
    }
}