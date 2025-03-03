public with sharing class UserApproverBeforeHandler extends DomainLogicHandler {
    List<SObjectField> userFields = new List<SObjectField>{
        User.ManagerId
    };

    List<User> workSet = new List<User>();

    public override void check(SObject newObj) {
        if (isQualified((User) newObj)) {
            workSet.add((User) newObj);
        }
    }

    public override void check(SObject newObj, SObject oldObj) {
        if (TriggerUtility.isChanged(newObj, oldObj, userFields)) {
            workSet.add((User) newObj);
        }
    }

    public override void processRecords() {
        Map<Id, User> managerUsers = getManagerUsers();

        for (User thisUser : workSet) {
            User managerUser = managerUsers.get(thisUser.ManagerId);
            thisUser.Director_Approver__c = managerUser?.ManagerId;
            thisUser.VP_Approver__c = managerUser?.Manager?.ManagerId;
            thisUser.SVP_Approver__c = managerUser?.Manager?.Manager?.ManagerId;
        }
    }

    private Boolean isQualified(User newObj) {
        return newObj.ManagerId != null;
    }

    private Set<Id> getManagerIds() {
        Set<Id> results = new Set<Id>();
        for (User thisUser : workSet) {
            results.add(thisUser.ManagerId);
        }
        return results;
    }

    private Map<Id, User> getManagerUsers() {
        Set<Id> managerIds = getManagerIds();
        return new Map<Id, User>(
            [
                SELECT
                    Id,
                    ManagerId,
                    Manager.ManagerId,
                    Manager.Manager.ManagerId
                FROM User
                WHERE Id IN :managerIds
            ]
        );
    }
}