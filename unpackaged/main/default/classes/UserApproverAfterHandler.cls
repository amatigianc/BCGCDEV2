public with sharing class UserApproverAfterHandler extends DomainLogicHandler {
    List<SObjectField> userFields = new List<SObjectField>{ User.ManagerId };
    List<User> updateUsers = new List<User>();

    Set<Id> managerIds = new Set<Id>();

    public override void check(SObject newObj) {
        if (isQualified((User) newObj)) {
            managerIds.add(newObj.Id);
        }
    }

    public override void check(SObject newObj, SObject oldObj) {
        if (
            isQualified((User) newObj) &&
            TriggerUtility.isChanged(newObj, oldObj, userFields)
        ) {
            managerIds.add(newObj.Id);
        }
    }

    public override void processRecords() {
        List<User> managerUsers = getManagerUsers();

        for (User managerUser : managerUsers) {
            for(User thisUser : managerUser.ManagedUsers) {
                thisUser.Director_Approver__c = managerUser?.ManagerId;
                thisUser.VP_Approver__c = managerUser?.Manager?.ManagerId;
                thisUser.SVP_Approver__c = managerUser?.Manager?.Manager?.ManagerId;
            }
            updateUsers.addAll(managerUser.ManagedUsers);     
        }

        update updateUsers;
    }

    private Boolean isQualified(User thisUser) {
        return thisUser.ManagerId != null;
    }

    private List<User> getManagerUsers() {
        return
            [
                SELECT
                    Id,
                    ManagerId,
                    Manager.ManagerId,
                    Manager.Manager.ManagerId,
                    (
                        SELECT
                            Id,
                            ManagerId,
                            Manager.ManagerId,
                            Manager.Manager.ManagerId
                        FROM ManagedUsers
                    )
                FROM User
                WHERE Id IN :managerIds
            ];
    }
}