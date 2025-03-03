public with sharing class SalesDivisionAssignment {
    public static Map<SObjectType, SObjectField> countryFieldMap = new Map<SObjectType, SObjectField>{
        Account.getSObjectType() => Account.BillingCountryCode,
        Contact.getSObjectType() => Contact.MailingCountryCode,
        Lead.getSObjectType() => Lead.CountryCode
    };

    static Map<String, String> salesDivisionMap = getSalesDivisionMap();
    static Map<SObjectType, SObjectField> salesDivisionFieldMap = new Map<SObjectType, SObjectField>{
        Account.getSObjectType() => Account.Sales_Division__c,
        Contact.getSObjectType() => Contact.Sales_Division_Contact__c,
        Lead.getSObjectType() => Lead.Sales_Division_Contact__c
    };

    public static void assign(SObject sobj) {
        String countryCode = (String) sobj.get(getCountryField(sobj));
        sobj.put(
            getSalesDivisionField(sobj),
            salesDivisionMap.get(countryCode)
        );
    }

    static Map<String, String> getSalesDivisionMap() {
        if (salesDivisionMap == null) {
            salesDivisionMap = new Map<String, String>();
            List<Sales_Division__mdt> salesDivisionMdts = [
                SELECT CountryCode__c, Sales_Division__c
                FROM Sales_Division__mdt
            ];
            for (Sales_Division__mdt salesDivisionMdt : salesDivisionMdts) {
                salesDivisionMap.put(
                    salesDivisionMdt.CountryCode__c,
                    salesDivisionMdt.Sales_Division__c
                );
            }
        }

        return salesDivisionMap;
    }

    static SObjectField getSalesDivisionField(SObject sobj) {
        return salesDivisionFieldMap.get(sobj.getSObjectType());
    }

    static SObjectField getCountryField(SObject sobj) {
        return countryFieldMap.get(sobj.getSObjectType());
    }
}