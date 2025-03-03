public with sharing class CaseCommentsFiles {
@AuraEnabled(cacheable=true)
    public static List<CaseCommentWrapper> getCaseCommentsWithAttachments(Id caseId) {
        if (caseId == null) {
            throw new AuraHandledException('Case ID cannot be null');
        }
        
        // Step 1: Query all Case Comments for the given Case
        List<CaseComment> comments = [
            SELECT Id, CommentBody, CreatedDate
            FROM CaseComment
            WHERE ParentId = :caseId
        ];
        
        // Step 2: Collect all CaseComment IDs
        Set<Id> commentIds = new Set<Id>();
        for (CaseComment comment : comments) {
            commentIds.add(comment.Id);
        }
    
        // Step 3: Query ContentDocumentLinks with a filter on LinkedEntityId
        Map<Id, List<ContentDocumentLink>> attachmentsMap = new Map<Id, List<ContentDocumentLink>>();
        if (!commentIds.isEmpty()) {
            for (ContentDocumentLink link : [
                SELECT ContentDocument.Title, ContentDocument.LatestPublishedVersionId, LinkedEntityId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :commentIds
            ]) {
                if (!attachmentsMap.containsKey(link.LinkedEntityId)) {
                    attachmentsMap.put(link.LinkedEntityId, new List<ContentDocumentLink>());
                }
                attachmentsMap.get(link.LinkedEntityId).add(link);
            }
        }
    
        // Step 4: Build the wrapper class to return data
        List<CaseCommentWrapper> result = new List<CaseCommentWrapper>();
        for (CaseComment comment : comments) {
            List<AttachmentWrapper> attachmentWrappers = new List<AttachmentWrapper>();
            if (attachmentsMap.containsKey(comment.Id)) {
                for (ContentDocumentLink doc : attachmentsMap.get(comment.Id)) {
                    attachmentWrappers.add(new AttachmentWrapper(doc.ContentDocument.Title, doc.ContentDocument.LatestPublishedVersionId));
                }
            }
            result.add(new CaseCommentWrapper(comment.Id, comment.CommentBody, comment.CreatedDate, attachmentWrappers));
        }
        return result;
    }
    
    // Wrapper classes
    public class CaseCommentWrapper {
        @AuraEnabled public Id commentId;
        @AuraEnabled public String commentBody;
        @AuraEnabled public DateTime createdDate;
        @AuraEnabled public List<AttachmentWrapper> attachments;
    
        public CaseCommentWrapper(Id commentId, String commentBody, DateTime createdDate, List<AttachmentWrapper> attachments) {
            this.commentId = commentId;
            this.commentBody = commentBody;
            this.createdDate = createdDate;
            this.attachments = attachments;
        }
    }
    
    public class AttachmentWrapper {
        @AuraEnabled public String title;
        @AuraEnabled public String downloadUrl;
    
        public AttachmentWrapper(String title, Id versionId) {
            this.title = title;
            this.downloadUrl = '/sfc/servlet.shepherd/version/download/' + versionId;
        }
    }
}