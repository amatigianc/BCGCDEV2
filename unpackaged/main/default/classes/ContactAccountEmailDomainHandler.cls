public with sharing class ContactAccountEmailDomainHandler extends DomainLogicHandler {
    private Map<Id, Contact> accountIdContactMap = new Map<Id, Contact>();

    public override void check(SObject newObj) {
        Contact newContact = (Contact) newObj;
        accountIdContactMap.put(newContact.AccountId, newContact);
    }

    public override void processRecords() {
        List<Account> accounts = [
            SELECT Id, Email_Domain_Name__c
            FROM Account
            WHERE
                Email_Domain_Name__c = NULL
                AND Id IN :accountIdContactMap.keySet()
        ];

        for (Account account : accounts) {
            account.Email_Domain_Name__c = accountIdContactMap.get(account.Id)
                .Email_Address_Domain__c;
        }
        
        update accounts;
    }
}