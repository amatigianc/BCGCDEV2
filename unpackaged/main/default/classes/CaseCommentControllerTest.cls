@IsTest
public with sharing class CaseCommentControllerTest {
  @IsTest
  static void testGetCaseDetails() {
    Account account = AccountTestFactory.createCustomer();

    Case newCase = new Case();
    newCase.Origin = 'Email';
    newCase.AccountId = account.Id;
    insert newCase;
    Case newCase2 = new Case();
    newCase2.Origin = 'Email';
    newCase2.AccountId = account.Id;
    insert newCase2;
    CaseComment ccomment = new CaseComment(
      ParentId = newCase.Id,
      CommentBody = 'comment',
      IsPublished = true
    );
    Attachment attach = new Attachment();
    attach.Name = 'Unit Test Attachment';
    Blob bodyBlob = Blob.valueOf('Unit Test Attachment Body');
    attach.body = bodyBlob;
    attach.parentId = newCase.Id;
    insert ccomment;
    insert attach;
    CaseComment ccomment2 = new CaseComment(
      ParentId = newCase2.Id,
      CommentBody = 'comment2',
      IsPublished = true
    );
    List<CaseCommentController.aAttachment> aAttachmentsList = CaseCommentController.getAttachments(
      newCase.Id
    );
    System.assertEquals(
      true,
      aAttachmentsList.size() > 0,
      'aAttachmentsList.size(): ' + aAttachmentsList.size()
    );
    insert ccomment2;
    List<CaseCommentController.cComments> cCommentsList = CaseCommentController.getComments(
      newCase.Id
    );
    System.assertEquals(
      true,
      cCommentsList.size() > 0,
      'cCommentsList.size(): ' + cCommentsList.size()
    );

    ContentVersion contentVersion = new ContentVersion(
      Title = 'Penguins',
      PathOnClient = 'Penguins.jpg',
      VersionData = Blob.valueOf('Test Content'),
      IsMajorVersion = true
    );
    insert contentVersion;
    List<ContentDocument> documents = [
      SELECT Id, Title, LatestPublishedVersionId
      FROM ContentDocument
    ];

    //create ContentDocumentLink  record
    ContentDocumentLink cdl = new ContentDocumentLink();
    cdl.LinkedEntityId = newCase.id;
    cdl.ContentDocumentId = documents[0].Id;
    cdl.shareType = 'V';
    insert cdl;

    CaseCommentController.getFiles(newCase.Id);
    CaseCommentController.deleteAttachment(attach.Id);
  }
}