public class LegacyTemplateLineSummaryController {
    public class BCException extends Exception {
    }

    public SBQQ__Quote__c q { get; set; }
    public Map<Id, Map<Integer, Decimal>> bundleTotalByDimension { get; set; }

    // roll up quantity of same product name.  do not include quantity of parent product (non mdq).
    public Map<Integer, Map<String, Decimal>> bundleQtyTotalByDimensionByProductName {
        get;
        set;
    }
    public Map<String, Boolean> bundleQtyTotalByDimensionByProductNameIsNotEmpty {
        get;
        set;
    }

    public Map<Id, Map<Integer, Decimal>> discountAverageTotalByDimension {
        get;
        set;
    }
    public Map<Id, Map<Integer, Decimal>> discountAverageByDimension {
        get;
        set;
    }
    public Map<Integer, Map<Id, List<SBQQ__QuoteLine__c>>> productByByBundleByDimension {
        get;
        set;
    }
    public Set<Integer> years { get; set; }
    public List<SBQQ__QuoteLine__c> productNotBundle { get; set; }
    public Map<Integer, List<SBQQ__QuoteLine__c>> mdqProductNotBundle {
        get;
        set;
    }
    public List<Id> mapKeys { get; set; }
    public Boolean bundleTotalByDimensionIsNotEmpty { get; set; }
    public Map<Integer, Boolean> mdqProductNotBundleIsNotEmptyByDimension {
        get;
        set;
    }
    public Map<Integer, Decimal> totalByYear { get; set; }
    public Decimal totalExcludingFirstSegment { get; set; }
    public string currencyCode { get; set; }
    public Map<Id, Id> parentBundleBychildBundle { get; set; }
    public Map<Integer, List<SBQQ__QuoteLine__c>> oneTimeByDimension {
        get;
        set;
    }
    public Map<Integer, Boolean> oneTimeIsNotEmptyByDimension { get; set; }
    public Boolean totalByYearIsNotEmpty { get; set; }
    public Boolean totalBySizeGreaterThan1 { get; set; }
    public Map<String, Id> linesByPCode { get; set; }
    public Map<String, List<SBQQ__QuoteLine__c>> qLineByPCode { get; set; }

    public Boolean useTermQuantity { get; set; }

    public Boolean showDiscount { get; set; }

    public Map<Id, Double> originalQtyById { get; set; }

    //used in Contract Template
    //public String supportPackageProductName {get;set;}
    //public Decimal mandatoryRenewalTerm {get;set;}
    //public Double mandatoryRenewalFee {get;set;}
    //public Date dateOfExistingAgreement {get;set;}
    //public Integer initialTermMultiYear {get;set;}
    //public integer titleIndex {get;set;}

    public Boolean lessThanAYear { get; set; }

    public LegacyTemplateLineSummaryController() {
        string debugPrefix = 'TemplateSummarySectionCtr.TemplateSummarySectionCtr(): ';
        Id quoteId = (Id) ApexPages.currentPage().getParameters().get('qid');
        bundleTotalByDimension = new Map<Id, Map<Integer, Decimal>>();

        bundleQtyTotalByDimensionByProductName = new Map<Integer, Map<String, Decimal>>();
        bundleQtyTotalByDimensionByProductNameIsNotEmpty = new Map<String, Boolean>();

        discountAverageTotalByDimension = new Map<Id, Map<Integer, Decimal>>();
        discountAverageByDimension = new Map<Id, Map<Integer, Decimal>>();
        productByByBundleByDimension = new Map<Integer, Map<Id, List<SBQQ__QuoteLine__c>>>();
        years = new Set<Integer>{ 1 };
        productNotBundle = new List<SBQQ__QuoteLine__c>();
        mdqProductNotBundle = new Map<Integer, List<SBQQ__QuoteLine__c>>();
        mapKeys = new List<Id>();
        bundleTotalByDimensionIsNotEmpty = false;
        mdqProductNotBundleIsNotEmptyByDimension = new Map<Integer, Boolean>{
            1 => false,
            2 => false,
            3 => false,
            4 => false,
            5 => false
        };
        totalByYear = new Map<Integer, Decimal>();
        parentBundleBychildBundle = new Map<Id, Id>();
        oneTimeByDimension = new Map<Integer, List<SBQQ__QuoteLine__c>>();
        oneTimeIsNotEmptyByDimension = new Map<Integer, Boolean>{
            1 => false,
            2 => false,
            3 => false,
            4 => false,
            5 => false
        };
        Set<String> supportPackages = new Set<String>();
        totalByYearIsNotEmpty = false;
        totalBySizeGreaterThan1 = false;
        linesByPCode = new Map<String, Id>();
        qLineByPCode = new Map<String, List<SBQQ__QuoteLine__c>>();
        totalExcludingFirstSegment = 0;
        useTermQuantity = false;
        originalQtyById = new Map<Id, Double>();

        q = [
            SELECT
                Id,
                DocumentCurrencySymbol__c,
                Outgoing_Document_Use_Term_Quantity__c,
                SBQQ__SubscriptionTerm__c,
                SBQQ__Type__c
            FROM SBQQ__Quote__c
            WHERE Id = :quoteId
            LIMIT 1
        ];
        currencyCode = q <> null ? q.DocumentCurrencySymbol__c : '';
        useTermQuantity = q.Outgoing_Document_Use_Term_Quantity__c;
        lessThanAYear =
            q.SBQQ__SubscriptionTerm__c < 12 &&
            q.SBQQ__Type__c <> 'Amendment';

        //Process bundles that are not childs of other bundles
        supportPackages = processGrandparentBundles(quoteId, supportPackages);

        //Used for "Products with Duplicate Codes" rollup functionality
        List<SBQQ__QuoteLine__c> qList = processChildren(quoteId);

        //process bundles components (includes nested bundles) and non bundle components
        supportPackages = processNonGrandparentLines(qList, supportPackages);

        //Products with duplicates codes rollup functionality
        rollupDuplicateCodes();
    }

    public Set<String> processGrandparentBundles(
        string quoteId,
        Set<String> supportPackages
    ) {
        string debugPrefix = 'TemplateSummarySectionCtr.processGrandparentBundles(): ';
        List<SBQQ__QuoteLine__c> lstQLI = [
            SELECT
                Id,
                SBQQ__Quote__r.SBQQ__Type__c,
                SBQQ__Quote__r.SBQQ__FirstSegmentTermEndDate__c,
                SBQQ__Quote__r.SBQQ__EndDate__c,
                SBQQ__AdditionalDiscountAmount__c,
                SBQQ__TotalDiscountRate__c,
                SBQQ__ProductName__c,
                SBQQ__OptionLevel__c,
                SBQQ__ListPrice__c,
                SBQQ__Quantity__c,
                SBQQ__ProductCode__c,
                SBQQ__ProductFamily__c,
                SBQQ__Description__c,
                Description_Updated__c,
                SBQQ__Bundle__c,
                SBQQ__SegmentIndex__c,
                SBQQ__NetTotal__c,
                Net_Total_Display__c,
                SBQQ__Discount__c,
                SBQQ__ProductSubscriptionType__c,
                SBQQ__Quote__r.SBQQ__SubscriptionTerm__c,
                SBQQ__Quote__r.Initial_Term_Length__c,
                SBQQ__RequiredBy__c,
                Oracle_Code__c,
                Term_Quantity__c,
                Custom_Product_Name__c,
                Custom_Product_Description__c,
                Has_Custom_Product_Name__c,
                Paperwork_Product_Name__c
            FROM SBQQ__QuoteLine__c
            WHERE
                SBQQ__Quote__c = :quoteId
                AND SBQQ__Bundle__c = TRUE
                AND SBQQ__OptionLevel__c = NULL
                AND SBQQ__ProductFamily__c != 'Rate Cards'
                AND SBQQ__EffectiveQuantity__c > 0
            ORDER BY
                SBQQ__SegmentIndex__c,
                Paperwork_Sort_Order__c,
                SBQQ__Product__r.SBQQ__SortOrder__c
        ];

        for (SBQQ__QuoteLine__c ql : lstQLI) {
            if (!originalQtyById.containsKey(ql.Id)) {
                originalQtyById.put(ql.Id, ql.SBQQ__Quantity__c);
            }
            Integer segmentIndex = (Integer) ql.SBQQ__SegmentIndex__c;

            if (ql != null && ql.Description_Updated__c != null) {
                ql.Description_Updated__c = ql.Description_Updated__c.replaceAll(
                    '<[^>]+>',
                    ' '
                );
            }

            if (ql != null && ql.Custom_Product_Description__c != null) {
                ql.Custom_Product_Description__c = ql.Custom_Product_Description__c.replaceAll(
                    '<[^>]+>',
                    ' '
                );
            }

            if (!bundleTotalByDimension.containsKey(ql.Id)) {
                bundleTotalByDimension.put(
                    ql.Id,
                    new Map<Integer, Decimal>{ 1 => 0 }
                );
                discountAverageTotalByDimension.put(
                    ql.Id,
                    new Map<Integer, Decimal>()
                );
                discountAverageByDimension.put(
                    ql.Id,
                    new Map<Integer, Decimal>()
                );
                mapKeys.add(ql.Id);
                bundleTotalByDimensionIsNotEmpty = true;
            }

            //Products will be displayed in year 1 dimension even if there are no MDQ products
            if (!productByByBundleByDimension.containsKey(1)) {
                productByByBundleByDimension.put(
                    1,
                    new Map<Id, List<SBQQ__QuoteLine__c>>()
                );
            }
            if (!productByByBundleByDimension.get(1).containsKey(ql.Id)) {
                productByByBundleByDimension.get(1)
                    .put(ql.Id, new List<SBQQ__QuoteLine__c>{ ql });
            }

            //initializes total by bundle map
            if (!totalByYear.containsKey(1)) {
                totalByYear.put(1, 0);
            }

            //populate a map of quote lines by product code
            String parentLineId = 'blank';
            if (
                !qLineByPCode.containsKey(
                    ql.SBQQ__ProductCode__c +
                        '-' +
                        parentLineId +
                        '-' +
                        ql.SBQQ__SegmentIndex__c
                )
            ) {
                qLineByPCode.put(
                    ql.SBQQ__ProductCode__c +
                        '-' +
                        parentLineId +
                        '-' +
                        ql.SBQQ__SegmentIndex__c,
                    new List<SBQQ__QuoteLine__c>()
                );
            }
            qLineByPCode.get(
                    ql.SBQQ__ProductCode__c +
                        '-' +
                        parentLineId +
                        '-' +
                        ql.SBQQ__SegmentIndex__c
                )
                .add(ql);

            this.populateMapOfQtyByDimensionByProductName(ql, segmentIndex);
        }

        return supportPackages;
    }

    public List<SBQQ__QuoteLine__c> processChildren(string quoteId) {
        string debugPrefix = 'TemplateSummarySectionCtr.processChildren(): ';
        List<SBQQ__QuoteLine__c> qList = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> lstQLI = [
            SELECT
                Id,
                SBQQ__Quote__r.SBQQ__Type__c,
                SBQQ__Quote__r.SBQQ__FirstSegmentTermEndDate__c,
                SBQQ__Quote__r.SBQQ__EndDate__c,
                SBQQ__AdditionalDiscountAmount__c,
                SBQQ__TotalDiscountRate__c,
                SBQQ__ProductName__c,
                SBQQ__ListPrice__c,
                SBQQ__Quantity__c,
                SBQQ__ProductCode__c,
                SBQQ__ProductFamily__c,
                SBQQ__Description__c,
                Description_Updated__c,
                SBQQ__RequiredBy__c,
                SBQQ__NetTotal__c,
                Net_Total_Display__c,
                SBQQ__SegmentIndex__c,
                SBQQ__Discount__c,
                Oracle_Code__c,
                SBQQ__Bundle__c,
                SBQQ__OptionLevel__c,
                SBQQ__ProductSubscriptionType__c,
                SBQQ__Quote__r.SBQQ__SubscriptionTerm__c,
                SBQQ__Quote__r.Initial_Term_Length__c,
                Term_Quantity__c,
                Custom_Product_Name__c,
                Custom_Product_Description__c,
                Has_Custom_Product_Name__c,
                Paperwork_Product_Name__c
            FROM SBQQ__QuoteLine__c
            WHERE
                SBQQ__Quote__c = :quoteId
                AND (SBQQ__Bundle__c = FALSE
                OR SBQQ__OptionLevel__c != NULL)
                AND ((SBQQ__EffectiveQuantity__c > 0
                AND SBQQ__Quote__r.SBQQ__Type__c = 'Amendment')
                OR SBQQ__Quote__r.SBQQ__Type__c != 'Amendment')
                AND SBQQ__ProductFamily__c != 'Rate Cards'
            ORDER BY
                SBQQ__OptionLevel__c,
                SBQQ__SegmentIndex__c,
                Paperwork_Sort_Order__c,
                SBQQ__Product__r.SBQQ__SortOrder__c
        ];

        for (SBQQ__QuoteLine__c ql : lstQLI) {
            if (!originalQtyById.containsKey(ql.Id)) {
                originalQtyById.put(ql.Id, ql.SBQQ__Quantity__c);
            }
            Integer segmentIndex = (Integer) ql.SBQQ__SegmentIndex__c;

            if (ql.SBQQ__ProductCode__c <> null) {
                String parentLineId = 'blank';
                if (ql.SBQQ__RequiredBy__c <> null) {
                    parentLineId = ql.SBQQ__RequiredBy__c;
                }

                if (ql.SBQQ__NetTotal__c == 0) {
                    linesByPCode.put(
                        ql.SBQQ__ProductCode__c +
                            '-' +
                            parentLineId +
                            '-' +
                            ql.SBQQ__SegmentIndex__c,
                        ql.Id
                    );
                }

                if (ql != null && ql.Description_Updated__c != null) {
                    ql.Description_Updated__c = ql.Description_Updated__c.replaceAll(
                        '<[^>]+>',
                        ' '
                    );
                }

                if (ql != null && ql.Custom_Product_Description__c != null) {
                    ql.Custom_Product_Description__c = ql.Custom_Product_Description__c.replaceAll(
                        '<[^>]+>',
                        ' '
                    );
                }

                //populate a map of quote lines by product code
                if (
                    !qLineByPCode.containsKey(
                        ql.SBQQ__ProductCode__c +
                            '-' +
                            parentLineId +
                            '-' +
                            ql.SBQQ__SegmentIndex__c
                    )
                ) {
                    qLineByPCode.put(
                        ql.SBQQ__ProductCode__c +
                            '-' +
                            parentLineId +
                            '-' +
                            ql.SBQQ__SegmentIndex__c,
                        new List<SBQQ__QuoteLine__c>()
                    );
                }
                qLineByPCode.get(
                        ql.SBQQ__ProductCode__c +
                            '-' +
                            parentLineId +
                            '-' +
                            ql.SBQQ__SegmentIndex__c
                    )
                    .add(ql);
            }

            qList.add(ql);

            // default the not empty map.
            if (
                !bundleQtyTotalByDimensionByProductNameIsNotEmpty.containsKey(
                    ql.SBQQ__ProductName__c
                )
            ) {
                bundleQtyTotalByDimensionByProductNameIsNotEmpty.put(
                    ql.SBQQ__ProductName__c,
                    false
                );
            }

            //this.populateMapOfQtyByDimensionByProductName(ql, segmentIndex);
        }

        return qList;
    }

    public Set<String> processNonGrandparentLines(
        List<SBQQ__QuoteLine__c> qList,
        Set<String> supportPackages
    ) {
        String debugPrefix = 'TemplateSummarySectionCtr.processNonGrandparentLines(): ';

        // set up parent bundle lookup by child bundle.
        Map<String, List<SBQQ__QuoteLine__c>> qLineSortMap = new Map<String, List<SBQQ__QuoteLine__c>>();
        for (SBQQ__QuoteLine__c ql : qList) {
            //when is a bundle component
            if (ql.SBQQ__RequiredBy__c <> null) {
                //populate map (used for nested bundles)
                if (ql.SBQQ__Bundle__c == true) {
                    parentBundleBychildBundle.put(
                        ql.Id,
                        ql.SBQQ__RequiredBy__c
                    );
                }
            }

            if (!qLineSortMap.containsKey(ql.Paperwork_Product_Name__c)) {
                qLineSortMap.put(
                    ql.Paperwork_Product_Name__c,
                    new List<SBQQ__QuoteLine__c>()
                );
            }
            qLineSortMap.get(ql.Paperwork_Product_Name__c).add(ql);
        }

        List<String> sortedProductNames = new List<String>(
            qLineSortMap.keySet()
        );
        sortedProductNames.sort();
        List<SBQQ__QuoteLine__c> sortedQlList = new List<SBQQ__QuoteLine__c>();
        for (String productName : sortedProductNames) {
            sortedQlList.addAll(qLineSortMap.get(productName));
        }

        qList = sortedQlList;

        Decimal count = 1;

        for (SBQQ__QuoteLine__c ql : qList) {
            Decimal netTotalSum;
            Decimal discountAverageTotal;
            Decimal discountAverage;
            Decimal yearTotal;
            Integer segmentIndex = (Integer) ql.SBQQ__SegmentIndex__c;

            //used in Contract Template
            if (ql.SBQQ__ProductName__c.contains('Support Package')) {
                supportPackages.add(ql.SBQQ__ProductName__c);
            }

            //when is a bundle component
            if (ql.SBQQ__RequiredBy__c <> null) {
                //Initialize Bundle year dimension map only if it's not a grandchild
                if (ql.SBQQ__OptionLevel__c == 1) {
                    if (
                        bundleTotalByDimension == null ||
                        ql.SBQQ__RequiredBy__c == null ||
                        bundleTotalByDimension.get(ql.SBQQ__RequiredBy__c) ==
                        null ||
                        bundleTotalByDimension.get(ql.SBQQ__RequiredBy__c)
                            .size() == 0
                    ) {
                        discountAverageTotalByDimension.get(
                                ql.SBQQ__RequiredBy__c
                            )
                            .put(1, 0);
                        discountAverageByDimension.get(ql.SBQQ__RequiredBy__c)
                            .put(1, 0);
                    }
                }

                //process MDQ components
                if (segmentIndex <> null) {
                    //add dimension to years list if it's not included
                    if (!years.contains(segmentIndex)) {
                        years.add(segmentIndex);
                    }

                    if (ql.SBQQ__ProductSubscriptionType__c == 'Renewable') {
                        //put dimensions if it does not exist (do not apply for year 1)
                        if (
                            !productByByBundleByDimension.containsKey(
                                segmentIndex
                            )
                        ) {
                            productByByBundleByDimension.put(
                                segmentIndex,
                                new Map<Id, List<SBQQ__QuoteLine__c>>()
                            );
                        }

                        //put the bundle line when the bundle was not in that dimension (do not apply for year 1)
                        if (ql.SBQQ__OptionLevel__c == 1) {
                            if (
                                !productByByBundleByDimension.get(segmentIndex)
                                    .containsKey(ql.SBQQ__RequiredBy__c)
                            ) {
                                productByByBundleByDimension.get(segmentIndex)
                                    .put(
                                        ql.SBQQ__RequiredBy__c,
                                        new List<SBQQ__QuoteLine__c>()
                                    );
                                SBQQ__QuoteLine__c qBun = productByByBundleByDimension.get(
                                        1
                                    )
                                    .get(ql.SBQQ__RequiredBy__c)[0];
                                productByByBundleByDimension.get(segmentIndex)
                                    .get(ql.SBQQ__RequiredBy__c)
                                    .add(qBun);
                            }

                            //store bundle components for that dimension
                            if (ql.SBQQ__ProductCode__c <> null) {
                                if (
                                    !ql.SBQQ__ProductCode__c.startsWith('100-')
                                ) {
                                    ql.Net_Total_Display__c = 'Included';
                                    productByByBundleByDimension.get(
                                            segmentIndex
                                        )
                                        .get(ql.SBQQ__RequiredBy__c)
                                        .add(ql);
                                }
                            }
                        } else {
                            //if it's a nested bundle components put's grand parent into map
                            if (
                                !productByByBundleByDimension.get(segmentIndex)
                                    .containsKey(
                                        parentBundleBychildBundle.get(
                                            ql.SBQQ__RequiredBy__c
                                        )
                                    )
                            ) {
                                productByByBundleByDimension.get(segmentIndex)
                                    .put(
                                        parentBundleBychildBundle.get(
                                            ql.SBQQ__RequiredBy__c
                                        ),
                                        new List<SBQQ__QuoteLine__c>()
                                    );
                                List<SBQQ__QuoteLine__c> ls = productByByBundleByDimension.get(
                                        1
                                    )
                                    .get(
                                        parentBundleBychildBundle.get(
                                            ql.SBQQ__RequiredBy__c
                                        )
                                    );
                                if (ls.size() > 0) {
                                    SBQQ__QuoteLine__c qGrandBun = ls[0];
                                    productByByBundleByDimension.get(
                                            segmentIndex
                                        )
                                        .get(
                                            parentBundleBychildBundle.get(
                                                ql.SBQQ__RequiredBy__c
                                            )
                                        )
                                        .add(qGrandBun);
                                }
                            }

                            //store bundle components for that dimension
                            if (ql.SBQQ__ProductCode__c <> null) {
                                if (
                                    !ql.SBQQ__ProductCode__c.startsWith('100-')
                                ) {
                                    ql.Net_Total_Display__c = 'Included';
                                    productByByBundleByDimension.get(
                                            segmentIndex
                                        )
                                        .get(
                                            parentBundleBychildBundle.get(
                                                ql.SBQQ__RequiredBy__c
                                            )
                                        )
                                        .add(ql);
                                }
                            }
                        }
                    } else {
                        //add quote line to one Time map
                        if (ql.SBQQ__ProductCode__c <> null) {
                            if (!ql.SBQQ__ProductCode__c.startsWith('100-')) {
                                ql.Net_Total_Display__c = 'Included';

                                if (
                                    !oneTimeByDimension.containskey(
                                        segmentIndex
                                    )
                                ) {
                                    oneTimeByDimension.put(
                                        segmentIndex,
                                        new List<SBQQ__QuoteLine__c>()
                                    );
                                }

                                oneTimeByDimension.get(segmentIndex).add(ql);
                                oneTimeIsNotEmptyByDimension.put(
                                    segmentIndex,
                                    true
                                );
                            }
                        }
                    }

                    if (ql.SBQQ__OptionLevel__c == 1) {
                        //Sum Bundle dimension total
                        if (
                            !bundleTotalByDimension.get(ql.SBQQ__RequiredBy__c)
                                .containskey(segmentIndex)
                        ) {
                            bundleTotalByDimension.get(ql.SBQQ__RequiredBy__c)
                                .put(segmentIndex, 0);
                            discountAverageTotalByDimension.get(
                                    ql.SBQQ__RequiredBy__c
                                )
                                .put(segmentIndex, 0);
                            discountAverageByDimension.get(
                                    ql.SBQQ__RequiredBy__c
                                )
                                .put(segmentIndex, 0);
                        }
                        netTotalSum = bundleTotalByDimension.get(
                                ql.SBQQ__RequiredBy__c
                            )
                            .get(segmentIndex);
                        if (netTotalSum <> null) {
                            netTotalSum += ql.SBQQ__NetTotal__c;
                        } else {
                            netTotalSum = ql.SBQQ__NetTotal__c;
                        }
                        discountAverageTotal = discountAverageTotalByDimension.get(
                                ql.SBQQ__RequiredBy__c
                            )
                            .get(segmentIndex);
                        if (discountAverageTotal <> null) {
                            discountAverageTotal += ql.SBQQ__TotalDiscountRate__c !=
                                null
                                ? ql.SBQQ__TotalDiscountRate__c
                                : 0;
                        } else {
                            discountAverageTotal = ql.SBQQ__TotalDiscountRate__c !=
                                null
                                ? ql.SBQQ__TotalDiscountRate__c
                                : 0;
                        }
                        discountAverage = discountAverageTotal / count;
                        bundleTotalByDimension.get(ql.SBQQ__RequiredBy__c)
                            .put(segmentIndex, netTotalSum);
                        discountAverageTotalByDimension.get(
                                ql.SBQQ__RequiredBy__c
                            )
                            .put(segmentIndex, discountAverageTotal);
                        discountAverageByDimension.get(ql.SBQQ__RequiredBy__c)
                            .put(segmentIndex, discountAverage);
                    } else {
                        //Sum Bundle dimension total into grand parent bundle when for nested bundle components
                        Id grandparentBundleId = parentBundleBychildBundle.get(
                            ql.SBQQ__RequiredBy__c
                        );
                        if (
                            bundleTotalByDimension.get(grandparentBundleId) ==
                            null
                        ) {
                            bundleTotalByDimension.put(
                                grandparentBundleId,
                                new Map<Integer, Decimal>()
                            );
                            discountAverageTotalByDimension.put(
                                grandparentBundleId,
                                new Map<Integer, Decimal>()
                            );
                            discountAverageByDimension.put(
                                grandparentBundleId,
                                new Map<Integer, Decimal>()
                            );
                        }
                        Map<Integer, Decimal> bundleTotal = bundleTotalByDimension.get(
                            grandparentBundleId
                        );
                        if (!bundleTotal.containskey(segmentIndex)) {
                            bundleTotalByDimension.get(grandparentBundleId)
                                .put(segmentIndex, 0);
                            discountAverageTotalByDimension.get(
                                    grandparentBundleId
                                )
                                .put(segmentIndex, 0);
                            discountAverageByDimension.get(grandparentBundleId)
                                .put(segmentIndex, 0);
                        }
                        netTotalSum = bundleTotalByDimension.get(
                                grandparentBundleId
                            )
                            .get(segmentIndex);
                        if (netTotalSum <> null) {
                            netTotalSum += ql.SBQQ__NetTotal__c;
                        } else {
                            netTotalSum = ql.SBQQ__NetTotal__c;
                        }
                        discountAverageTotal = discountAverageTotalByDimension.get(
                                grandparentBundleId
                            )
                            .get(segmentIndex);
                        if (discountAverageTotal <> null) {
                            discountAverageTotal += ql.SBQQ__TotalDiscountRate__c !=
                                null
                                ? ql.SBQQ__TotalDiscountRate__c
                                : 0;
                        } else {
                            discountAverageTotal = ql.SBQQ__TotalDiscountRate__c !=
                                null
                                ? ql.SBQQ__TotalDiscountRate__c
                                : 0;
                        }
                        discountAverage = discountAverageTotal / count;
                        bundleTotalByDimension.get(grandparentBundleId)
                            .put(segmentIndex, netTotalSum);
                        discountAverageTotalByDimension.get(grandparentBundleId)
                            .put(segmentIndex, discountAverageTotal);
                        discountAverageByDimension.get(grandparentBundleId)
                            .put(segmentIndex, discountAverage);
                    }

                    //Initialize total by year if year is not yet a key in the map
                    if (!totalByYear.containsKey(segmentIndex)) {
                        totalByYear.put(segmentIndex, 0);
                    }

                    //sum year total
                    yearTotal = totalByYear.get(segmentIndex);
                    yearTotal += ql.SBQQ__NetTotal__c;
                    totalByYear.put(segmentIndex, yearTotal);

                    if (
                        segmentIndex > 1 ||
                        ql.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c -
                        ql.SBQQ__Quote__r.Initial_Term_Length__c == 0
                    ) {
                        totalExcludingFirstSegment += ql.SBQQ__NetTotal__c;
                    }
                } else {
                    //components is not MDQ

                    if (ql.SBQQ__ProductSubscriptionType__c == 'Renewable') {
                        //store bundle component in dimension year 1
                        if (ql.SBQQ__ProductCode__c <> null) {
                            if (!ql.SBQQ__ProductCode__c.startsWith('100-')) {
                                ql.Net_Total_Display__c = 'Included';
                                productByByBundleByDimension.get(1)
                                    .get(ql.SBQQ__RequiredBy__c)
                                    .add(ql);
                            }
                        }
                    } else {
                        //add quote line to one Time map
                        if (ql.SBQQ__ProductCode__c <> null) {
                            if (!ql.SBQQ__ProductCode__c.startsWith('100-')) {
                                ql.Net_Total_Display__c = 'Included';
                                if (!oneTimeByDimension.containskey(1)) {
                                    oneTimeByDimension.put(
                                        1,
                                        new List<SBQQ__QuoteLine__c>()
                                    );
                                }
                                oneTimeByDimension.get(1).add(ql);
                                oneTimeIsNotEmptyByDimension.put(1, true);
                            }
                        }
                    }

                    if (ql.SBQQ__OptionLevel__c == 1) {
                        //Sum Bundle dimension total
                        netTotalSum = bundleTotalByDimension.get(
                                ql.SBQQ__RequiredBy__c
                            )
                            .get(1);
                        if (netTotalSum <> null) {
                            netTotalSum += ql.SBQQ__NetTotal__c;
                        } else {
                            netTotalSum = ql.SBQQ__NetTotal__c;
                        }
                        discountAverageTotal = discountAverageTotalByDimension.get(
                                ql.SBQQ__RequiredBy__c
                            )
                            .get(1);
                        if (discountAverageTotal <> null) {
                            discountAverageTotal += ql.SBQQ__TotalDiscountRate__c !=
                                null
                                ? ql.SBQQ__TotalDiscountRate__c
                                : 0;
                        } else {
                            discountAverageTotal = ql.SBQQ__TotalDiscountRate__c !=
                                null
                                ? ql.SBQQ__TotalDiscountRate__c
                                : 0;
                        }
                        discountAverage = discountAverageTotal / count;
                        if (
                            bundleTotalByDimension.containsKey(
                                ql.SBQQ__RequiredBy__c
                            )
                        ) {
                            bundleTotalByDimension.get(ql.SBQQ__RequiredBy__c)
                                .put(1, netTotalSum);
                            discountAverageTotalByDimension.get(
                                    ql.SBQQ__RequiredBy__c
                                )
                                .put(1, discountAverageTotal);
                            discountAverageByDimension.get(
                                    ql.SBQQ__RequiredBy__c
                                )
                                .put(1, discountAverage);
                        }
                    } else {
                        //Sum Bundle dimension total into grand parent bundle
                        netTotalSum = bundleTotalByDimension.get(
                                parentBundleBychildBundle.get(
                                    ql.SBQQ__RequiredBy__c
                                )
                            )
                            .get(1);
                        discountAverageTotal = discountAverageByDimension.get(
                                parentBundleBychildBundle.get(
                                    ql.SBQQ__RequiredBy__c
                                )
                            )
                            .get(1);
                        if (netTotalSum == null) {
                            netTotalSum = 0;
                        }
                        if (netTotalSum <> null) {
                            netTotalSum += ql.SBQQ__NetTotal__c;
                        } else {
                            netTotalSum = ql.SBQQ__NetTotal__c;
                        }
                        if (discountAverageTotal <> null) {
                            discountAverageTotal += ql.SBQQ__TotalDiscountRate__c !=
                                null
                                ? ql.SBQQ__TotalDiscountRate__c
                                : 0;
                        } else {
                            discountAverageTotal = 0;
                        }
                        discountAverage = discountAverageTotal / count;
                        bundleTotalByDimension.get(
                                parentBundleBychildBundle.get(
                                    ql.SBQQ__RequiredBy__c
                                )
                            )
                            .put(1, netTotalSum);
                        discountAverageTotalByDimension.get(
                                parentBundleBychildBundle.get(
                                    ql.SBQQ__RequiredBy__c
                                )
                            )
                            .put(1, discountAverageTotal);
                        discountAverageByDimension.get(
                                parentBundleBychildBundle.get(
                                    ql.SBQQ__RequiredBy__c
                                )
                            )
                            .put(1, discountAverage);
                    }

                    //sum year total
                    yearTotal = totalByYear.get(1);
                    yearTotal += ql.SBQQ__NetTotal__c;
                    totalByYear.put(1, yearTotal);
                }
            } else {
                //product is not a bundle component

                //when is a mdq product
                if (segmentIndex <> null) {
                    //add dimension to years list if it's not included
                    if (!years.contains(segmentIndex)) {
                        years.add(segmentIndex);
                    }

                    //Initialize total by year if year is not yet a key in the map
                    if (!totalByYear.containsKey(segmentIndex)) {
                        totalByYear.put(segmentIndex, 0);
                    }

                    //sum year total
                    yearTotal = totalByYear.get(segmentIndex);
                    yearTotal += ql.SBQQ__NetTotal__c;
                    totalByYear.put(segmentIndex, yearTotal);

                    if (
                        segmentIndex > 1 ||
                        (ql.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c != null &&
                        ql.SBQQ__Quote__r.Initial_Term_Length__c != null &&
                        ql.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c -
                        ql.SBQQ__Quote__r.Initial_Term_Length__c == 0) ||
                        (ql.SBQQ__Quote__r.SBQQ__FirstSegmentTermEndDate__c !=
                        null &&
                        ql.SBQQ__Quote__r.SBQQ__EndDate__c != null &&
                        ql.SBQQ__Quote__r.SBQQ__FirstSegmentTermEndDate__c ==
                        ql.SBQQ__Quote__r.SBQQ__EndDate__c)
                    ) {
                        totalExcludingFirstSegment += ql.SBQQ__NetTotal__c;
                    }

                    if (ql.SBQQ__ProductCode__c <> null) {
                        if (!ql.SBQQ__ProductCode__c.startsWith('100-')) {
                            if (
                                ql.SBQQ__ProductSubscriptionType__c ==
                                'Renewable'
                            ) {
                                if (
                                    !mdqProductNotBundle.containskey(
                                        segmentIndex
                                    )
                                ) {
                                    mdqProductNotBundle.put(
                                        segmentIndex,
                                        new List<SBQQ__QuoteLine__c>()
                                    );
                                }
                                mdqProductNotBundle.get(segmentIndex).add(ql);
                                mdqProductNotBundleIsNotEmptyByDimension.put(
                                    segmentIndex,
                                    true
                                );
                            } else {
                                //add quote line to one Time map
                                if (
                                    !oneTimeByDimension.containskey(
                                        segmentIndex
                                    )
                                ) {
                                    oneTimeByDimension.put(
                                        segmentIndex,
                                        new List<SBQQ__QuoteLine__c>()
                                    );
                                }
                                oneTimeByDimension.get(segmentIndex).add(ql);
                                oneTimeIsNotEmptyByDimension.put(
                                    segmentIndex,
                                    true
                                );
                            }
                        }
                    }
                } else {
                    //is not a mdq product
                    if (ql.SBQQ__ProductCode__c <> null) {
                        //Initialize total by year if year is not yet a key in the map
                        if (!totalByYear.containsKey(1)) {
                            totalByYear.put(1, 0);
                        }

                        //sum year total
                        yearTotal = totalByYear.get(1);
                        yearTotal += ql.SBQQ__NetTotal__c;
                        totalByYear.put(1, yearTotal);

                        if (!ql.SBQQ__ProductCode__c.startsWith('100-')) {
                            if (
                                ql.SBQQ__ProductSubscriptionType__c ==
                                'Renewable'
                            ) {
                                productNotBundle.add(ql);
                            } else {
                                //add quote line to one Time map
                                if (!oneTimeByDimension.containskey(1)) {
                                    oneTimeByDimension.put(
                                        1,
                                        new List<SBQQ__QuoteLine__c>()
                                    );
                                }
                                oneTimeByDimension.get(1).add(ql);
                                oneTimeIsNotEmptyByDimension.put(1, true);
                            }
                        }
                    }
                }
            }

            this.populateMapOfQtyByDimensionByProductName(ql, segmentIndex);
        }

        if (totalByYear.size() > 0) {
            totalByYearIsNotEmpty = true;
        }
        if (totalByYear.size() > 1) {
            totalBySizeGreaterThan1 = true;
        }

        return supportPackages;
    }

    public void populateMapOfQtyByDimensionByProductName(
        SBQQ__QuoteLine__c ql,
        Integer segmentIndex
    ) {
        // default the not empty map.
        if (
            !bundleQtyTotalByDimensionByProductNameIsNotEmpty.containsKey(
                ql.SBQQ__ProductName__c
            )
        ) {
            bundleQtyTotalByDimensionByProductNameIsNotEmpty.put(
                ql.SBQQ__ProductName__c,
                false
            );
        }

        Double qlQuantity = useTermQuantity
            ? ql.Term_Quantity__c
            : ql.SBQQ__Quantity__c;

        // if this is not a bundle,
        if (!ql.SBQQ__Bundle__c) {
            // populate map of bundleQtyTotalByDimensionByProductName
            // if map contains current segmentindex already,
            if (
                bundleQtyTotalByDimensionByProductName.containsKey(segmentIndex)
            ) {
                // get map of qty by product name for this segmentindex.
                Map<String, Decimal> bundleQtyTotalByProductName = bundleQtyTotalByDimensionByProductName.get(
                    segmentIndex
                );

                // if map contains qty for current product name,
                if (
                    bundleQtyTotalByProductName.containsKey(
                        ql.SBQQ__ProductName__c
                    )
                ) {
                    // add current quantity to this qty for current product name.
                    bundleQtyTotalByDimensionByProductName.get(segmentIndex)
                        .put(
                            ql.SBQQ__ProductName__c,
                            qlQuantity +
                            bundleQtyTotalByDimensionByProductName.get(
                                    segmentIndex
                                )
                                .get(ql.SBQQ__ProductName__c)
                        );
                } else {
                    // map does not contain qty for current product name.
                    // add qty for current product name to map.
                    bundleQtyTotalByDimensionByProductName.get(segmentIndex)
                        .put(ql.SBQQ__ProductName__c, qlQuantity);
                }
            } else {
                // map does not contain current segment index.
                // add current segment index to map.
                bundleQtyTotalByDimensionByProductName.put(
                    segmentIndex,
                    new Map<string, Decimal>()
                );

                // add qty for current product name to map.
                bundleQtyTotalByDimensionByProductName.get(segmentIndex)
                    .put(ql.SBQQ__ProductName__c, qlQuantity);
            }
            bundleQtyTotalByDimensionByProductNameIsNotEmpty.put(
                ql.SBQQ__ProductName__c,
                true
            );
        }
    }

    // rollup duplicate codes functionality.
    public void rollupDuplicateCodes() {
        for (Integer i : productByByBundleByDimension.keySet()) {
            for (Id d : productByByBundleByDimension.get(i).keySet()) {
                List<SBQQ__QuoteLine__c> qlToPut = new List<SBQQ__QuoteLine__c>();

                for (
                    SBQQ__QuoteLine__c ql : productByByBundleByDimension.get(i)
                        .get(d)
                ) {
                    Double qlQuantity = useTermQuantity
                        ? ql.Term_Quantity__c
                        : ql.SBQQ__Quantity__c;
                    if (ql.SBQQ__ProductCode__c <> null) {
                        String parentLineId = 'blank';
                        if (ql.SBQQ__RequiredBy__c <> null) {
                            parentLineId = ql.SBQQ__RequiredBy__c;
                        }
                        if (
                            qLineByPCode.get(
                                    ql.SBQQ__ProductCode__c +
                                        '-' +
                                        parentLineId +
                                        '-' +
                                        ql.SBQQ__SegmentIndex__c
                                )
                                .size() == 1
                        ) {
                            qlToPut.add(ql);
                        } else {
                            //if the code is duplicated, check if there is a product with that code
                            //if not it does not do anything
                            if (
                                linesByPCode.containsKey(
                                    ql.SBQQ__ProductCode__c +
                                        '-' +
                                        parentLineId +
                                        '-' +
                                        ql.SBQQ__SegmentIndex__c
                                )
                            ) {
                                //summayze the quantities and update
                                // set the product quantity with the sumarized quantity
                                if (
                                    linesByPCode.get(
                                        ql.SBQQ__ProductCode__c +
                                            '-' +
                                            parentLineId +
                                            '-' +
                                            ql.SBQQ__SegmentIndex__c
                                    ) == ql.id
                                ) {
                                    Decimal qty = 0;
                                    Decimal discd = 0;
                                    Decimal discp = 0;
                                    Decimal count = 0;
                                    for (
                                        SBQQ__QuoteLine__c qlines : qLineByPCode.get(
                                            ql.SBQQ__ProductCode__c +
                                                '-' +
                                                parentLineId +
                                                '-' +
                                                ql.SBQQ__SegmentIndex__c
                                        )
                                    ) {
                                        Double qlineQuantity = useTermQuantity
                                            ? qlines.Term_Quantity__c
                                            : qlines.SBQQ__Quantity__c;
                                        qty += qlineQuantity;
                                        discp += qlines.SBQQ__TotalDiscountRate__c !=
                                            null
                                            ? qlines.SBQQ__TotalDiscountRate__c
                                            : 0;
                                        count++;
                                    }

                                    ql.SBQQ__Quantity__c = qty;
                                    ql.SBQQ__Discount__c = discp / count;
                                    qlToPut.add(ql);
                                }
                            } else {
                                qlToPut.add(ql);
                            }
                        }
                    } else {
                        qlToPut.add(ql);
                    }
                }

                //updates the map list
                productByByBundleByDimension.get(i).put(d, qlToPut);
            }
        }
    }
}