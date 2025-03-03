@SuppressWarnings('PMD.AvoidDirectAccessTriggerMap')
/**
 * Suppressed due to use case. The Trigger collection is only
 * interrogated to determine the type of SObject the trigger
 * is fired on.
 */
public with sharing class DomainHandlerUtility {
  List<DomainLogicHandler> handlers;
  String triggerEvent = Trigger.operationType.name();
  List<String> qualifiedStatuses = new List<String>{ 'Active' };

  public DomainHandlerUtility() {
    if (Test.isRunningTest()) {
      qualifiedStatuses.add('Draft');
    }
    setDomainHandlers();
  }

  public void process() {
    String dml = triggerEvent.split('_')[1];
    switch on dml {
      when 'INSERT' {
        processInsert();
      }
      when 'UPDATE' {
        processUpdate();
      }
      when 'DELETE' {
        processDelete();
      }
    }

    processHandlers();
  }

  void processDelete() {
    for (SObject obj : Trigger.old) {
      for (DomainLogicHandler handler : handlers) {
        handler.check(obj);
      }
    }
  }
  void processInsert() {
    for (SObject newObj : Trigger.new) {
      for (DomainLogicHandler handler : handlers) {
        handler.check(newObj);
      }
    }
  }

  void processUpdate() {
    for (SObject newObj : Trigger.new) {
      SObject oldObj = Trigger.oldMap.get(newObj.Id);
      for (DomainLogicHandler handler : handlers) {
        handler.check(newObj, oldObj);
      }
    }
  }

  void processHandlers() {
    for (DomainLogicHandler handler : handlers) {
      handler.processRecords();
    }
  }

  void setDomainHandlers() {
    String sobjectName = getSObjectName();
    List<Domain_Handler__mdt> domainHandlers = [
      SELECT Label, Handler_Class__c, Trigger_Event__c, Order__c, Status__c
      FROM Domain_Handler__mdt
      WHERE
        SObject_Name__c = :sobjectName
        AND Trigger_Event__c = :triggerEvent
        AND Status__c IN :qualifiedStatuses
      // AND Active__c = TRUE
      ORDER BY Order__c NULLS LAST
    ];

    handlers = new List<DomainLogicHandler>();
    for (Domain_Handler__mdt domainHandler : domainHandlers) {
      Type myType = Type.forName(domainHandler.Handler_Class__c);
      if (myType != null) {
        DomainLogicHandler handler = (DomainLogicHandler) myType.newInstance();
        handlers.add(handler);
      }
    }
  }

  String getSObjectName() {
    SObject sobj = Trigger.new == null ? Trigger.old[0] : Trigger.new[0];
    return sobj.getSobjectType()
      .getDescribe(SObjectDescribeOptions.DEFERRED)
      .getName();
  }
}