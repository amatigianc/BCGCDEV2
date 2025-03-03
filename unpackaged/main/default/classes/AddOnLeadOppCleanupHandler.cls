/**
 * This class is responsible for deleting Opportunities with the Record Type of
 * "Lead" and the Deal Type of "Add-On" after an Opportunity for the same Account 
 * with the Record Type of "Add-On" is created.
 * 
 * Test coverage for this class is found in AddOnRelatedStageZeroHandlerTest
 */
public with sharing class AddOnLeadOppCleanupHandler {
    public static void process(List<Add_On_Lead_Opp_Cleanup__e> events) {
        List<Opportunity> opps = new List<Opportunity>();
        for(Add_On_Lead_Opp_Cleanup__e event : events) {
            opps.add(new Opportunity(Id = event.Opportunity_Id__c));
        }

        delete opps;
    }
}