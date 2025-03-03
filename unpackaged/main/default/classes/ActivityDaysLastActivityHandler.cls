public with sharing class ActivityDaysLastActivityHandler extends DomainLogicHandler {
  Map<Id, List<DateTime>> whoIdActivityDate = new Map<Id, List<DateTime>>();
  List<SObject> qualifiedObjects = new List<SObject>();
  List<Id> createdByIds = new List<Id>();

  public override void check(Sobject newObj) {
    Id whoID = (Id) newObj.get('WhoId');

    if (whoID != null && isQualified(newObj)) {
      Datetime activityDate = (DateTime) newObj.get('ActivityDate');

      if (!whoIdActivityDate.containsKey(whoID)) {
        whoIdActivityDate.put(whoID, new List<DateTime>());
      }
      whoIdActivityDate.get(whoID).add(activityDate);
      qualifiedObjects.add(newObj);

      createdByIds.add((Id) newObj.get('CreatedbyId'));
    }
  }

  public override void check(Sobject newObj, Sobject oldObj) {
    Id whoId = (Id) newObj.get('WhoId');

    if (whoID != null && isQualified(newObj) && isChanged(newObj, oldObj)) {
      Datetime activityDate = (DateTime) newObj.get('ActivityDate');

      if (!whoIdActivityDate.containsKey(whoId)) {
        whoIdActivityDate.put(whoId, new List<DateTime>());
      }
      whoIdActivityDate.get(whoId).add(activityDate);
      qualifiedObjects.add(newObj);
      createdByIds.add((Id) newObj.get('CreatedbyId'));
    }
  }

  private Boolean isQualified(Sobject newobj) {
    return isQualifiedObject(newObj) && isQualifiedActivityType(newObj);
  }

  private Boolean isQualifiedObject(Sobject newObj) {
    return (newObj instanceof Task || newObj instanceof Event);
  }

  private Boolean isQualifiedActivityType(Sobject newObj) {
    if (newObj instanceof Task) {
      return ((Task) newObj).Type == 'Call' ||
        ((Task) newobj).Type == 'Email' ||
        ((Task) newObj).TaskSubType == 'Call' ||
        ((Task) newObj).TaskSubType == 'Email';
    }
    return (newObj instanceof Event);
  }

  private Boolean isQualfiedRole(User createdBy) {
    return FeatureManagement.checkPermission('Creates_Sales_Activity');
  }

  private Boolean isChanged(SObject newObj, SObject oldObj) {
    return (newObj.get('ActivityDate') != oldObj.get('ActivityDate'));
  }

  public override void processRecords() {
    if (!qualifiedObjects.isEmpty()) {
      Map<Id, User> taskCreatedBys = new Map<Id, User>(
        [SELECT Id, UserRole.Name FROM User WHERE Id IN :createdByIds]
      );

      for (Id idRecord : WhoIdActivityDate.keySet()) {
        WhoIdActivityDate.get(idRecord).sort();
      }

      Map<Id, SObject> contactLeadToUpdate = new Map<Id, SObject>();
      contactLeadToUpdate.putAll(
        [
          SELECT Id, Last_Sales_Activity_Date__c
          FROM Contact
          WHERE Id IN :whoIdActivityDate.keySet()
        ]
      );
      contactLeadToUpdate.putAll(
        [
          SELECT Id, Last_Sales_Activity_Date__c
          FROM Lead
          WHERE Id IN :whoIdActivityDate.keySet()
        ]
      );

      List<SObject> updateRecords = new List<SObject>();

      for (SObject activityToProcess : qualifiedObjects) {
        User createdBy = taskCreatedBys.get(
          (Id) activityToProcess.get('createdById')
        );

        if (isQualfiedRole(createdBy)) {
          SObject processObject = contactLeadToUpdate.get(
            (Id) activityToProcess.get('WhoId')
          );

          DateTime currentDate = (DateTime) processObject.get(
            'Last_Sales_Activity_Date__c'
          );

          DateTime newerDate = WhoIdActivityDate.get(processObject.Id)[
            WhoIdActivityDate.get(processObject.Id).size() - 1
          ];

          if (newerDate > currentDate || currentDate == null) {
            processObject.put('Last_Sales_Activity_Date__c', newerDate);
          }

          updateRecords.add(processObject);
        }
      }
      update updateRecords;
    }
  }
}