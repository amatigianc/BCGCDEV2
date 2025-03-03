trigger TaskTrigger on Task(before insert, after insert, before update, after update) {
    new DomainHandlerUtility().process();
}