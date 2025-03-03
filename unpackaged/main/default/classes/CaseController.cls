public class CaseController {

    @AuraEnabled(cacheable=true)
    public static Case getCaseDetails(String caseID) {
        return [SELECT Request_closure__c, Priority FROM Case where ID = :caseID];
    }

    @AuraEnabled
    public static void requestClosure(String caseID) {
        Case updateCase = new Case(id = caseID, Request_closure__c = true);
        update updateCase;
    }

    @AuraEnabled
    public static void updatePriority(String caseID, String priority) {
        Case updateCase = new Case(id = caseID, Priority = priority);
        update updateCase;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean componentAvailable(String userId){
        Set<String> prfN = new set<String>();

        prfN.Add('Portal User (Gold-Self Reg)');
        prfN.Add('Portal User (Platinum-Self Reg)');
        prfN.Add('Portal User (Self-Reg)');
        prfN.Add('Portal User (Silver-Self Reg)');
        prfN.Add('Portal User-SelfReg-Gold Support); Plus for Japan');

        String profCurrenUser = [Select Profile.Name from User where id=:userId].Profile.Name;

        return !prfN.contains(profCurrenUser);


    }


}