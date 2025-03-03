@isTest(isparallel=true)
public class CurrencyUtilityTest {
    @isTest
    static void testConvertAndRound() {
        Map<String, Decimal> currencyRatesMap = CurrencyUtility.getInstance()
            .getCurrencyRatesByIsoCode();
        Map<String, Integer> currencyRoundsMap = CurrencyUtility.getInstance()
            .getCurrencyRoundsByIsoCode();

        Decimal inputValue = 16500.0;

        System.assert(
            !currencyRoundsMap.isEmpty(),
            'currencyRoundMap was not populated'
        );

        for (String isoCode : currencyRatesMap.keySet()) {
            Decimal expectedRate = currencyRatesMap.get(isoCode);
            Integer expectedRound = currencyRoundsMap.containsKey(isoCode)
                ? currencyRoundsMap.get(isoCode)
                : 1;
            Decimal expectedOutput =
                Math.round(expectedRate * inputValue / expectedRound) *
                expectedRound;

            Decimal outputValue = CurrencyUtility.getInstance()
                .convertAndRoundPrice(inputValue, isoCode);

            System.assertEquals(
                expectedOutput,
                outputValue,
                'Error converting price, price not converted properly'
            );
        }
    }

    @isTest
    static void testConvertAndRoundDated() {
        Date today = System.today();
        Map<String, Decimal> currencyRatesMap = CurrencyUtility.getInstance(
                today
            )
            .getCurrencyRatesByIsoCode();
        Map<String, Integer> currencyRoundsMap = CurrencyUtility.getInstance(
                today
            )
            .getCurrencyRoundsByIsoCode();

        Decimal inputValue = 16500.0;

        System.assert(
            !currencyRoundsMap.isEmpty(),
            'currencyRoundMap was not populated'
        );

        for (String isoCode : currencyRatesMap.keySet()) {
            Decimal expectedRate = currencyRatesMap.get(isoCode);
            Integer expectedRound = currencyRoundsMap.containsKey(isoCode)
                ? currencyRoundsMap.get(isoCode)
                : 1;
            Decimal expectedOutput =
                Math.round(expectedRate * inputValue / expectedRound) *
                expectedRound;

            Decimal outputValue = CurrencyUtility.getInstance(today)
                .convertAndRoundPrice(inputValue, isoCode);

            System.assertEquals(
                expectedOutput,
                outputValue,
                'Error converting price, price not converted properly'
            );
        }
    }

    @isTest
    static void testConvertAndRoundDateSet() {
        Set<Date> dateSet = new Set<Date>{
            System.today(),
            Date.valueOf('2022-01-01')
        };

        Map<String, Decimal> currencyRatesMap = CurrencyUtility.getInstance(
                dateSet
            )
            .getCurrencyRatesByIsoCode(System.today());
        Map<String, Integer> currencyRoundsMap = CurrencyUtility.getInstance(
                dateSet
            )
            .getCurrencyRoundsByIsoCode();

        Decimal inputValue = 16500.0;

        System.assert(
            !currencyRoundsMap.isEmpty(),
            'currencyRoundMap was not populated'
        );

        for (String isoCode : currencyRatesMap.keySet()) {
            Decimal expectedRate = currencyRatesMap.get(isoCode);
            Integer expectedRound = currencyRoundsMap.containsKey(isoCode)
                ? currencyRoundsMap.get(isoCode)
                : 1;
            Decimal expectedOutput =
                Math.round(expectedRate * inputValue / expectedRound) *
                expectedRound;

            Decimal outputValue = CurrencyUtility.getInstance(dateSet)
                .convertAndRoundPrice(inputValue, isoCode, System.today());

            System.assertEquals(
                expectedOutput,
                outputValue,
                'Error converting price, price not converted properly'
            );
        }
    }

    @IsTest
    static void testConvert() {
        Map<String, Decimal> currencyRatesMap = CurrencyUtility.getInstance()
            .getCurrencyRatesByIsoCode();

        Decimal inputValue = 16500.0;

        for (String isoCode : currencyRatesMap.keySet()) {
            Decimal expectedRate = currencyRatesMap.get(isoCode);
            Decimal expectedOutput = expectedRate * inputValue;

            Decimal outputValue = CurrencyUtility.getInstance()
                .convertPrice(inputValue, isoCode);

            System.assertEquals(
                expectedOutput,
                outputValue,
                'Error converting price, price not converted properly'
            );
        }
    }

    @IsTest
    static void testConvertDated() {
        Date today = System.today();
        Map<String, Decimal> currencyRatesMap = CurrencyUtility.getInstance(
                today
            )
            .getCurrencyRatesByIsoCode();

        Decimal inputValue = 16500.0;

        for (String isoCode : currencyRatesMap.keySet()) {
            Decimal expectedRate = currencyRatesMap.get(isoCode);
            Decimal expectedOutput = expectedRate * inputValue;

            Decimal outputValue = CurrencyUtility.getInstance(today)
                .convertPrice(inputValue, isoCode);

            System.assertEquals(
                expectedOutput,
                outputValue,
                'Error converting price, price not converted properly'
            );
        }
    }

    @IsTest
    static void testConvertDateSet() {
        Set<Date> dateSet = new Set<Date>{
            System.today(),
            Date.valueOf('2022-01-01')
        };

        Map<String, Decimal> currencyRatesMap = CurrencyUtility.getInstance(
                dateSet
            )
            .getCurrencyRatesByIsoCode(System.today());

        Decimal inputValue = 16500.0;

        for (String isoCode : currencyRatesMap.keySet()) {
            Decimal expectedRate = currencyRatesMap.get(isoCode);
            Decimal expectedOutput = expectedRate * inputValue;

            Decimal outputValue = CurrencyUtility.getInstance(dateSet)
                .convertPrice(inputValue, isoCode, System.today());

            System.assertEquals(
                expectedOutput,
                outputValue,
                'Error converting price, price not converted properly'
            );
        }
    }

    @IsTest
    static void testGetSupportedCurrencies() {
        Set<String> supportedCurrencies = CurrencyUtility.getInstance()
            .getSupportedCurrencies();

        System.assert(
            !supportedCurrencies.isEmpty(),
            'No other supported currencies were returned'
        );
    }
}