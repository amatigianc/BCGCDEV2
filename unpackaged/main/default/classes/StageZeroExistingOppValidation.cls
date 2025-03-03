public with sharing class StageZeroExistingOppValidation extends DomainLogicHandler {
    BCMap qualifiedOppsByAccount = new BCMap('AccountId');

    public override void check(SObject newObj) {
        if (isQualified((Opportunity) newObj)) {
            qualifiedOppsByAccount.put(newObj);
        }
    }

    public override void processRecords() {
        if (qualifiedOppsByAccount.isNotAllEmpty()) {
            List<Opportunity> existingOpps = [
                SELECT Id, AccountId
                FROM Opportunity
                WHERE
                    RecordType.Name = 'Lead'
                    AND AccountId IN :qualifiedOppsByAccount.keyAllSet()
                    AND IsClosed = FALSE
                    AND CreatedDate = LAST_N_DAYS:60
            ];
            for (Opportunity existingOpp : existingOpps) {
                for (
                    SObject newObj : qualifiedOppsByAccount.getAll(
                        existingOpp.AccountId
                    )
                ) {
                    newObj.addError(
                        'An existing open Stage Zero Opportunity exists for this Account.'
                    );
                }
            }
        }

        return;
    }

    Boolean isQualified(Opportunity newOpp) {
        return isLeadRecordType(newOpp);
    }

    Boolean isLeadRecordType(Opportunity newOpp) {
        return newOpp.RecordTypeId ==
            RecordTypeUtility.getId(Opportunity.getSObjectType(), 'Lead');
    }
}