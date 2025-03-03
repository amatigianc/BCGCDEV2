public with sharing class OpportunityExistingMRRStamper extends DomainLogicHandler {
    List<Opportunity> qualifiedOpps = new List<Opportunity>();
    List<Date> closeDates = new List<Date>();
    List<String> currencies = new List<String>();
    BCMap currentConversionRates;
    BCMap conversions;

    public override void check(SObject newObj) {
        addToQualifiedRecords((Opportunity) newObj);
    }

    public override void check(SObject newObj, SObject oldObj) {
        if (isQualified(newObj, oldObj)) {
            addToQualifiedRecords((Opportunity) newObj);
        }
    }

    public override void processRecords() {
        if (!qualifiedOpps.isEmpty()) {
            setConversions();

            for (Opportunity opp : qualifiedOpps) {
                setExistingMrr(opp);
            }
        }
    }

    void setExistingMrr(Opportunity opp) {
        Double legacyUsdMrr = opp.Legacy_USD_Existing_MRR__c == null
            ? 0
            : opp.Legacy_USD_Existing_MRR__c;

        if (opp.CurrencyIsoCode == 'USD') {
            opp.Existing_MRR__c = legacyUsdMrr;
            return;
        }

        List<DatedConversionRate> rates = conversions.getAll(
            opp.CurrencyIsoCode
        );

        for (DatedConversionRate rate : rates) {
            if (
                rate.StartDate <= opp.CloseDate &&
                rate.NextStartDate > opp.CloseDate
            ) {
                opp.Existing_MRR__c = rate.ConversionRate * legacyUsdMrr;
            }
        }
    }

    void setConversions() {
        if (closeDates.isEmpty()) {
            return;
        }
        closeDates.sort();
        List<DatedConversionRate> conversionRates = [
            SELECT StartDate, NextStartDate, IsoCode, ConversionRate
            FROM DatedConversionRate
            WHERE
                IsoCode IN :currencies
                AND StartDate <= :closeDates[0]
                AND NextStartDate > :closeDates[closeDates.size() - 1]
            ORDER BY StartDate ASC
        ];

        conversions = new BCMap(conversionRates, 'IsoCode');
        setCurrentConversionRates();
    }

    void setCurrentConversionRates() {
        List<AggregateResult> results = [
            SELECT Max(StartDate) MaxDate, IsoCode
            FROM DatedConversionRate
            WHERE IsoCode IN :currencies
            GROUP BY IsoCode
        ];
        List<Date> maxDates = new List<Date>();
        for (AggregateResult result : results) {
            maxDates.add((Date) result.get('MaxDate'));
        }
        List<DatedConversionRate> conversionRates = [
            SELECT IsoCode, ConversionRate
            FROM DatedConversionRate
            WHERE IsoCode IN :currencies AND StartDate IN :maxDates
        ];
        currentConversionRates = new BCMap(conversionRates, 'IsoCode');
    }

    void addToQualifiedRecords(Opportunity newOpp) {
        qualifiedOpps.add(newOpp);
        if (newopp.CurrencyIsoCode != 'USD') {
            closeDates.add(newOpp.CloseDate);
            currencies.add(newOpp.CurrencyIsoCode);
        }
    }

    Boolean isQualified(SObject newObj, SObject oldObj) {
        return TriggerUtility.isChanged(
            newObj,
            oldObj,
            new List<SObjectField>{
                Opportunity.CloseDate,
                Opportunity.CurrencyIsoCode,
                Opportunity.Legacy_USD_Existing_MRR__c
            }
        );
    }
}