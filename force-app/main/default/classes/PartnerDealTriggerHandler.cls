public class PartnerDealTriggerHandler {

    public static void beforeSave(List<Partner_Deal__c> newDeals) {

        PartnerDealService.validateAndPrepareDeals(newDeals);

    }
    
    public static void afterUpdate(
        List<Partner_Deal__c> newDeals,
        Map<Id, Partner_Deal__c> oldMap
     ) {
     
     
     PartnerDealService.createOpportunityForApprovedDeals(
         newDeals,
         oldMap
      );
    }
}