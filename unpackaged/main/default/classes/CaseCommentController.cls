public with sharing class CaseCommentController {
    @AuraEnabled(cacheable=true)
    public static List<cComments> getComments(ID caseId) {
        List<Attachment> attchs = [SELECT LastModifiedDate, Name, ParentID FROM Attachment WHERE ParentID = :caseId];
        List<cComments> comments = new List<cComments>();
        for(CaseComment comment : [Select id, LastModifiedDate, LastModifiedBy.Id, LastModifiedBy.Name, IsPublished, CreatedDate, CreatedBy.Id, CreatedBy.Name, CommentBody 
                                    From CaseComment c where ParentId = :caseId AND IsPublished = true order by c.LastModifiedDate desc])
        {
            cComments tempcComment = new cComments();
            tempcComment.cComment = comment;
            tempcComment.commentCreator = comment.LastModifiedBy.Name;
            tempcComment.commentText = comment.CommentBody;
            tempcComment.dateCreated =  comment.LastModifiedDate.format();
            for(Attachment attch : attchs){
                if( comment.LastModifiedDate.addSeconds(3) > attch.LastModifiedDate &&
                    comment.LastModifiedDate.addSeconds(-3) < attch.LastModifiedDate)
                    {
                        tempcComment.relatedAttachmentID = '/servlet/servlet.FileDownload?file=' + attch.Id;
                        tempcComment.attachmentID = attch.Id;
                        tempcComment.hasRelatedAttachmentID = true;
                    }
            } 
            //Add to list
            if(tempcComment.relatedAttachmentID == null){
                tempcComment.relatedAttachmentID = 'No Attachment';
                tempcComment.hasRelatedAttachmentID = false;
            }
            comments.add(tempcComment);
        }
        return comments;
    }

    
    /*@AuraEnabled(cacheable=true)
    public static List<Case> getContacts(String accId) {
        return [SELECT Id, subject, Account.Name from Case where id = :accId];
    }*/
    
    @AuraEnabled
    public static Boolean deleteAttachment(String attchID) {
        Id userId = UserInfo.getUserId();
        Boolean worked;
        List<Attachment> attch = [SELECT ID FROM Attachment WHERE ID = :attchID and OwnerId =: userID];
        if(attch.size() > 0){
            delete attch;
            worked = true;
        }
        else {
            worked = false;
        }    
        return worked;
    }

    @AuraEnabled
    public static void deleteFile(String fileID) {
        ContentDocument cd = new ContentDocument(id = [SELECT ContentDocumentId FROM ContentDistribution WHERE ID = :fileID].ContentDocumentId);
        delete cd;
    }

    @AuraEnabled(cacheable=true)
    public static List<aAttachment> getAttachments(ID caseId) {
        List<Attachment> attchs = [SELECT LastModifiedDate, Name, ParentID, CreatedBy.Name FROM Attachment WHERE ParentID = :caseId order by LastModifiedDate desc];
        List<aAttachment> attchsToreturn = new List<aAttachment>();
        for(Attachment attch : attchs){
            aAttachment aattch = new aAttachment();
            aattch.aAttachment = attch;
            aattch.CommunityURL = '/servlet/servlet.FileDownload?file=' + attch.Id;
            attchsToreturn.add(aattch);
        }
        return attchsToreturn;
    }

    @AuraEnabled
    public static List<ContentDistribution> getFiles(ID caseId) {
        List<ContentDocumentLink> cdlList = [SELECT ContentDocumentID FROM ContentDocumentLink WHERE LinkedEntityId = :caseId];
        Set<ID> setIDsCD = new Set<Id>();
        for (ContentDocumentLink cdl : cdlList) {
            setIDsCD.add(cdl.ContentDocumentid);
        }
        List<ContentVersion> cvList = [SELECT ID, Title FROM ContentVersion WHERE ContentDocumentID IN :setIDsCD];
        List<ContentDistribution> cdList = [SELECT Name, DistributionPublicUrl, LastModifiedDate, CreatedBy.name, ContentVersionId 
            FROM ContentDistribution WHERE ContentVersionId IN :cvList];
		Map<ID, ContentDistribution> mapOnlyOneCD = new Map<Id, ContentDistribution>();
        for(ContentDistribution cd : cdList){
            if(!mapOnlyOneCD.containsKey(cd.ContentVersionId)){
                mapOnlyOneCD.put(cd.ContentVersionID, cd);
            }
        }
        List<ContentVersion> cvsWOcds = new List<ContentVersion>();
        if(cvList.size() > mapOnlyOneCD.size()){
            for (ContentVersion cv : cvList) {
                if(!mapOnlyOneCD.containsKey(cv.id)){
                    cvsWOcds.add(cv);
                }
            }
            List<ContentDistribution> cdsToCreate = new List<ContentDistribution>();
            for(ContentVersion cv : cvsWOcds){
                ContentDistribution cd = new ContentDistribution();
                cd.Name = cv.title;
                cd.ContentVersionId = cv.id;
                cd.PreferencesAllowViewInBrowser= true;
                cd.PreferencesLinkLatestVersion=true;
                cd.PreferencesNotifyOnVisit=false;
                cd.PreferencesPasswordRequired=false;
                cd.PreferencesAllowOriginalDownload= true;
                cdsToCreate.add(cd);
            }
            insert cdsToCreate;
            cdList = [select Name, DistributionPublicUrl, LastModifiedDate, CreatedBy.Name, ContentVersionId 
                from ContentDistribution WHERE ContentVersionId IN :cvList];
            mapOnlyOneCD = new Map<Id, ContentDistribution>();
            for(ContentDistribution cd : cdList){
                if(!mapOnlyOneCD.containsKey(cd.ContentVersionId)){
                    mapOnlyOneCD.put(cd.ContentVersionID, cd);
                }
            }
        }
        List<ContentDistribution> cdToReturn = mapOnlyOneCD.values();
        return cdToReturn;
    }

    public class cComments {
        
        @AuraEnabled
        public CaseComment cComment {get; set;}
        @AuraEnabled
        public String commentCreator {get; set;}
        @AuraEnabled
        public String commentText {get; set;}
        @AuraEnabled
        public String dateCreated {get; set;}
        @AuraEnabled
        public String relatedAttachmentID {get; set;}
        @AuraEnabled
        public Boolean hasRelatedAttachmentID {get; set;}
        @AuraEnabled
        public String attachmentID {get; set;}
    }

    public class aAttachment {
        @AuraEnabled
        public String CommunityURL {get; set;}
        @AuraEnabled
        public Attachment aAttachment {get; set;}
    }
}