trigger PartnerDealTrigger on Partner_Deal__c (
    before insert,
    before update,
    after update
 ) {
 if(Trigger.isBefore) {
     PartnerDealTriggerHandler.beforeSave(Trigger.new);
  }
  if (Trigger.isAfter && Trigger.isUpdate) {
      PartnerDealTriggerHandler.afterUpdate(
          Trigger.new,
          Trigger.oldMap
          );
      }
  }