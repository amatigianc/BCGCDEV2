trigger CaseCommentTrigger on CaseComment(after insert) {
  DomainHandlerUtility handler = new DomainHandlerUtility();
  handler.process();
}