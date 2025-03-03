public with sharing class CaseEmailFiles {
    @AuraEnabled(cacheable=true)
    public static List<AttachmentWrapper> getAttachmentsFromCaseEmails(Id caseId) {
        if (caseId == null) {
            throw new AuraHandledException('Case ID cannot be null');
        }
        
        // Step 1: Query all EmailMessages related to the Case
        List<EmailMessage> emails = [
            SELECT Id, Subject, FromAddress, CreatedDate
            FROM EmailMessage
            WHERE ParentId = :caseId
        ];
    
        // Step 2: Collect all EmailMessage IDs
        Set<Id> emailIds = new Set<Id>();
        for (EmailMessage email : emails) {
            emailIds.add(email.Id);
        }
    
        // Step 3: Query attachments for the collected EmailMessage IDs
        List<ContentDocumentLink> attachments = new List<ContentDocumentLink>();
        if (!emailIds.isEmpty()) {
            attachments = [
                SELECT ContentDocument.Title, ContentDocument.LatestPublishedVersionId, LinkedEntityId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :emailIds
            ];
        }
    
        // Step 4: Build the wrapper class to return data
        List<AttachmentWrapper> result = new List<AttachmentWrapper>();
        for (ContentDocumentLink doc : attachments) {
            result.add(new AttachmentWrapper(doc.ContentDocument.Title, doc.ContentDocument.LatestPublishedVersionId));
        }
    
        return result;
    }
    
    // Wrapper class for attachments
    public class AttachmentWrapper {
        @AuraEnabled public String title;
        @AuraEnabled public String downloadUrl;
    
        public AttachmentWrapper(String title, Id versionId) {
            this.title = title;
            this.downloadUrl = '/sfc/servlet.shepherd/version/download/' + versionId;
        }
    }
    
}