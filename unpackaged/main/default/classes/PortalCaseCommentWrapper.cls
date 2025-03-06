public without sharing class PortalCaseCommentWrapper {
  @AuraEnabled(cacheable=false)
  public static CaseComment createPortalComment(
    String caseId,
    String bodyComment
  ) {
    Id parentId = (Id) caseId;
    System.debug('CaseID: ' + caseId);
    System.debug('BodyComment: ' + bodyComment);
    CaseComment cc = new CaseComment();

    cc.ParentId = parentId;
    cc.CommentBody = bodyComment;
    cc.IsPublished = true;
    try {
      insert cc;
    } catch (Exception e) {
      ExceptionHandler.process(e, 'PortalCaseCommentWrapper.cls');
    }
    return cc;
  }
}