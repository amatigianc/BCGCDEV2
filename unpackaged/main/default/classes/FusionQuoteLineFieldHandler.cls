public with sharing class FusionQuoteLineFieldHandler extends DomainLogicHandler {
    public override void check(SObject newObj) {
        SBQQ__QuoteLine__c newQuoteLine = (SBQQ__QuoteLine__c) newObj;
        if (isQualified(newQuoteLine)) {
            setFusionFields(newQuoteLine);
        }
    }

    public override void check(SObject newObj, SObject oldObj) {
        SBQQ__QuoteLine__c newQuoteLine = (SBQQ__QuoteLine__c) newObj;
        SBQQ__QuoteLine__c oldQuoteLine = (SBQQ__QuoteLine__c) oldObj;
        if (isQualified(newQuoteLine, oldQuoteLine)) {
            setFusionFields(newQuoteLine);
        }
    }

    Boolean isQualified(SBQQ__QuoteLine__c newQuoteLine) {
        return needsLowerLimit(newQuoteLine) && needsRate(newQuoteLine);
    }

    Boolean isQualified(
        SBQQ__QuoteLine__c newQuoteLine,
        SBQQ__QuoteLine__c oldQuoteLine
    ) {
        return isChanged(newQuoteLine, oldQuoteLine);
    }

    Boolean isChanged(
        SBQQ__QuoteLine__c newQuoteLine,
        SBQQ__QuoteLine__c oldQuoteLine
    ) {
        return TriggerUtility.isChanged(
            newQuoteLine,
            oldQuoteLine,
            new List<SObjectField>{
                SBQQ__QuoteLine__c.Total_Overage_Quantity__c,
                SBQQ__QuoteLine__c.Overage_Rate__c
            }
        );
    }

    Boolean needsLowerLimit(SBQQ__QuoteLine__c newQuoteLine) {
        return newQuoteLine.Total_Overage_Quantity__c != null &&
            newQuoteLine.Lower_Limit__c == null;
    }

    Boolean needsRate(SBQQ__QuoteLine__c newQuoteLine) {
        return newQuoteLine.Overage_Rate__c != null &&
            newQuoteLine.Rate__c == null;
    }

    void setFusionFields(SBQQ__QuoteLine__c newQuoteLine) {
        newQuoteLine.Lower_Limit__c = newQuoteLine.Total_Overage_Quantity__c;
        Decimal overageRate = (Decimal) newQuoteLine.Overage_Rate__c;
        Integer precision = (Integer) (newQuoteLine.Overage_Rate_Precision__c == null ? 2 : newQuoteLine.Overage_Rate_Precision__c);
        newQuoteLine.Rate__c = String.valueOf(overageRate.setScale(precision));
    }
}