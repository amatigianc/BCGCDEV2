@SuppressWarnings('Performance-EagerlyLoadedDescribeSObjectResult')
// Not able to set a field describe as deffered.
public with sharing class CurrencyUtility {
    private static CurrencyUtility instance = null;
    private Date currencyDate = System.today();
    private Set<Date> lookupDates = new Set<Date>{System.today()};

    private Map<String, Decimal> currencyRateMap = new Map<String, Decimal>();
    private Map<String, Integer> currencyRoundMap = new Map<String, Integer>();
    private Map<Date, Map<String, Decimal>> currencyRateMapByDate = new Map<Date, Map<String, Decimal>>();

    //Constructors to handle specific scenarios

    //Simple lookup to todays rate
    private CurrencyUtility() {
        buildCurrencyRateMap();
        buildCurrencyRoundMap();
    }

    //Simple lookup to a specific date
    private CurrencyUtility(Date lookupDate) {
        this.currencyDate = lookupDate;
        buildCurrencyRateMap();
        buildCurrencyRoundMap();
    }

    //Advanced lookup that includes range of dates
    private CurrencyUtility(Set<Date> lookupDates) {
        this.lookupDates = lookupDates;
        buildCurrencyRateMapByDate(lookupDates);
        buildCurrencyRoundMap();
    }

    //Use these to create your instance

    //Simple instance with todays rates
    public static CurrencyUtility getInstance() {
        if (instance == null) {
            instance = new CurrencyUtility();
        }

        return instance;
    }

    //Simple instance with specific dates instance
    public static CurrencyUtility getInstance(Date lookupDate) {
        if (instance == null || instance?.currencyDate != lookupDate) {
            instance = new CurrencyUtility(lookupDate);
        }

        return instance;
    }

    //Advanced instance with all dates given in a particular set
    public static CurrencyUtility getInstance(Set<Date> lookupDates) {
        if (instance == null) {
            instance = new CurrencyUtility(lookupDates);
        }

        return instance;
    }


    //Simple methods to use
    public Map<String, Decimal> getCurrencyRatesByIsoCode() {
        return currencyRateMap;
    }

    public Decimal convertAndRoundPrice(Decimal price, String currencyIsoCode) {
        if (!currencyRoundMap.containsKey(currencyIsoCode)) {
            return convertPrice(price, currencyIsoCode);
        }

        Decimal conversionRate = currencyRateMap.get(currencyIsoCode);
        Integer roundAmount = currencyRoundMap.get(currencyIsoCode);

        return Math.round((conversionRate * price / roundAmount)) * roundAmount;
    }

    public Decimal convertPrice(Decimal price, String currencyIsoCode) {
        Decimal conversionRate = currencyRateMap.get(currencyIsoCode);
        return conversionRate * price;
    }

    //Advanced methods to use
    public Map<String, Decimal> getCurrencyRatesByIsoCode(Date lookupDate) {
        return this.currencyRateMapByDate.get(lookupDate);
    }

    public Decimal convertAndRoundPrice(Decimal price, String currencyIsoCode, Date lookupDate) {
        if (!currencyRoundMap.containsKey(currencyIsoCode)) {
            return convertPrice(price, currencyIsoCode, lookupDate);
        }

        Decimal conversionRate = this.currencyRateMapByDate.get(lookupDate).get(currencyIsoCode);
        Integer roundAmount = currencyRoundMap.get(currencyIsoCode);

        return Math.round((conversionRate * price / roundAmount)) * roundAmount;
    }

    public Decimal convertPrice(Decimal price, String currencyIsoCode, Date lookupDate) {
        Decimal conversionRate = this.currencyRateMapByDate.get(lookupDate).get(currencyIsoCode);
        return conversionRate * price;
    }

    public Decimal convertPriceToUSD(Decimal price, String currencyIsoCode, Date lookupDate) {
        if(price == null) {
            return 0.0;
        }

        if(this.currencyRateMapByDate.containsKey(lookupDate)) {
            Decimal conversionRate = this.currencyRateMapByDate.get(lookupDate).get(currencyIsoCode);

            if(conversionRate == null) {
                return price;
            }
    
            return price / conversionRate;
        } else {
            return price;
        }
    }

    //Misc methods
    public Map<String, Integer> getCurrencyRoundsByIsoCode() {
        return currencyRoundMap;
    }
    
    public Set<String> getSupportedCurrencies() {
        Set<String> results = new Set<String>();
        Schema.DescribeFieldResult fieldResult = PricebookEntry.CurrencyIsoCode.getDescribe();
        for (Schema.PicklistEntry value : fieldResult.getPicklistValues()) {
            if (value.getValue() != 'USD') {
                results.add(value.getValue());
            }
        }
        return results;
    }

    /** HELPER METHODS */

    private void buildCurrencyRateMap() {
        for (DatedConversionRate dcr : [
            SELECT Id, IsoCode, ConversionRate
            FROM DatedConversionRate
            WHERE StartDate <= :currencyDate AND NextStartDate >= :currencyDate
            WITH SECURITY_ENFORCED
        ]) {
            currencyRateMap.put(dcr.IsoCode, dcr.ConversionRate);
        }
    }

    private void buildCurrencyRateMapByDate(Set<Date> lookupDates) {
        Date earliestDate = System.today();

        for(Date testDate : lookupDates) {
            if(testDate < earliestDate) {
                earliestDate = testDate;
            }
        }

        List<DatedConversionRate> dcrs = [
            SELECT Id, IsoCode, ConversionRate, StartDate, NextStartDate
            FROM DatedConversionRate
            WHERE StartDate <= :earliestDate OR NextStartDate >= :System.today()
        ];

        for (Date testDate : lookupDates) {
            if(!this.currencyRateMapByDate.containsKey(testDate)) {
                this.currencyRateMapByDate.put(testDate, new Map<String, Decimal>());
            }

            for(DatedConversionRate dcr : dcrs) {
                if(dcr.StartDate <= testDate && dcr.NextStartDate >= testDate) {
                    this.currencyRateMapByDate.get(testDate).put(dcr.IsoCode, dcr.ConversionRate);
                }
            }
        }
    }

    private void buildCurrencyRoundMap() {
        List<CPQ_Price_Rounding__mdt> priceRounding = [
            SELECT Id, Currency__c, Rounding_Amount__c
            FROM CPQ_Price_Rounding__mdt
            WITH SECURITY_ENFORCED
        ];

        for (CPQ_Price_Rounding__mdt pr : priceRounding) {
            currencyRoundMap.put(
                pr.Currency__c,
                (Integer) pr.Rounding_Amount__c
            );
        }
    }
}