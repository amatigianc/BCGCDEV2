/**
 * Test coverage for this class is found in BCAccountCustomerAccountLookupTest.
 */
public with sharing class BrightcoveAccountCustomerAccountLookup extends DomainLogicHandler {
    private Map<String, List<Brightcove_Account__c>> bcAccountsByEmailDomain = new Map<String, List<Brightcove_Account__c>>();
    private Map<String, List<Brightcove_Account__c>> bcAccountsByEmail = new Map<String, List<Brightcove_Account__c>>();

    public override void check(SObject newObj) {
        Brightcove_Account__c newBcAccount = (Brightcove_Account__c) newObj;
        qualify(newBcAccount);
    }

    public override void processRecords() {
        matchByEmail();
        matchByDomain();
    }

    void qualify(Brightcove_Account__c newBcAccount) {
        if (isQualified(newBcAccount)) {
            addToDomainsMap(newBcAccount);
            addToEmailsMap(newBcAccount);
        }
    }

    void addToDomainsMap(Brightcove_Account__c newBcAccount) {
        String domain = newBcAccount.Email_Domain__c.toLowerCase();
        if (
            !bcAccountsByEmailDomain.containsKey(domain)
        ) {
            bcAccountsByEmailDomain.put(
                domain,
                new List<Brightcove_Account__c>()
            );
        }
        bcAccountsByEmailDomain.get(domain).add(newBcAccount);
    }

    void addToEmailsMap(Brightcove_Account__c newBcAccount) {
        String email = newBcAccount.Email_Address__c.toLowerCase();
        if (!bcAccountsByEmail.containsKey(email)) {
            bcAccountsByEmail.put(
                email,
                new List<Brightcove_Account__c>()
            );
        }
        bcAccountsByEmail.get(email).add(newBcAccount);
    }

    Boolean isQualified(Brightcove_Account__c newBcAccount) {
        return newBcAccount.Email_Domain__c != null;
    }

    void matchByEmail() {
        List<Contact> matchedContacts = [
            SELECT Id, AccountId, Email
            FROM Contact
            WHERE Email IN :bcAccountsByEmail.keySet()
        ];

        BCMap contactByEmail = new BCMap(matchedContacts, 'Email');

        for (String email : contactByEmail.keySet()) {
            Contact contact = (Contact) contactByEmail.get(email);
            for (
                Brightcove_Account__c bcAccount : bcAccountsByEmail.get(email)
            ) {
                bcAccount.Account__c = contact.AccountId;
            }
        }
    }

    void matchByDomain() {
        List<Account> matchedAccounts = [
            SELECT Id, Email_Domain_Name__c
            FROM Account
            WHERE Email_Domain_Name__c IN :bcAccountsByEmailDomain.keySet()
        ];
        BCMap accountsByDomain = new BCMap(
            matchedAccounts,
            'Email_Domain_Name__c'
        );
        for (String domain : accountsByDomain.keySet()) {
            for (
                Brightcove_Account__c bcAccount : bcAccountsByEmailDomain.get(
                    domain
                )
            ) {
                if (bcAccount.Account__c == null) {
                    bcAccount.Account__c = accountsByDomain.get(domain).Id;
                }
            }
        }
    }
}