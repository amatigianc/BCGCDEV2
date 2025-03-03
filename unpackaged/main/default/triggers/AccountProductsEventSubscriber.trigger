trigger AccountProductsEventSubscriber on Account_Products_Events__e(
  after insert
) {
  AccountProductPlatformEventHandler.process(Trigger.new);
}