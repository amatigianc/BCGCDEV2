trigger EventTrigger on Event(before insert, after insert, before update, after update) {
    new DomainHandlerUtility().process();
}