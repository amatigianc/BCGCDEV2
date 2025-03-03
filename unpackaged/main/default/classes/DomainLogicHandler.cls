public virtual class DomainLogicHandler {
    public virtual void check(SObject newObj) {
        return;
    }

    public virtual void check(SObject newObj, SObject oldObj) {
        return;
    }

    public virtual void processRecords() {
        return;
    }
}