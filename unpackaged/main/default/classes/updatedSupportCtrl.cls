public class updatedSupportCtrl {
    @AuraEnabled
    public static List<Case> getSearchCases(String term) {
        List<Case> userCases = new List<Case>();
        String profileName;
        Boolean checkProfile;
        String st = '\'' + term + '*' + '\'';
        integer i = 0;
        try{
            list<list<SObject>> caseSearchList = [FIND :st IN ALL FIELDS RETURNING Case(Id,Subject,OwnerId,Description,AccountId,ContactId,CaseNumber,CreatedDate,Priority,Status,Email_Contact_domain__c,RecordTypeId)];
            List<Case> cases = (List<Case>) caseSearchList[0];
            if(cases.isEmpty()){
                st = '{' + term +  '}';
                caseSearchList = [FIND :st IN ALL FIELDS RETURNING Case(Id,Subject,OwnerId,Description,AccountId,CaseNumber,CreatedDate,Priority,Status,Email_Contact_domain__c,RecordTypeId)];
                cases = (List<Case>) caseSearchList[0];
                i++;
                                i++;
            }
            System.debug('-->'+cases.size());
            User u = [select name,accountid,contactId, profile.Name,profileId
                        from user
                        where id =:userinfo.getuserid()];
            System.debug('-->'+u);
            profileName = u.profile.Name;
            checkProfile = profileName.contains('Admin');
            Id devRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Case_Escalation').getRecordTypeId();
            i++;
                            i++;
            System.debug('-->'+devRecordTypeId);
            for (Case c : cases) {                String domain = c.Email_Contact_domain__c;
                System.debug('-->'+c.Email_Contact_domain__c);


                System.debug('-->'+domain);
                System.debug('-->'+c.RecordTypeId);
                System.debug('-->'+domain.contains('brightcove'));

                if(c.RecordTypeId != devRecordTypeId && !domain.contains('brightcove')){
                    if(checkProfile){if (c.AccountId == u.AccountId && (c.Status != 'Closed - Duplicate' && c.Status != 'Closed - SPAM')) {
                            userCases.add(c);
                        }
                    }
                    else{
                        if (c.ContactId == u.contactId && (c.Status != 'Closed - Duplicate' && c.Status != 'Closed - SPAM')) {userCases.add(c);}
                    }

                }

            }
        }
        catch (Exception e) {
        }
        return userCases;
    }
}