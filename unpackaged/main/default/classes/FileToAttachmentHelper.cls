public class FileToAttachmentHelper {
  @future(callout=false) // Runs asynchronously
  public static void createAttachmentsAsync(Set<Id> fileIds) {
    if (fileIds.isEmpty()) {
      return;
    }
    System.debug('fileIds -->' + fileIds);

    // Query ContentVersions (should now be available)
    Map<Id, ContentVersion> fileVersionMap = new Map<Id, ContentVersion>();
    for (ContentVersion fileVersion : [
      SELECT ContentDocumentId, VersionData, Title, PathOnClient
      FROM ContentVersion
      WHERE ContentDocumentId IN :fileIds
      ORDER BY CreatedDate DESC
    ]) {
      fileVersionMap.put(fileVersion.ContentDocumentId, fileVersion);
    }
    System.debug('ContentVersion -->' + fileVersionMap);
    // Query ContentDocumentLinks
    Map<Id, Id> fileToParentMap = new Map<Id, Id>();
    for (ContentDocumentLink link : [
      SELECT ContentDocumentId, LinkedEntityId
      FROM ContentDocumentLink
      WHERE ContentDocumentId IN :fileIds
    ]) {
      // Ensure the ParentId is NOT a User (005 prefix)
      if (!String.valueOf(link.LinkedEntityId).startsWith('005')) {
        fileToParentMap.put(link.ContentDocumentId, link.LinkedEntityId);
      }
    }

    // Create Attachments
    List<Attachment> attachments = new List<Attachment>();
    for (Id fileId : fileIds) {
      if (
        fileVersionMap.containsKey(fileId) &&
        fileToParentMap.containsKey(fileId)
      ) {
        ContentVersion fileVersion = fileVersionMap.get(fileId);
        Id parentId = fileToParentMap.get(fileId);
        // Skip invalid parent records (e.g., Users)
        if (String.valueOf(parentId).startsWith('005')) {
          continue;
        }
        Attachment att = new Attachment();
        att.ParentId = parentId;
        att.Name = fileVersion.Title;
        att.Body = fileVersion.VersionData;
        att.ContentType = 'application/octet-stream';

        attachments.add(att);
      }
    }
    System.debug('Attachment -->' + attachments);
    if (!attachments.isEmpty()) {
      insert attachments;
    }
  }
}