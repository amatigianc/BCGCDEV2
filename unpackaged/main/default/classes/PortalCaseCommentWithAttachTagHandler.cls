/**
 * Description: trigger on that adds a text tag to the body of the comments when there's an attachment from portal
 * Object: CaseComment
 * Event: BEFORE_INSERT
 * */
public with sharing class PortalCaseCommentWithAttachTagHandler extends DomainLogicHandler {
  Map<Id, CaseComment> mapCreatedByIdCaseComment = new Map<Id, CaseComment>();

  public override void check(SObject newObj) {
    CaseComment caseCommentRecord = (CaseComment) newObj;
    mapCreatedByIdCaseComment.put(
      caseCommentRecord.CreatedById,
      caseCommentRecord
    );
  }

  public override void processRecords() {
    Map<Id, String> mapUserIdUserType = new Map<Id, String>();
    List<User> userList = [
      SELECT Id, UserType
      FROM User
      WHERE Id IN :mapCreatedByIdCaseComment.keySet()
      WITH SECURITY_ENFORCED
    ];

    for (User user : userList) {
      mapUserIdUserType.put(user.Id, user.UserType);
    }

    Map<Id, String> mapParentIdFileName = new Map<Id, String>();
    for (Attachment attachRecord : [
      SELECT Id, Name, ParentId, CreatedById
      FROM Attachment
      WHERE CreatedById IN :mapUserIdUserType.keySet()
    ]) {
      mapParentIdFileName.put(
        attachRecord.ParentId,
        '[' + attachRecord.Name + ']'
      );
    }
    System.debug('mapCreatedByIDCaseComment:' + mapCreatedByIdCaseComment);
    System.debug('mapParentIdFileName:' + mapParentIdFileName);
    System.debug('MapUserIdUserType: ' + mapUserIdUserType);

    for (CaseComment caseComment : mapCreatedByIdCaseComment.values()) {
      System.debug(
        'parentId and CommentId and FileId' +
        mapParentIdFileName.get(caseComment.Id)
      );

      if ((mapUserIdUserType.get(caseComment.CreatedById) == 'CspLitePortal')) {
        caseComment.CommentBody =
          mapParentIdFileName.get(caseComment.Id) +
          '\n ' +
          caseComment.CommentBody;
        System.debug('INSIDE USER: ' + caseComment);
      }
    }

    try {
      update mapCreatedByIdCaseComment.values();
    } catch (Exception e) {
      ExceptionHandler.process(e, 'PortalCaseCommentWithAttachTagHandler');
    }
  }
}