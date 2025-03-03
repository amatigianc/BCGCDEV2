public class PostChatRating {
    
    private final Case [] c;
    public final String dt {get;set;} 
    
    public PostChatRating() {
        String UserId = UserInfo.getUserId();
        system.debug('User ID is'+ UserId);
        String ContactId ='';
        dt = EncodingUtil.urlEncode(DateTime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ssZ'),'UTF-8');
        if(!Test.isRunningTest()){ContactId = [SELECT ContactId FROM User WHERE Id = :UserId].ContactId;
        }else{ContactId = [SELECT id FROM Contact Limit 1].Id;}
            
        c = [SELECT ContactId, Contact.Name, Id, AccountId, Status,  Account.Name, Account_Account_ID__c, OwnerId, Zapier_Case_Owner__c, CaseNumber, CreatedDate, ClosedDate, Account_Tier__c, Support_Package__c, Origin, ContactEmail, Account_Edition__c 
             FROM Case 
             WHERE ContactId = :ContactId AND Origin = 'Live Chat'
             ORDER BY CaseNumber 
             DESC 
             Limit 1];
     if (c.size()!= 0){
        system.debug('Case Info - Origin '+ c[0].Origin + ' Contact Name ' + c[0].Contact.Name + ' CaseNumber ' + c[0].CaseNumber+ ' Status ' + c[0].Status);
        } else {
            
            system.debug('============No Cases were found============');
        }
        
    }
    
    public Case getCase() {
        if (c.size()!= 0){
            return c[0];
            }
        else
            return null;
    }
    
    public String getDateTimeFormat(){ 
        return dt;  
    }
}