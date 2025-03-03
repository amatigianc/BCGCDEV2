@SuppressWarnings('Design-ExcessivePublicCount')
public with sharing class ContractLineSummaryController {
    private String sectionName = 'Quote Lines (One-Time)';
    public SBQQ__Quote__c quote { get; set; }
    public String quoteCurrency { get; set; }
    public List<SBQQ__LineColumn__c> lineColumns { get; set; }
    public List<LineItemSummary> lineSummaries { get; set; }
    public List<String> segmentLabels { get; set; }
    public Map<String, List<LineItemSummary>> lineSummariesBySegment {
        get;
        set;
    }
    public Map<String, Decimal> segmentTotals { get; set; }

    public ContractLineSummaryController() {
        Id quoteId = (Id) ApexPages.currentPage().getParameters().get('qid');
        Id templateId = (Id) ApexPages.currentPage().getParameters().get('tid');

        lineColumns = [
            SELECT
                Id,
                Name,
                SBQQ__Width__c,
                SBQQ__FieldName__c,
                SBQQ__Alignment__c
            FROM SBQQ__LineColumn__c
            WHERE
                SBQQ__Template__c = :templateId
                AND SBQQ__Section__r.Name = :sectionName
            ORDER BY SBQQ__DisplayOrder__c ASC
        ];

        quote = [
            SELECT
                Id,
                Single_Term__c,
                Outgoing_Document_Hide_Product_Prices__c,
                SBQQ__Type__c,
                CurrencyIsoCode
            FROM SBQQ__Quote__c
            WHERE Id = :quoteId
        ];

        lineSummaries = new List<LineItemSummary>();
        segmentLabels = new List<String>();
        lineSummariesBySegment = new Map<String, List<LineItemSummary>>();
        segmentTotals = new Map<String, Decimal>();

        processQuoteLines(quoteId);

        calculateSegmentTotals();
    }

    private void calculateSegmentTotals() {
        for (String key : lineSummariesBySegment.keySet()) {
            Decimal total = 0.0;
            for (
                LineItemSummary lineSummary : lineSummariesBySegment.get(key)
            ) {
                if (!lineSummary.hasPrice) {
                    continue;
                }

                total += lineSummary.termPriceValue;

                //if show bundled
                if (quote.Outgoing_Document_Hide_Product_Prices__c) {
                    lineSummary.termPrice = 'Included';
                }
            }
            segmentTotals.put(key, total);
        }
    }

    private void processQuoteLines(Id quoteId) {
        Map<String, List<SBQQ__QuoteLine__c>> quoteLinesByProductType = getSortedQuoteLines(
            quoteId
        );

        if (quoteLinesByProductType.containsKey('Renewable')) {
            setupLineSummaryMap(quoteLinesByProductType.get('Renewable'));
            populateLineSummaryMap(quoteLinesByProductType.get('Renewable'));
        }
    }

    private Map<String, List<SBQQ__QuoteLine__c>> getSortedQuoteLines(
        Id quoteId
    ) {
        Map<String, List<SBQQ__QuoteLine__c>> results = new Map<String, List<SBQQ__QuoteLine__c>>();
        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT
                Id,
                CurrencyIsoCode,
                SBQQ__ProductName__c,
                Oracle_Code__c,
                SBQQ__Description__c,
                Initial_Term_Quantity__c,
                Initial_Term_Amount__c,
                SBQQ__Quantity__c,
                SBQQ__SegmentLabel__c,
                SBQQ__ProrateMultiplier__c,
                SBQQ__Bundled__c,
                SBQQ__NetTotal__c,
                Term_Quantity__c,
                SBQQ__Product__r.Platform__c,
                Paperwork_Sort_Order__c,
                Paperwork_Product_Type__c
            FROM SBQQ__QuoteLine__c
            WHERE
                SBQQ__Quote__c = :quoteId
                AND SBQQ__Hidden__c = FALSE
                AND Paperwork_Product_Type__c != 'Overage Rate'
            ORDER BY SBQQ__SegmentIndex__c, Paperwork_Sort_Order__c ASC
        ];

        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            if (!results.containsKey(quoteLine.Paperwork_Product_Type__c)) {
                results.put(
                    quoteLine.Paperwork_Product_Type__c,
                    new List<SBQQ__QuoteLine__c>()
                );
            }

            results.get(quoteLine.Paperwork_Product_Type__c).add(quoteLine);
        }

        return results;
    }

    private void setupLineSummaryMap(List<SBQQ__QuoteLine__c> quoteLines) {
        segmentLabels = getSegmentLabels(quoteLines);

        for (String segmentLabel : segmentLabels) {
            String key = segmentLabel;

            if(quote.SBQQ__Type__c == 'Amendment') {
                key = 'Addon';
            }

            if (!lineSummariesBySegment.containsKey(key)) {
                lineSummariesBySegment.put(
                    key,
                    new List<LineItemSummary>()
                );
            }
        }
    }

    private List<String> getSegmentLabels(List<SBQQ__QuoteLine__c> quoteLines) {
        List<String> results = new List<String>();
        if(quote.SBQQ__Type__c == 'Amendment') {
            return new List<String> {'Addon'};
        }

        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            if (quoteLine.SBQQ__SegmentLabel__c == null) {
                continue;
            }

            if (!results.contains(quoteLine.SBQQ__SegmentLabel__c)) {
                results.add(quoteLine.SBQQ__SegmentLabel__c);
            }
        }

        return results;
    }

    private void populateLineSummaryMap(List<SBQQ__QuoteLine__c> quoteLines) {
        List<SBQQ__QuoteLine__c> segmentedLines = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> unsegmentedLines = new List<SBQQ__QuoteLine__c>();
        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            if (quoteCurrency == null) {
                quoteCurrency = quoteLine.CurrencyIsoCode;
            }

            if (quoteLine.SBQQ__SegmentLabel__c == null) {
                unsegmentedLines.add(quoteLine);
            } else {
                segmentedLines.add(quoteLine);
            }
        }

        for (SBQQ__QuoteLine__c quoteLine : segmentedLines) {
            processSegmentedQuoteLine(quoteLine);
        }

        for (SBQQ__QuoteLine__c quoteLine : unsegmentedLines) {
            processUnsegmentedQuoteLine(quoteLine);
        }
    }

    private void processSegmentedQuoteLine(SBQQ__QuoteLine__c quoteLine) {
        String amount = quoteLine.SBQQ__NetTotal__c.toPlainString();
        String key = quoteline.SBQQ__SegmentLabel__c;
        if (quoteLine.SBQQ__Bundled__c || quoteLine.SBQQ__NetTotal__c == 0.0) {
            amount = 'Included';
        }
        if(quote.SBQQ__Type__c == 'Amendment') {
            key = 'Addon';
        }
        lineSummariesBySegment.get(key)
            .add(new LineItemSummary(quoteLine, amount));
    }

    private void processUnsegmentedQuoteLine(SBQQ__QuoteLine__c quoteLine) {
        for (String segmentLabel : segmentLabels) {
            String key = segmentLabel;

            if(quote.SBQQ__Type__c == 'Amendment') {
                key = 'Addon';
            }
            String amount;
            if (quote.Single_Term__c) {
                amount = quoteLine.SBQQ__NetTotal__c.toPlainString();
            } else {
                amount = (quoteLine.SBQQ__NetTotal__c /
                    quoteLine.SBQQ__ProrateMultiplier__c)
                    .toPlainString();
            }

            if (quoteLine.SBQQ__Bundled__c || Decimal.valueOf(amount) == 0.0) {
                amount = 'Included';
            }
            lineSummariesBySegment.get(key)
                .add(new LineItemSummary(quoteLine, amount));
        }
    }

    public class LineItemSummary {
        public String productCode { get; set; }
        public String productName { get; set; }
        public String quantity { get; set; }
        public String description { get; set; }
        public String termPrice { get; set; }
        public String currencyIsoCode { get; set; }
        public Boolean isPlatform { get; set; }
        public Decimal termPriceValue {
            get {
                return Decimal.valueOf(termPrice);
            }
            set;
        }
        public Boolean hasPrice {
            get {
                return termPrice != 'Included';
            }
            set;
        }

        public LineItemSummary(
            SBQQ__QuoteLine__c quoteLine,
            String displayAmount
        ) {
            this.productCode = quoteLine.Oracle_Code__c;
            this.productName = quoteLine.SBQQ__ProductName__c;
            this.quantity = quoteLine.Term_Quantity__c.format();
            this.description = quoteLine.SBQQ__Description__c;
            this.termPrice = displayAmount;
            this.currencyIsoCode = quoteLine.CurrencyIsoCode;
            this.isPlatform = quoteLine.SBQQ__Product__r.Platform__c;
        }
    }
}