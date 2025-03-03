@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class ScheduleContractRenewalQuote implements Schedulable {
    public final static String CRON_EXP = '0 0 0 * * ? *'; //runs nightly at midnight

    global void execute(SchedulableContext sc) {
        BatchContractRenewalQuote batchContract = new BatchContractRenewalQuote();
        Database.executeBatch(batchContract, 10);
    }
}