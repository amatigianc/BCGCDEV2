trigger BrightcoveAccountEventSubscriber on Brightcove_Account_Event__e(
    after insert
) {
    BrightcoveAccountEventHandler.process(Trigger.new);
}