trigger AttachmentTrigger on Attachment (after insert) {
    List<Id> parentIds = new List<Id>();
    
    for(Attachment a: Trigger.new) {
        parentIds.add(a.ParentId);
        System.debug('ParentIds: ' + a.ParentId);
        String prefix = String.valueOf(a.ParentId).substring(0,3);
        
        System.debug('Object Type: ' + prefix);
    }
    
    List<Attachment> listAtt = new List<Attachment>([SELECT Id, ParentId, CreatedDate FROM Attachment WHERE Id IN :Trigger.new]);
    Map<Id, Id> mapAttchIdAndParentId = new Map<Id,Id>();
    Map<Id, DateTime> mapAttachIdAndCreateDateTime = new Map<Id, DateTime>();
    
    for(Attachment att : listAtt) {
        mapAttchIdAndParentId.put(att.Id, att.parentId);
        mapAttachIdAndCreateDateTime.put(att.Id, att.CreatedDate);
    }
    
    System.debug('List of Attachment '+ listAtt);
    System.debug('a: ' + mapAttchIdAndParentId);
    System.debug('b: ' + mapAttachIdAndCreateDateTime);
    
    List<CaseComment> listComment = new List<CaseComment>([SELECT Id, CommentBody, CreatedDate From CaseComment WHERE ParentId IN :mapAttchIdAndParentId.values()  ]);
    String baseURL = System.URL.getOrgDomainUrl().toString();
    String downloadURL =  baseUrl + '/servlet/servlet.FileDownload?file=';
    for (CaseComment cc: listComment){
        cc.CommentBody = '** [Attachment] ***'+ cc.CreatedDate + ' ' + cc.CommentBody + '[Download:'+ downloadURL +  '] ';
    }
    System.debug('ListOfnew Commennt: ' + listComment);
    update listComment;
System.debug('A new attachment got in me');
}