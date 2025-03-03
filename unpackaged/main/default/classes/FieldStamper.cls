public abstract class FieldStamper {
    public abstract void stamp(SObject sobj);

    public virtual Boolean isQualified(SObject sobj) {
        return true;
    }
}