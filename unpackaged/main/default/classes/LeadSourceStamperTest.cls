@isTest(isparallel=true)
public with sharing class LeadSourceStamperTest {
    @isTest
    static void testSetLeadSource() {
        Lead newLead = LeadTestFactory.getLead();
        newLead.Lead_Source_Latest__c = Lead.Lead_Source_Latest__c.getDescribe()
                .getPicklistValues()[0]
            .getValue();
        insert newLead;

        newLead = [
            SELECT Id, LeadSource, Lead_Source_Latest__c
            FROM Lead
            WHERE Id = :newLead.Id
        ];
        System.assertEquals(
            newLead.Lead_Source_Latest__c,
            newLead.LeadSource,
            'Lead Source not stamped from Lead Source Latest.'
        );

        newLead.LeadSource = null;
        newLead.Lead_Source_Latest__c = Lead.Lead_Source_Latest__c.getDescribe()
                .getPicklistValues()[1]
            .getValue();
        update newLead;

        newLead = [
            SELECT Id, LeadSource, Lead_Source_Latest__c
            FROM Lead
            WHERE Id = :newLead.Id
        ];
        System.assertEquals(
            newLead.Lead_Source_Latest__c,
            newLead.LeadSource,
            'Lead Source not stamped from Lead Source Latest.'
        );
    }
}