public with sharing class QuoteApprovalSyncHandler extends DomainLogicHandler {
    Map<String, String> approvalStatusToQuoteStatus = new Map<String, String>{
        'Pending' => 'In Review',
        'Approved' => 'Approved',
        'Recalled' => 'Draft',
        'Rejected' => 'Draft'
    };

    public override void check(SObject newObj, SObject oldObj) {
        if (
            newObj.get('ApprovalStatus__c') != oldObj.get('ApprovalStatus__c')
        ) {
            newObj.put('SBQQ__Status__c', approvalStatusToQuoteStatus.get(
                (String)newObj.get('ApprovalStatus__c')
            ));
        }
    }
}