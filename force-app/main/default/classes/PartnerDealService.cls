public class PartnerDealService {

    public static void validateAndPrepareDeals(List<Partner_Deal__c> newDeals) {

        Set<Id> customerAccountIds = new Set<Id>();

        for (Partner_Deal__c deal : newDeals) {
            if (deal.Customer_Account__c != null) {
                customerAccountIds.add(deal.Customer_Account__c);
            }
        }

        List<Partner_Deal__c> existingDeals = [
            SELECT Id,
                   Customer_Account__c,
                   Status__c
            FROM Partner_Deal__c
            WHERE Customer_Account__c IN :customerAccountIds
            AND Status__c IN ('Submitted', 'Under Review', 'Approved')
        ];

        Map<Id, Id> activeCustomerDeals = new Map<Id, Id>();

        for (Partner_Deal__c existingDeal : existingDeals) {
            activeCustomerDeals.put(
                existingDeal.Customer_Account__c,
                existingDeal.Id
            );
        }

        for (Partner_Deal__c deal : newDeals) {

            // ==========================
            // Submitted Deal Validations
            // ==========================
            if (deal.Status__c == 'Submitted') {

                if (deal.Deal_Amount__c == null ||
                    deal.Deal_Amount__c <= 0) {

                    deal.Deal_Amount__c.addError(
                        'Deal Amount must be greater than zero.'
                    );
                }

                if (deal.Partner_Account__c == null) {

                    deal.Partner_Account__c.addError(
                        'Partner Account is required when submitting a deal.'
                    );
                }

                if (deal.Discount_Percentage__c != null &&
                    deal.Discount_Percentage__c > 30) {

                    deal.Discount_Percentage__c.addError(
                        'Discount Percentage cannot exceed 30%.'
                    );
                }

                if (deal.Customer_Account__c != null &&
                    activeCustomerDeals.containsKey(deal.Customer_Account__c) &&
                    activeCustomerDeals.get(deal.Customer_Account__c) != deal.Id) {

                    deal.Customer_Account__c.addError(
                        'An active Partner Deal already exists for this customer.'
                    );
                }

                if (deal.Submitted_Date__c == null) {
                    deal.Submitted_Date__c = System.now();
                }
            }

            // ==========================
            // Approval Audit Fields
            // ==========================
            if (deal.Approval_Status__c == 'Approved') {

                if (deal.Approved_By__c == null) {
                    deal.Approved_By__c = UserInfo.getUserId();
                }

                if (deal.Approved_Date__c == null) {
                    deal.Approved_Date__c = System.now();
                }
            }
        }
    }

    public static void createOpportunityForApprovedDeals(
    List<Partner_Deal__c> newDeals,
    Map<Id, Partner_Deal__c> oldMap
) {

    for (Partner_Deal__c deal : newDeals) {

        Partner_Deal__c oldDeal = oldMap.get(deal.Id);

        if (deal.Approval_Status__c == 'Approved' &&
            oldDeal.Approval_Status__c != 'Approved') {

            System.enqueueJob(
                new PartnerDealQueueable(deal.Id)
            );
        }
    }
}
}