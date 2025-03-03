@isTest
public with sharing class LeadTestFactory {
    public static Lead getLead() {
        return new Lead(
            Email = 'LeadTestFactory@example.com',
            LastName = 'LeadTestFactory',
            Company = 'LeadTestFactory'
        );
    }

    public static Lead createLead() {
        Lead lead = getLead();
        insert lead;
        return lead;
    }
}