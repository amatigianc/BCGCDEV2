public with sharing class EntitlementProcessor {
    static Map<String, Id> slaProcesses = getSlaProcesses();

    public static Entitlement getEntitlement(
        Account account,
        String productName,
        Date startDate,
        Date endDate
    ) {
        Entitlement entitlement = new Entitlement(
            AccountId = account.Id,
            Name = productName,
            StartDate = startDate,
            EndDate = endDate
        );

        productName = productName.split(' ')[0];

        switch on productName {
            when 'Silver' {
                entitlement.SlaProcessId = slaProcesses.get(
                    'Silver ' + account.Sales_Division__c
                );
            }
            when else {
                entitlement.SlaProcessId = slaProcesses.get(productName);
            }
        }
        return entitlement;
    }

    static Map<String, Id> getSlaProcesses() {
        if (slaProcesses == null) {
            slaProcesses = new Map<String, Id>();
            for (SlaProcess slaProcess : [
                SELECT Id, Name
                FROM SlaProcess
                WHERE IsVersionDefault = TRUE
            ]) {
                slaProcesses.put(slaProcess.Name, slaProcess.Id);
            }
        }
        return slaProcesses;
    }
}