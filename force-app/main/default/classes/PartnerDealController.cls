public with sharing class PartnerDealController {
    
    @AuraEnabled(cacheable=true)
    public static List<Partner_Deal__c> getPartnerDeals() {
        return [
            SELECT Id,
                Name,
                Status__c,
                Approval_Status__c,
                Deal_Amount__c,
                Submitted_Date__c,
                Customer_Account__r.Name
             FROM Partner_Deal__c
             ORDER BY CreatedDate DESC
          ];
    }
    @AuraEnabled(cacheable=true)
public static Partner_Deal__c getPartnerDealDetails(Id dealId) {

    return [
        SELECT Id,
               Name,
               Status__c,
               Approval_Status__c,
               Deal_Amount__c,
               Discount_Percentage__c,
               Submitted_Date__c,
               Approved_Date__c,
               Partner_Account__c,
               Partner_Account__r.Name,
               Customer_Account__c,
               Customer_Account__r.Name
        FROM Partner_Deal__c
        WHERE Id = :dealId
        LIMIT 1
    ];
}   
}